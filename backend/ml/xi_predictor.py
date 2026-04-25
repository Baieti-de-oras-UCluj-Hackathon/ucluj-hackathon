from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

import joblib
import pandas as pd
from catboost import CatBoostClassifier, CatBoostRegressor


FORMATIONS = ["4-3-3", "4-4-2", "4-2-3-1", "3-5-2", "5-3-2"]


class StartingXIPredictor:
    """
    Handles player performance scoring and optimal XI selection.
    Uses a hybrid approach:
    1. Supervised: If historical match ratings are available.
    2. Unsupervised: Composite scoring based on role-specific KPIs.
    """

    def __init__(
        self,
        model_path: Optional[str] = None,
        feature_cols: Optional[List[str]] = None,
    ):
        self.model_path = model_path
        self.feature_cols = feature_cols or [
            "performance_score",
            "recent_form_score",
            "matches_played",
            "pass_accuracy",
            "duel_win_rate",
            "def_action_success",
            "shot_accuracy",
            "dribble_success",
        ]
        self.model = self._load_model()
        self.is_supervised = self.model is not None

    def _load_model(self) -> Optional[Any]:
        if not self.model_path:
            return None
        try:
            return joblib.load(self.model_path)
        except Exception:
            return None

    def _create_fallback_model(self):
        """Create a default CatBoost model if none provided."""
        return CatBoostRegressor(
            iterations=500,
            learning_rate=0.05,
            depth=6,
            random_seed=42,
            # Ordered boosting — implicit activ, dar poți forța:
            boosting_type="Ordered",  # ← previne leakage temporal
            # Regularizare built-in:
            l2_leaf_reg=3.0,
            bagging_temperature=0.8,
        )

    def _composite_score(self, row: pd.Series) -> float:
        """
        Unsupervised composite score — used when no labeled data is available.
        Blends performance score, recent form, and efficiency metrics based on position.
        Scaled to 0-1 range (multiplied by 100 in UI for 0-100 scale).
        """
        # Base floor ensures even players with minimal data have a professional rating (e.g., 45/100)
        base_floor = 0.45

        # Available capacity for variable stats: 0.55
        # Weights for variable components:
        # Performance (0.22), Form (0.15), Experience (0.03) -> 0.40 total
        # Position-specific (0.15) -> 0.15 total
        # Sum = 0.40 + 0.15 = 0.55. Total score = base_floor + components = 1.0

        perf = row.get("performance_score", 0) or 0
        form = row.get("recent_form_score", 0) or 0

        # If performance_score is on 0-100 scale, normalize it
        if perf > 1.1:
            perf /= 100.0
        if form > 1.1:
            form /= 100.0

        base_vars = (
            0.22 * perf
            + 0.15 * form
            + 0.03 * min((row.get("matches_played", 0) or 0) / 20, 1.0)
        )

        role = str(row.get("role_group", "")).upper()

        if role == "GK":
            bonus = (
                0.07 * min((row.get("per90_gkSaves", 0) or 0) / 3.0, 1.0)
                + 0.05 * min((row.get("per90_gkCleanSheets", 0) or 0) / 0.5, 1.0)
                + 0.03 * (row.get("pass_accuracy", 0) or 0) / 100
            )
        elif role == "DEF":
            bonus = (
                0.07 * (row.get("def_action_success", 0) or 0) / 100
                + 0.05 * (row.get("duel_win_rate", 0) or 0) / 100
                + 0.03 * (row.get("pass_accuracy", 0) or 0) / 100
            )
        elif role == "MID":
            bonus = (
                0.07 * (row.get("pass_accuracy", 0) or 0) / 100
                + 0.05 * (row.get("duel_win_rate", 0) or 0) / 100
                + 0.03 * min((row.get("per90_keyPasses", 0) or 0) / 2.0, 1.0)
            )
        elif role == "FWD":
            bonus = (
                0.07 * min((row.get("per90_goals", 0) or 0) / 0.8, 1.0)
                + 0.05 * (row.get("shot_accuracy", 0) or 0) / 100
                + 0.03 * (row.get("dribble_success", 0) or 0) / 100
            )
        else:
            bonus = (
                0.05 * (row.get("pass_accuracy", 0) or 0) / 100
                + 0.05 * (row.get("duel_win_rate", 0) or 0) / 100
                + 0.05 * (row.get("def_action_success", 0) or 0) / 100
            )

        return base_floor + base_vars + bonus

    # ── Opponent adjustment ────────────────────────────────────────────────────

    def compute_opponent_adjustments(
        self,
        df_opponent_players: pd.DataFrame,
    ) -> Dict[str, float]:
        """
        Analyse opponent squad to identify their strengths and weaknesses.
        Returns a dict of adjustment factors per role/feature.
        """
        if df_opponent_players.empty:
            return {}

        opp_stats = df_opponent_players.agg(
            {
                "pass_accuracy": "mean",
                "shot_accuracy": "mean",
                "def_action_success": "mean",
            }
        ).to_dict()

        # Adjustments: if opponent is strong in passing, we might want higher def_action_success
        adjustments = {
            "def_weight": 1.0 + (opp_stats.get("pass_accuracy", 50) / 1000),
            "mid_weight": 1.0 + (opp_stats.get("def_action_success", 50) / 1000),
        }
        return adjustments

    # ── Selection Engine ───────────────────────────────────────────────────────

    def predict_optimal_xi(
        self,
        df_players: pd.DataFrame,
        formation: str = "4-3-3",
        opponent_adjustments: Optional[Dict[str, float]] = None,
    ) -> Dict[str, Any]:
        """
        Selects the best 11 players for a given formation.
        """
        adj = opponent_adjustments or {}
        pool = df_players.copy()

        # 1. Scoring
        if self.is_supervised:
            # Predict using model
            pool["predicted_score"] = self.model.predict(pool[self.feature_cols])
        else:
            # Fallback to composite scoring
            pool["predicted_score"] = pool.apply(self._composite_score, axis=1)

        # 2. Apply adjustments
        # (e.g., if opponent is strong, boost defensive importance)
        def_adj = adj.get("def_weight", 1.0)
        pool.loc[pool["role_group"] == "DEF", "predicted_score"] *= def_adj

        # 3. Formations logic
        # format: "4-3-3" or "4-2-3-1"
        parts = [int(p) for p in formation.split("-")]
        
        # We map parts to our role_groups: GK, DEF, MID, FWD
        # The first part is always DEF.
        # The last part is always FWD.
        # Any middle parts are summed as MID.
        def_count = parts[0]
        fwd_count = parts[-1]
        mid_count = sum(parts[1:-1]) if len(parts) > 2 else parts[1]

        slots = {
            "GK": 1,
            "DEF": def_count,
            "MID": mid_count,
            "FWD": fwd_count,
        }

        xi_rows = []
        used_ids = set()

        for role, count in slots.items():
            role_pool = pool[pool["role_group"] == role].sort_values(
                "predicted_score", ascending=False
            )
            selected = role_pool.head(count)
            xi_rows.append(selected)
            used_ids.update(selected["playerId"].tolist())

        xi_df = pd.concat(xi_rows, ignore_index=True) if xi_rows else pd.DataFrame()

        # Bench: remaining top players
        bench_df = (
            pool[~pool["playerId"].isin(used_ids)]
            .sort_values("predicted_score", ascending=False)
            .head(7)
        )

        return {
            "formation": formation,
            "formation_slots": slots,
            "xi": xi_df,
            "bench": bench_df,
            "all_scored": pool.sort_values("predicted_score", ascending=False),
        }

    def get_feature_importance(self) -> Optional[pd.DataFrame]:
        """Return feature importance if a supervised model was trained."""
        if not self.is_supervised or self.model is None:
            return None
        if hasattr(self.model, "feature_importances_"):
            fi = pd.DataFrame(
                {
                    "feature": self.feature_cols,
                    "importance": self.model.feature_importances_,
                }
            ).sort_values("importance", ascending=False)
            return fi
        return None