from __future__ import annotations

import numpy as np
import pandas as pd

from services.model_service import ModelService

_HOME_STATS = [
    "Home_Poss_5", "Home_Shots_5", "Home_SoT_5",
    "Home_Corners_5", "Home_Goals_5", "Home_Conceded_5",
]
_AWAY_STATS = [
    "Away_Poss_5", "Away_Shots_5", "Away_SoT_5",
    "Away_Corners_5", "Away_Goals_5", "Away_Conceded_5",
]

_LABELS = {
    "Home_Poss_5":     "posesia",
    "Home_Shots_5":    "suturi",
    "Home_SoT_5":      "suturi pe cadru",
    "Home_Corners_5":  "cornere",
    "Home_Goals_5":    "goluri marcate",
    "Home_Conceded_5": "goluri primite",
    "Away_Poss_5":     "posesia",
    "Away_Shots_5":    "suturi",
    "Away_SoT_5":      "suturi pe cadru",
    "Away_Corners_5":  "cornere",
    "Away_Goals_5":    "goluri marcate",
    "Away_Conceded_5": "goluri primite",
}

_UNITS = {
    "Home_Poss_5": "%", "Away_Poss_5": "%",
}


class PrescriptionService:
    def __init__(self, model_svc: ModelService):
        self._model = model_svc

    def prescribe(
        self,
        features: pd.DataFrame,
        ucl_is_home: bool,
        num_simulations: int = 800,
        random_state: int = 42,
    ) -> dict:
        """Run the constrained Monte Carlo optimizer from the notebook (Cell 38).

        Returns baseline_prob, best_prob, improvement, and a human-readable
        prescription string in Romanian.
        """
        if not self._model.is_ready:
            return {"text": "", "improvement": 0.0}

        feature_cols = self._model.feature_cols
        bounds = self._model.bounds          # {stat: {'low': x, 'high': y}}
        target_stats = _HOME_STATS if ucl_is_home else _AWAY_STATS

        # Build index map once
        feat_idx = {col: i for i, col in enumerate(feature_cols)}

        # Baseline vector (numpy array for fast copy in loop)
        X_row = features[feature_cols].copy()
        if self._model._imputer is not None:
            X_row = pd.DataFrame(
                self._model._imputer.transform(X_row),
                columns=feature_cols,
            )
        baseline_vec = X_row.iloc[0].to_numpy(dtype=float)

        def _predict(vec: np.ndarray) -> float:
            df = pd.DataFrame([vec], columns=feature_cols)
            return float(self._model._model.predict_proba(df)[0, 1])

        raw_baseline = _predict(baseline_vec)
        # Convert to P(U Cluj win) perspective for display
        baseline_prob = raw_baseline if ucl_is_home else 1.0 - raw_baseline

        # Resolve bounds — fall back to Home_* bounds for Away_* stats
        def _bounds(stat: str):
            b = bounds.get(stat) or bounds.get(stat.replace("Away_", "Home_"))
            if b is None:
                return (None, None)
            return (b["low"], b["high"])

        poss_lo, poss_hi   = _bounds(target_stats[0])
        shot_lo, shot_hi   = _bounds(target_stats[1])
        sot_lo,  sot_hi    = _bounds(target_stats[2])
        corn_lo, corn_hi   = _bounds(target_stats[3])
        goal_lo, goal_hi   = _bounds(target_stats[4])
        conc_lo, conc_hi   = _bounds(target_stats[5])

        if any(v is None for v in [poss_lo, shot_lo, sot_lo, corn_lo, goal_lo, conc_lo]):
            return {"text": "", "improvement": 0.0}

        rng = np.random.default_rng(random_state)
        # When home: maximize P(home win); when away: minimize P(home win) = maximize P(U Cluj win)
        best_raw = raw_baseline
        best_tactic: dict | None = None

        for _ in range(num_simulations):
            poss  = rng.uniform(poss_lo, poss_hi)
            shots = rng.uniform(shot_lo, shot_hi)

            sot_lo2 = max(sot_lo, 0.2 * shots)
            sot_hi2 = min(sot_hi, 0.7 * shots)
            if sot_hi2 <= sot_lo2:
                continue
            sot = rng.uniform(sot_lo2, sot_hi2)

            corn_lo2 = max(corn_lo, 0.15 * shots)
            corn_hi2 = min(corn_hi, 0.80 * shots)
            if corn_hi2 <= corn_lo2:
                continue
            corners = rng.uniform(corn_lo2, corn_hi2)

            goal_lo2 = max(goal_lo, 0.05 * shots)
            goal_hi2 = min(goal_hi, 0.60 * sot)
            if goal_hi2 <= goal_lo2:
                continue
            goals = rng.uniform(goal_lo2, goal_hi2)

            max_conc = min(goals - 0.2, conc_hi)
            if max_conc <= conc_lo:
                continue
            conceded = rng.uniform(conc_lo, max_conc)

            vec = baseline_vec.copy()
            vec[feat_idx[target_stats[0]]] = poss
            vec[feat_idx[target_stats[1]]] = shots
            vec[feat_idx[target_stats[2]]] = sot
            vec[feat_idx[target_stats[3]]] = corners
            vec[feat_idx[target_stats[4]]] = goals
            vec[feat_idx[target_stats[5]]] = conceded

            p = _predict(vec)
            improved = (p > best_raw) if ucl_is_home else (p < best_raw)
            if improved:
                best_raw = p
                best_tactic = {
                    target_stats[0]: round(float(poss), 1),
                    target_stats[1]: round(float(shots), 1),
                    target_stats[2]: round(float(sot), 1),
                    target_stats[3]: round(float(corners), 1),
                    target_stats[4]: round(float(goals), 1),
                    target_stats[5]: round(float(conceded), 1),
                }

        best_prob = best_raw if ucl_is_home else 1.0 - best_raw
        improvement = best_prob - baseline_prob

        if best_tactic is None or improvement < 0.01:
            return {
                "text": _no_improvement_text(baseline_prob),
                "improvement": round(improvement, 4),
            }

        text = _build_prescription_text(
            baseline_prob, best_prob, improvement,
            baseline_vec, feat_idx, best_tactic, target_stats,
        )
        return {"text": text, "improvement": round(improvement, 4)}


