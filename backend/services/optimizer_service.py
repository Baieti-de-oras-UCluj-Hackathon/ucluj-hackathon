from __future__ import annotations

import logging

import numpy as np
import pandas as pd

from ml.feature_config import OPTIMIZABLE_FEATURES, OPTIMIZABLE_LABELS
from services.model_service import ModelService

logger = logging.getLogger(__name__)

DEFAULT_SIMULATIONS = 1_000


class OptimizerService:
    """Constrained Monte Carlo tactical optimizer.

    Generates realistic tactical permutations within historically
    plausible bounds, scores each with CatBoost, applies football-domain
    constraints, and returns the best valid blueprint.
    """

    def __init__(self, model_svc: ModelService):
        self._model = model_svc

    def optimize(
        self,
        baseline_features: pd.DataFrame,
        num_simulations: int = DEFAULT_SIMULATIONS,
    ) -> dict:
        baseline_prob = self._model.predict_proba(baseline_features)
        bounds = self._model.bounds
        medians = self._model.medians
        feature_cols = self._model.feature_cols

        if not bounds:
            bounds = self._fallback_bounds(baseline_features)

        base_row = baseline_features.iloc[0].to_dict()
        best_prob = baseline_prob
        best_targets: dict[str, float] = {f: base_row.get(f, 0.0) for f in OPTIMIZABLE_FEATURES}
        valid_count = 0

        for _ in range(num_simulations):
            candidate = dict(base_row)
            for feat in OPTIMIZABLE_FEATURES:
                lo = bounds.get(feat, {}).get("low", candidate.get(feat, 0) * 0.8)
                hi = bounds.get(feat, {}).get("high", candidate.get(feat, 0) * 1.2)
                if hi <= lo:
                    continue
                candidate[feat] = np.random.uniform(lo, hi)

            if not self._check_constraints(candidate, bounds):
                continue

            valid_count += 1
            row = pd.DataFrame([candidate], columns=feature_cols)
            prob = self._model.predict_proba(row)
            if prob > best_prob:
                best_prob = prob
                best_targets = {f: candidate[f] for f in OPTIMIZABLE_FEATURES}

        targets = []
        for feat in OPTIMIZABLE_FEATURES:
            baseline_val = base_row.get(feat, 0.0)
            opt_val = best_targets[feat]
            targets.append({
                "feature": feat,
                "label": OPTIMIZABLE_LABELS.get(feat, feat),
                "baseline_value": round(baseline_val, 2),
                "optimized_value": round(opt_val, 2),
                "delta": round(opt_val - baseline_val, 2),
            })

        uplift = best_prob - baseline_prob
        diagnosis = self._generate_diagnosis(targets, uplift)

        return {
            "baseline_probability": round(baseline_prob, 4),
            "optimized_probability": round(best_prob, 4),
            "uplift": round(uplift, 4),
            "targets": targets,
            "diagnosis": diagnosis,
            "simulations_run": num_simulations,
            "valid_simulations": valid_count,
        }

    def _check_constraints(self, c: dict, bounds: dict) -> bool:
        shots = c.get("Home_Shots_5", 0)
        sot = c.get("Home_SoT_5", 0)
        corners = c.get("Home_Corners_5", 0)
        goals = c.get("Home_Goals_5", 0)
        conceded = c.get("Home_Conceded_5", 0)

        sot_lo = bounds.get("Home_SoT_5", {}).get("low", 0)
        sot_hi = bounds.get("Home_SoT_5", {}).get("high", shots)
        sot_min = max(sot_lo, 0.2 * shots)
        sot_max = min(sot_hi, 0.7 * shots)
        if sot_max <= sot_min:
            return False
        if not (sot_min <= sot <= sot_max):
            return False

        corners_lo = bounds.get("Home_Corners_5", {}).get("low", 0)
        corners_hi = bounds.get("Home_Corners_5", {}).get("high", shots)
        c_min = max(corners_lo, 0.15 * shots)
        c_max = min(corners_hi, 0.8 * shots)
        if c_max <= c_min:
            return False
        if not (c_min <= corners <= c_max):
            return False

        goals_lo = bounds.get("Home_Goals_5", {}).get("low", 0)
        goals_hi = bounds.get("Home_Goals_5", {}).get("high", sot)
        g_min = max(goals_lo, 0.05 * shots)
        g_max = min(goals_hi, 0.6 * sot)
        if g_max <= g_min:
            return False
        if not (g_min <= goals <= g_max):
            return False

        if conceded >= goals - 0.2:
            return False

        return True

    def _fallback_bounds(self, features: pd.DataFrame) -> dict:
        row = features.iloc[0]
        b = {}
        for feat in OPTIMIZABLE_FEATURES:
            val = row.get(feat, 0)
            b[feat] = {"low": val * 0.7, "high": val * 1.3}
        return b

    def _generate_diagnosis(self, targets: list[dict], uplift: float) -> str:
        if uplift <= 0:
            return "No tactical variation produced a meaningful uplift over the baseline."

        top = sorted(targets, key=lambda t: abs(t["delta"]), reverse=True)[:3]
        parts = [f"{t['label']} to {t['optimized_value']:.1f}" for t in top if t["delta"] != 0]
        if not parts:
            return "Minor tactical adjustments recommended."
        changes = ", ".join(parts)
        return f"Uplift achieved by adjusting {changes}. All targets within plausible ranges."
