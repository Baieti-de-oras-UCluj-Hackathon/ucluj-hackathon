"""
Starting XI Predictor — ML Model
Uses a combination of:
  1. Supervised learning (XGBoost) — if historical starting XI labels are available
  2. Unsupervised scoring fallback — when no labels exist yet

The model ranks available players per position group and selects the optimal XI
for a given formation.
"""

import json
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.pipeline import Pipeline
from sklearn.model_selection import cross_val_score
import warnings
warnings.filterwarnings("ignore")

try:
    from catboost import CatBoostClassifier
    HAS_CATBOOST = True
except ImportError:
    HAS_CATBOOST = False

try:
    import xgboost as xgb
    HAS_XGB = True
except ImportError:
    HAS_XGB = False


# ─── Formation definitions ─────────────────────────────────────────────────────
FORMATIONS = {
    "4-3-3":  {"GK": 1, "DEF": 4, "MID": 3, "FWD": 3},
    "4-4-2":  {"GK": 1, "DEF": 4, "MID": 4, "FWD": 2},
    "4-2-3-1":{"GK": 1, "DEF": 4, "MID": 5, "FWD": 1},
    "3-5-2":  {"GK": 1, "DEF": 3, "MID": 5, "FWD": 2},
    "3-4-3":  {"GK": 1, "DEF": 3, "MID": 4, "FWD": 3},
    "5-3-2":  {"GK": 1, "DEF": 5, "MID": 3, "FWD": 2},
    "5-4-1":  {"GK": 1, "DEF": 5, "MID": 4, "FWD": 1},
}


# ─── Feature columns used for the model ───────────────────────────────────────
NUMERIC_FEATURES = [
    "age", "matches_played", "total_minutes",
    "performance_score", "recent_form_score",
    "pass_accuracy", "duel_win_rate", "dribble_success",
    "shot_accuracy", "aerial_win_rate", "cross_accuracy", "def_action_success",
    "per90_goals", "per90_assists", "per90_shots", "per90_shotsOnTarget",
    "per90_passes", "per90_successfulPasses", "per90_keyPasses",
    "per90_interceptions", "per90_defensiveDuelsWon", "per90_aerialDuelsWon",
    "per90_successfulDribbles", "per90_recoveries", "per90_clearances",
    "per90_xgShot", "per90_xgAssist", "per90_progressivePasses",
    "per90_touchInBox", "per90_gkSaves", "per90_gkCleanSheets",
    "per90_losses", "per90_fouls", "per90_yellowCards",
]