def _no_improvement_text(prob: float) -> str:
    if prob >= 0.65:
        return (
            f"Profilul tactic actual este optim pentru această confruntare. "
            f"Menține abordarea ofensivă și controlul mingii."
        )
    return (
        "Optimizatorul tactic nu a identificat un plan de joc semnificativ superior "
        "față de abordarea actuală. Concentrează-te pe disciplina defensivă."
    )


# Stats where higher is better (▲ good), and which where lower is better (▼ good)
_HIGHER_IS_BETTER = {
    "Home_Poss_5", "Away_Poss_5",
    "Home_Shots_5", "Away_Shots_5",
    "Home_SoT_5", "Away_SoT_5",
    "Home_Corners_5", "Away_Corners_5",
    "Home_Goals_5", "Away_Goals_5",
}
_LOWER_IS_BETTER = {
    "Home_Conceded_5", "Away_Conceded_5",
}


def _build_prescription_text(
    baseline_prob: float,
    best_prob: float,
    improvement: float,
    baseline_vec: np.ndarray,
    feat_idx: dict,
    best_tactic: dict,
    target_stats: list[str],
) -> str:
    lines = []
    for stat in target_stats:
        current = round(float(baseline_vec[feat_idx[stat]]), 1)
        target  = best_tactic[stat]
        delta   = target - current
        if abs(delta) < 0.05:
            continue
        # Only show changes that go in the intuitive coaching direction
        if stat in _HIGHER_IS_BETTER and delta < 0:
            continue
        if stat in _LOWER_IS_BETTER and delta > 0:
            continue
        label = _LABELS.get(stat, stat)
        unit  = _UNITS.get(stat, "")
        arrow = "▲" if delta > 0 else "▼"
        lines.append(f"{arrow} {label}: {current}{unit} → {target}{unit}")

    if not lines:
        return _no_improvement_text(baseline_prob)

    header = (
        f"PLAN TACTIC OPTIM — probabilitate proiectată {best_prob:.0%} "
        f"(+{improvement:.0%} față de baseline {baseline_prob:.0%}):"
    )
    return header + "\n" + "  |  ".join(lines)
