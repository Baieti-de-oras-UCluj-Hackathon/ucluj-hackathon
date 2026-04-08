from __future__ import annotations

import pandas as pd
import numpy as np

from ml.feature_config import BASE_FEATURES, OPTIONAL_FEATURES


class FeatureService:
    """Builds feature vectors for a fixture from the historical dataset."""

    def __init__(self, df: pd.DataFrame):
        self._df = df

    def build_feature_vector(
        self,
        home_team: str,
        away_team: str,
        feature_cols: list[str],
    ) -> pd.DataFrame:
        """Assemble the latest available feature row for a fixture.

        Looks up the most recent match for each team and combines their
        rolling/Elo/H2H stats into a single-row DataFrame aligned to
        feature_cols.
        """
        home_row = self._latest_home_stats(home_team)
        away_row = self._latest_away_stats(away_team)

        vector: dict[str, float] = {}
        for col in feature_cols:
            if col in home_row:
                vector[col] = home_row[col]
            elif col in away_row:
                vector[col] = away_row[col]
            else:
                vector[col] = np.nan

        return pd.DataFrame([vector], columns=feature_cols)

    def _latest_home_stats(self, team: str) -> dict[str, float]:
        matches = self._df[self._df["home_team"] == team].sort_values("match_date")
        if matches.empty:
            return {}
        row = matches.iloc[-1]
        return {c: float(row[c]) for c in _home_columns() if c in row.index and pd.notna(row[c])}

    def _latest_away_stats(self, team: str) -> dict[str, float]:
        matches = self._df[self._df["away_team"] == team].sort_values("match_date")
        if matches.empty:
            return {}
        row = matches.iloc[-1]
        return {c: float(row[c]) for c in _away_columns() if c in row.index and pd.notna(row[c])}

    def available_teams(self) -> list[str]:
        home = set(self._df["home_team"].dropna().unique())
        away = set(self._df["away_team"].dropna().unique())
        return sorted(home | away)

    def head_to_head(self, team_a: str, team_b: str, n: int = 5) -> list[dict]:
        mask = (
            ((self._df["home_team"] == team_a) & (self._df["away_team"] == team_b))
            | ((self._df["home_team"] == team_b) & (self._df["away_team"] == team_a))
        )
        h2h = self._df[mask].sort_values("match_date", ascending=False).head(n)
        return h2h[["match_date", "home_team", "away_team", "home_score", "away_score"]].to_dict("records")


def _home_columns() -> list[str]:
    return [c for c in BASE_FEATURES + OPTIONAL_FEATURES if c.startswith("Home_") or c.startswith("Computed_")]


def _away_columns() -> list[str]:
    return [c for c in BASE_FEATURES + OPTIONAL_FEATURES if c.startswith("Away_")]