class StartingXIPredictor:
    """
    Predicts the optimal starting XI for your team against a given opponent.

    Workflow:
      1. Call `fit(df, labels=None)` — supervised if labels provided, else unsupervised.
      2. Call `predict_xi(df, formation, your_team_id, opponent_team_id)` to get the XI.
    """

    def __init__(self, model_type: str = "auto"):
        """
        Args:
            model_type: 'xgboost', 'rf', 'gbm', or 'auto' (picks best available)
        """
        self.model_type = model_type
        self.model = None
        self.scaler = StandardScaler()
        self.is_supervised = False
        self.feature_cols: List[str] = []
        self.opponent_adjustments: Dict = {}  # cache opponent-specific adjustments

    # ── Internal helpers ───────────────────────────────────────────────────────

    def _get_feature_cols(self, df: pd.DataFrame) -> List[str]:
        """Return only the numeric feature columns that exist in df."""
        return [c for c in NUMERIC_FEATURES if c in df.columns]

    def _build_model(self, cat_features=None):
        return CatBoostClassifier(
        iterations=500,
        learning_rate=0.05,
        depth=6,
        cat_features=cat_features or [],   # ← magie CatBoost
        eval_metric="AUC",
        early_stopping_rounds=50,
        verbose=0,
        random_seed=42,
        # Ordered boosting — implicit activ, dar poți forța:
        boosting_type="Ordered",           # ← previne leakage temporal
        # Regularizare built-in:
        l2_leaf_reg=3.0,
        bagging_temperature=0.8,
    )

    def _composite_score(self, row: pd.Series) -> float:
        """
        Unsupervised composite score — used when no labeled data is available.
        Blends performance score, recent form, and efficiency metrics.
        """
        return (
            0.40 * (row.get("performance_score", 0) or 0)
            + 0.25 * (row.get("recent_form_score", 0) or 0)
            + 0.10 * (row.get("pass_accuracy", 0) or 0) / 100
            + 0.10 * (row.get("duel_win_rate", 0) or 0) / 100
            + 0.05 * (row.get("def_action_success", 0) or 0) / 100
            + 0.05 * min((row.get("matches_played", 0) or 0) / 20, 1.0)  # experience cap
            + 0.05 * (row.get("shot_accuracy", 0) or 0) / 100
        )

    # ── Opponent adjustment ────────────────────────────────────────────────────

    def compute_opponent_adjustments(
        self,
        df_opponent_players: pd.DataFrame,
    ) -> Dict[str, float]:
        """
        Analyse opponent squad to identify their strengths and weaknesses.
        Returns a dict of adjustments to apply to your player scores.
        
        Example: if opponent is weak in aerial duels, boost your aerial players.
        """
        adj = {}
        opp = df_opponent_players.copy()
        
        for group in ["GK", "DEF", "MID", "FWD"]:
            sub = opp[opp["role_group"] == group]
            if sub.empty:
                continue
            adj[f"{group}_aerial_weakness"] = 1.0 - (sub["aerial_win_rate"].mean() or 50) / 100
            adj[f"{group}_duel_weakness"] = 1.0 - (sub["duel_win_rate"].mean() or 50) / 100
            adj[f"{group}_pass_weakness"] = 1.0 - (sub["pass_accuracy"].mean() or 50) / 100

        return adj

    def _apply_opponent_boost(self, score: float, row: pd.Series, adj: Dict) -> float:
        """Apply opponent-based boost to a player's base score."""
        group = row.get("role_group", "MID")
        boost = 1.0

        aerial_boost = adj.get(f"{group}_aerial_weakness", 0)
        if (row.get("aerial_win_rate", 0) or 0) > 55:
            boost += 0.10 * aerial_boost

        duel_boost = adj.get(f"{group}_duel_weakness", 0)
        if (row.get("duel_win_rate", 0) or 0) > 55:
            boost += 0.08 * duel_boost

        return score * boost

    # ── Training ───────────────────────────────────────────────────────────────

    def fit(
        self,
        df: pd.DataFrame,
        labels: Optional[pd.Series] = None,
        verbose: bool = True,
    ):
        """
        Train the model.
        
        Args:
            df: Feature DataFrame (one row per player-match or player aggregate)
            labels: Binary series — 1 if player started, 0 if not.
                    If None, uses unsupervised scoring.
        """
        if labels is None or len(labels.unique()) < 2:
            self.is_supervised = False
            return
            
        self.is_supervised = True
        self.feature_cols = self._get_feature_cols(df)
        X = df[self.feature_cols].fillna(0).values
        y = labels.values
        
        X_scaled = self.scaler.fit_transform(X)

        cat_cols = ["role", "role_group", "positions_played"]
        cat_idx  = [self.feature_cols.index(c) for c in cat_cols if c in self.feature_cols]

        self.model = self._build_model(cat_features=cat_idx)
        from sklearn.model_selection import train_test_split
        X_train, X_val, y_train, y_val = train_test_split(X_scaled, y, test_size=0.2, random_state=42)
        
        try:
            self.model.fit(
                X_train, y_train,
                eval_set=(X_val, y_val),
                verbose=verbose
            )
        except Exception as e:
            if verbose:
                print(f"Failed to train CatBoost: {e}")
            self.is_supervised = False

    # ── Prediction ─────────────────────────────────────────────────────────────

    def score_players(
        self,
        df: pd.DataFrame,
        opponent_df: Optional[pd.DataFrame] = None,
    ) -> pd.DataFrame:
        """
        Score all players. Returns df with an added 'predicted_score' column.
        
        Args:
            df: Feature DataFrame for YOUR team's players
            opponent_df: Feature DataFrame for opponent's players (optional)
        """
        out = df.copy()
        feat_cols = [c for c in self.feature_cols if c in out.columns]
        X = out[feat_cols].fillna(0).values

        # Opponent adjustments
        adj = {}
        if opponent_df is not None and not opponent_df.empty:
            adj = self.compute_opponent_adjustments(opponent_df)

        if self.is_supervised and self.model is not None:
            X_scaled = self.scaler.transform(X)
            proba = self.model.predict_proba(X_scaled)[:, 1]
            out["predicted_score"] = proba
        else:
            out["predicted_score"] = out.apply(self._composite_score, axis=1)

        # Apply opponent boosts
        if adj:
            out["predicted_score"] = out.apply(
                lambda row: self._apply_opponent_boost(row["predicted_score"], row, adj),
                axis=1,
            )

        return out

    def predict_xi(
        self,
        df: pd.DataFrame,
        formation: str = "4-3-3",
        your_team_id: Optional[int] = None,
        opponent_df: Optional[pd.DataFrame] = None,
    ) -> Dict:
        """
        Predict the starting XI.
        
        Args:
            df: Feature DataFrame for YOUR team's players
            formation: e.g. '4-3-3', '4-4-2', '3-5-2'
            your_team_id: Filter df to only include players from your team
            opponent_df: Feature DataFrame for opponent players (for adjustments)
        
        Returns:
            Dict with 'xi', 'bench', 'formation', 'formation_slots', 'scores'
        """
        if formation not in FORMATIONS:
            raise ValueError(f"Unknown formation '{formation}'. Valid: {list(FORMATIONS.keys())}")

        slots = FORMATIONS[formation]

        # Filter to your team if teamId column exists
        pool = df.copy()
        if your_team_id and "teamId" in pool.columns:
            pool = pool[pool["teamId"] == your_team_id]

        # Score players
        pool = self.score_players(pool, opponent_df)

        # Select best per position group
        xi_rows = []
        used_ids = set()

        for group, count in slots.items():
            candidates = pool[pool["role_group"] == group].copy()
            candidates = candidates[~candidates["playerId"].isin(used_ids)]
            candidates = candidates.sort_values("predicted_score", ascending=False)
            selected = candidates.head(count)
            xi_rows.append(selected)
            used_ids.update(selected["playerId"].tolist())

        xi_df = pd.concat(xi_rows, ignore_index=True) if xi_rows else pd.DataFrame()

        # Bench: remaining top players
        bench_df = pool[~pool["playerId"].isin(used_ids)].sort_values(
            "predicted_score", ascending=False
        ).head(7)

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
            fi = pd.DataFrame({
                "feature": self.feature_cols,
                "importance": self.model.feature_importances_,
            }).sort_values("importance", ascending=False)
            return fi
        return None
