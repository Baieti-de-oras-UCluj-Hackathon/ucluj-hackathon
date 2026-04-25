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
        
        def resolve_team(pid):
            profile = self._profiles.get(pid, {})
            return profile.get("currentTeamId", None)
            
        self._df["teamId"] = self._df["playerId"].apply(resolve_team)
        return self._df

    def predict_xi(self, formation: str, opponent_team_id: Optional[int]) -> Dict:
        if not self.predictor:
            raise RuntimeError("XI Model not loaded")
            
        df = self._get_feature_df()
        my_team_id = 11571  # Hardcoded Universitatea Cluj
        
        my_team_df = df[df["teamId"] == my_team_id].copy()
        if my_team_df.empty:
            raise RuntimeError(f"No players found for base team {my_team_id}")
            
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
        known_names = {
            8164: "FCSB",
            11564: "Dinamo Bucuresti",
            11565: "FCS Bucuresti",
            11566: "Rapid Bucuresti",
            11611: "CFR Cluj",
            11634: "FC Botosani",
            11663: "Unirea Slobozia",
            11943: "Metaloglobus",
            22731: "Csikszereda Miercurea Ciuc",
            23334: "FC Arges",
            26233: "Universitatea Craiova",
            30817: "UTA Arad",
            55427: "FC Hermannstadt",
            60390: "Petrolul 52",
            61242: "Farul Constanta",
        }

        try:
            df = self._get_feature_df()
        except Exception:
            df = None

        if df is None or df.empty or "teamId" not in df.columns:
            return sorted(
                [{"id": tid, "name": name} for tid, name in known_names.items()],
                key=lambda item: item["name"],
            )

        my_team_id = 11571
        team_counts = (
            df["teamId"]
            .dropna()
            .astype(int)
            .value_counts()
        )

        candidate_ids = [
            int(team_id)
            for team_id, count in team_counts.items()
            if int(team_id) != my_team_id and int(count) >= min_players
        ]

        if not candidate_ids:
            candidate_ids = list(known_names.keys())

        opponents = [
            {
                "id": team_id,
                "name": known_names.get(team_id, f"Team {team_id}"),
            }
            for team_id in candidate_ids
        ]
        return sorted(opponents, key=lambda item: item["name"])
