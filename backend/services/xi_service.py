from __future__ import annotations

import os
import pickle
import glob
from typing import Dict, Optional
import pandas as pd

from ml.pipeline import load_player_profiles, build_dataset_from_files, _format_output
from ml.xi_predictor import StartingXIPredictor

class XiService:
    def __init__(self, model_path: str, data_dir: str):
        self.model_path = model_path
        self.data_dir = data_dir
        self.predictor: Optional[StartingXIPredictor] = None
        self._df: Optional[pd.DataFrame] = None
        self._profiles: Dict = {}
        
        # Pre-load model
        if os.path.exists(model_path):
            with open(model_path, "rb") as f:
                self.predictor = pickle.load(f)
                
    def _get_feature_df(self) -> pd.DataFrame:
        if self._df is not None:
            return self._df
            
        match_files = sorted(glob.glob(os.path.join(self.data_dir, "*.json")))
        profile_path = os.path.join(self.data_dir, "players (1).json")
        if os.path.exists(profile_path):
            self._profiles = load_player_profiles(profile_path)
            
        self._df = build_dataset_from_files(match_files, self._profiles)
        
        if self._df is None or self._df.empty:
            # Return empty but with columns if possible, or just empty
            self._df = pd.DataFrame(columns=["playerId", "teamId"])
            return self._df

        def resolve_team(pid):
            profile = self._profiles.get(pid, {})
            return profile.get("currentTeamId", None)
            
        if "playerId" in self._df.columns:
            self._df["teamId"] = self._df["playerId"].apply(resolve_team)
        else:
            self._df["teamId"] = None

        return self._df

    def predict_xi(self, formation: str, opponent_team_id: Optional[int]) -> Dict:
        if not self.predictor:
            raise RuntimeError("XI Model not loaded")
            
        df = self._get_feature_df()
        my_team_id = 11571  # Hardcoded Universitatea Cluj
        
        my_team_df = df[df["teamId"] == my_team_id].copy()
        if my_team_df.empty:
            # Fallback: if no players assigned to our team, use everyone as a pool
            my_team_df = df.copy()
            if my_team_df.empty:
                raise RuntimeError(f"No players found in dataset for prediction")
            
        opp_team_df = df[df["teamId"] == opponent_team_id].copy() if opponent_team_id else None
        
        result = self.predictor.predict_xi(
            df=my_team_df,
            formation=formation,
            your_team_id=my_team_id,
            opponent_df=opp_team_df
        )
        
        return _format_output(result, my_team_id, opponent_team_id)

    def list_opponents(self, min_players: int = 20) -> list[dict]:
        """Return opponent options inferred from loaded XI feature data."""
        df = self._get_feature_df()
        if df.empty or "teamId" not in df.columns:
            return []

        my_team_id = 11571
        team_counts = (
            df["teamId"]
            .dropna()
            .astype(int)
            .value_counts()
        )

        # Keep only teams with enough player records to be meaningful options.
        candidate_ids = [
            int(team_id)
            for team_id, count in team_counts.items()
            if int(team_id) != my_team_id and int(count) >= min_players
        ]

        known_names = {
            11565: "FCSB",
            11611: "CFR Cluj",
            11634: "Rapid Bucuresti",
            11564: "Dinamo Bucuresti",
            26233: "Universitatea Craiova",
            61242: "Farul Constanta",
            22731: "Sepsi OSK",
            60390: "UTA Arad",
            11943: "FC Voluntari",
            55427: "FC Botosani",
            30817: "Hermannstadt",
            11566: "Politehnica Iasi",
            23334: "FC Arges",
            60374: "Corvinul Hunedoara",
            11571: "Universitatea Cluj",
        }

        # If data is missing or empty, return the hardcoded list as fallback
        if not candidate_ids:
            candidate_ids = [tid for tid in known_names.keys() if tid != my_team_id]

        opponents = [
            {
                "id": team_id,
                "name": known_names.get(team_id, f"Team {team_id}"),
            }
            for team_id in candidate_ids
        ]
        return sorted(opponents, key=lambda item: item["name"])
