from __future__ import annotations

import re

from services.model_service import ModelService
from services.feature_service import FeatureService
from services.explanation_service import ExplanationService
from services.optimizer_service import OptimizerService


INTENT_PATTERNS = [
    (r"(explain|why).*(probability|chance|win)", "explain"),
    (r"(key|main|top).*(driver|factor|reason)", "drivers"),
    (r"(tactical|generate).*(brief|blueprint|plan)", "blueprint"),
    (r"(uplift|improve|optimiz)", "optimize"),
    (r"(rest|fatigue|recovery).*(day|impact)", "rest_impact"),
    (r"(head.to.head|h2h|record)", "h2h"),
]


class ChatService:
    """Routes command-channel queries to the appropriate analytical service."""

    def __init__(
        self,
        model_svc: ModelService,
        feature_svc: FeatureService,
    ):
        self._model = model_svc
        self._features = feature_svc

    def handle(self, query: str, home_team: str | None, away_team: str | None) -> dict:
        intent = self._classify_intent(query)
        if not home_team or not away_team:
            return {
                "answer": "Specify both home and away teams for tactical analysis.",
                "context": {"intent": intent},
            }

        features = self._features.build_feature_vector(
            home_team, away_team, self._model.feature_cols,
        )
        prob = self._model.predict_proba(features)

        if intent == "explain" or intent == "drivers":
            svc = ExplanationService(self._model)
            result = svc.explain(features, prob)
            return {
                "answer": result["narrative"],
                "context": {
                    "probability": prob,
                    "top_drivers": result["top_drivers"][:3],
                },
            }

        if intent == "optimize" or intent == "blueprint":
            optimizer = OptimizerService(self._model)
            result = optimizer.optimize(features)
            return {
                "answer": result["diagnosis"],
                "context": {
                    "baseline": result["baseline_probability"],
                    "optimized": result["optimized_probability"],
                    "uplift": result["uplift"],
                    "targets": result["targets"],
                },
            }

        if intent == "rest_impact":
            row = features.iloc[0]
            home_rest = row.get("Home_RestDays", None)
            away_rest = row.get("Away_RestDays", None)
            answer = f"Home rest: {home_rest} days. Away rest: {away_rest} days. "
            if home_rest and away_rest and home_rest > away_rest:
                answer += "Rest advantage favors the home side."
            elif home_rest and away_rest and away_rest > home_rest:
                answer += "Opponent has a rest advantage."
            else:
                answer += "Rest days are balanced."
            return {"answer": answer, "context": {"home_rest": home_rest, "away_rest": away_rest}}

        if intent == "h2h":
            h2h = self._features.head_to_head(home_team, away_team, n=5)
            if not h2h:
                return {"answer": "No head-to-head records found.", "context": None}
            summary = f"Last {len(h2h)} meetings between {home_team} and {away_team}."
            return {"answer": summary, "context": {"matches": h2h}}

        return {
            "answer": f"Win probability for {home_team} vs {away_team}: {prob:.1%}. Ask about drivers, blueprint, rest impact, or head-to-head for more detail.",
            "context": {"probability": prob},
        }

    def _classify_intent(self, query: str) -> str:
        q = query.lower()
        for pattern, intent in INTENT_PATTERNS:
            if re.search(pattern, q):
                return intent
        return "general"
