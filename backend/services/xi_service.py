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
