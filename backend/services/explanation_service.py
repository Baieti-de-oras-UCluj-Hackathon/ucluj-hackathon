from __future__ import annotations

import pandas as pd

from ml.feature_config import OPTIMIZABLE_LABELS
from services.model_service import ModelService

FEATURE_LABELS: dict[str, str] = {
    "Computed_Elo_Diff": "Elo Advantage",
    "Computed_HFA": "Home Field Advantage",
    "Computed_Home_Elo": "Team Elo Rating",
    "Computed_Away_Elo": "Opponent Elo Rating",
    "Home_RestDays": "Rest Days",
    "Away_RestDays": "Opponent Rest Days",
    "Home_Points_5": "Recent Form (Points)",
    "Away_Points_5": "Opponent Form (Points)",
    "Home_Goals_5": "Goals Scored (5-match)",
    "Away_Goals_5": "Opponent Goals (5-match)",
    "Home_Conceded_5": "Goals Conceded (5-match)",
    "Away_Conceded_5": "Opponent Conceded (5-match)",
    "Home_Poss_5": "Possession (5-match)",
    "Away_Poss_5": "Opponent Possession (5-match)",
    "Home_Shots_5": "Shots (5-match)",
    "Away_Shots_5": "Opponent Shots (5-match)",
    "Home_SoT_5": "Shots on Target (5-match)",
    "Away_SoT_5": "Opponent SoT (5-match)",
    "Home_Corners_5": "Corners (5-match)",
    "Away_Corners_5": "Opponent Corners (5-match)",
    "Home_H2H_Pts_3": "H2H Record",
    "Away_H2H_Pts_3": "Opponent H2H Record",
    "Home_YellowCards_5": "Discipline (Yellow Cards)",
    "Away_YellowCards_5": "Opponent Discipline",
    "Home_Saves_5": "Goalkeeper Saves",
    "Away_Saves_5": "Opponent GK Saves",
    **OPTIMIZABLE_LABELS,
}

POSITIVE_WHEN_HIGH = {
    "Computed_Elo_Diff", "Computed_HFA", "Computed_Home_Elo",
    "Home_RestDays", "Home_Points_5", "Home_Goals_5",
    "Home_Poss_5", "Home_Shots_5", "Home_SoT_5",
    "Home_Corners_5", "Home_H2H_Pts_3", "Home_Saves_5",
}


class ExplanationService:

    def __init__(self, model_svc: ModelService):
        self._model = model_svc

    def explain(self, features: pd.DataFrame, probability: float) -> dict:
        importances = self._model.feature_importances()
        if not importances:
            return {"top_drivers": [], "top_risks": [], "narrative": "Feature importances unavailable."}

        total_imp = sum(importances.values()) or 1.0
        row = features.iloc[0]
        items = []
        for feat, imp in importances.items():
            val = row.get(feat, 0)
            is_positive = self._is_positive_driver(feat, val)
            items.append({
                "feature": feat,
                "label": FEATURE_LABELS.get(feat, feat),
                "importance": round(imp / total_imp, 4),
                "direction": "positive" if is_positive else "negative",
            })

        items.sort(key=lambda x: x["importance"], reverse=True)
        drivers = [i for i in items if i["direction"] == "positive"][:5]
        risks = [i for i in items if i["direction"] == "negative"][:5]
        narrative = self._build_narrative(drivers, risks, probability)

        return {"top_drivers": drivers, "top_risks": risks, "narrative": narrative}

    def _is_positive_driver(self, feature: str, value: float) -> bool:
        if feature in POSITIVE_WHEN_HIGH:
            return value > 0
        return value <= 0

    def _build_narrative(self, drivers: list, risks: list, prob: float) -> str:
        parts = []
        if prob >= 0.65:
            parts.append(f"Strong position at {prob:.0%} win probability.")
        elif prob >= 0.45:
            parts.append(f"Moderate advantage at {prob:.0%} win probability.")
        else:
            parts.append(f"Challenging outlook at {prob:.0%} win probability.")

        if drivers:
            top = drivers[0]
            parts.append(f"Primary driver: {top['label']}.")

        if risks:
            top_risk = risks[0]
            parts.append(f"Key risk: {top_risk['label']}.")

        return " ".join(parts)
