from __future__ import annotations

import os
import pickle
import glob
from typing import Dict, List, Optional
import pandas as pd

from ml.pipeline import load_player_profiles, build_dataset_from_files, _format_output
from ml.xi_predictor import StartingXIPredictor

# Maps fixture CSV team names → WyScout team IDs used in player profiles
FIXTURE_NAME_TO_ID: dict[str, int] = {
    "U Cluj": 11571,
    "CFR Cluj": 11611,
    "FCSB": 8164,
    "Rapid Bucuresti": 11566,
    "Dinamo Bucuresti": 11564,
    "FC Botosani": 11634,
    "Unirea Slobozia": 11663,
    "Metaloglobus Bucuresti": 11943,
    "Csikszereda M. Ciuc": 22731,
    "FC Arges": 23334,
    "U Craiova 1948": 26233,
    "Univ. Craiova": 26233,
    "UTA Arad": 30817,
    "FC Hermannstadt": 55427,
    "Petrolul Ploiesti": 60390,
    "Farul Constanta": 61242,
    "Otelul Galati": 69049,
    "Sepsi Sf. Gheorghe": None,
}

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

    def match_preview(
        self,
        opponent_name: str,
        formation: str,
        main_df: Optional[pd.DataFrame] = None,
    ) -> Dict:
        """Return starting XI + team stats + H2H record for an upcoming match."""
        if not self.predictor:
            raise RuntimeError("XI model not loaded")

        opp_id = FIXTURE_NAME_TO_ID.get(opponent_name)

        df = self._get_feature_df()
        my_team_id = 11571

        my_team_df = df[df["teamId"] == my_team_id].copy()
        if my_team_df.empty:
            raise RuntimeError(f"No players found for base team {my_team_id}")

        opp_team_df = df[df["teamId"] == opp_id].copy() if opp_id else None

        result = self.predictor.predict_xi(
            df=my_team_df,
            formation=formation,
            your_team_id=my_team_id,
            opponent_df=opp_team_df,
        )

        _PLAYER_COLS = [
            "playerId", "shortName", "role", "role_group",
            "predicted_score", "composite_score",
            "performance_score", "recent_form_score",
            "total_minutes", "matches_played",
            "pass_accuracy", "duel_win_rate",
            "per90_goals", "per90_assists", "per90_shots",
            "per90_keyPasses", "per90_interceptions", "per90_gkSaves",
            "per90_gkCleanSheets",
        ]

        # Normalize raw scores to 0-100 using league-wide position-group percentiles.
        # Using all players in the dataset (all teams) as the reference population,
        # split by role_group, with 5th/95th percentile bounds to avoid outlier skew.
        _RAW_COLS = [
            "performance_score", "recent_form_score",
            "per90_goals", "per90_assists", "per90_keyPasses",
            "per90_interceptions", "per90_gkSaves", "per90_gkCleanSheets", "per90_shots",
            "pass_accuracy", "duel_win_rate",
        ]

        df_all = self._get_feature_df()

        def _league_normalize(target: pd.DataFrame) -> pd.DataFrame:
            target = target.copy()
            for col in _RAW_COLS:
                if col not in df_all.columns or col not in target.columns:
                    continue
                for grp in ["GK", "DEF", "MID", "FWD"]:
                    mask_all = df_all["role_group"] == grp
                    mask_tgt = target["role_group"] == grp
                    if not mask_tgt.any():
                        continue
                    group_vals = df_all.loc[mask_all, col].dropna()
                    if len(group_vals) < 3:
                        continue
                    p5  = float(group_vals.quantile(0.05))
                    p95 = float(group_vals.quantile(0.95))
                    rng = p95 - p5
                    if rng == 0:
                        target.loc[mask_tgt, col] = 50.0
                    else:
                        target.loc[mask_tgt, col] = (
                            (target.loc[mask_tgt, col] - p5) / rng * 100
                        ).clip(0, 100).round(1)
            return target

        xi_norm    = _league_normalize(result["xi"])
        bench_norm = _league_normalize(result["bench"])

        def _fmt(frame: pd.DataFrame) -> List[Dict]:
            if frame is None or frame.empty:
                return []
            cols = [c for c in _PLAYER_COLS if c in frame.columns]
            return frame[cols].fillna(0).to_dict(orient="records")

        # Team aggregate stats
        all_df = result.get("all_scored", pd.DataFrame())
        team_stats: Dict = {}
        if not all_df.empty:
            def _mean(col: str) -> float:
                return round(float(all_df[col].mean()), 2) if col in all_df.columns else 0.0

            team_stats = {
                "avg_performance_score": _mean("performance_score"),
                "avg_recent_form": _mean("recent_form_score"),
                "avg_pass_accuracy": round(_mean("pass_accuracy"), 1),
                "avg_duel_win_rate": round(_mean("duel_win_rate"), 1),
            }
            for stat, key in [("per90_goals", "top_scorer"), ("per90_keyPasses", "top_creator")]:
                if stat in all_df.columns and not all_df.empty:
                    row = all_df.nlargest(1, stat).iloc[0]
                    team_stats[key] = str(row.get("shortName", ""))
                    team_stats[f"{key}_stat"] = round(float(row.get(stat, 0)), 2)

        # Opponent aggregate stats
        opponent_stats: Dict = {}
        if opp_team_df is not None and not opp_team_df.empty:
            def _opp_mean(col: str) -> float:
                return round(float(opp_team_df[col].mean()), 2) if col in opp_team_df.columns else 0.0
            
            opponent_stats = {
                "avg_performance_score": _opp_mean("performance_score"),
                "avg_recent_form": _opp_mean("recent_form_score"),
                "avg_pass_accuracy": round(_opp_mean("pass_accuracy"), 1),
                "avg_duel_win_rate": round(_opp_mean("duel_win_rate"), 1),
            }
            for stat, key in [("per90_goals", "top_scorer"), ("per90_keyPasses", "top_creator")]:
                if stat in opp_team_df.columns and not opp_team_df.empty:
                    row = opp_team_df.nlargest(1, stat).iloc[0]
                    opponent_stats[key] = str(row.get("shortName", ""))
                    opponent_stats[f"{key}_stat"] = round(float(row.get(stat, 0)), 2)
        else:
            opponent_stats = {
                "avg_performance_score": 0.0,
                "avg_recent_form": 0.0,
                "avg_pass_accuracy": 0.0,
                "avg_duel_win_rate": 0.0,
                "top_scorer": "",
                "top_scorer_stat": 0.0,
                "top_creator": "",
                "top_creator_stat": 0.0,
            }

        # Head-to-head from main fixtures CSV
        h2h: Dict = {"total": 0, "our_wins": 0, "draws": 0, "their_wins": 0,
                     "our_avg_goals": 0.0, "their_avg_goals": 0.0}
        if main_df is not None and not main_df.empty:
            try:
                our = "U Cluj"
                mask = (
                    ((main_df["home_team"] == our) & (main_df["away_team"] == opponent_name))
                    | ((main_df["home_team"] == opponent_name) & (main_df["away_team"] == our))
                )
                h2h_df = main_df[mask].dropna(subset=["home_score", "away_score"]).tail(10)
                if not h2h_df.empty:
                    our_wins = draws = their_wins = our_g_total = their_g_total = 0
                    for _, row in h2h_df.iterrows():
                        hs, as_ = int(row["home_score"]), int(row["away_score"])
                        is_home = row["home_team"] == our
                        og, tg = (hs, as_) if is_home else (as_, hs)
                        our_g_total += og
                        their_g_total += tg
                        if og > tg:
                            our_wins += 1
                        elif og < tg:
                            their_wins += 1
                        else:
                            draws += 1
                    n = len(h2h_df)
                    h2h = {
                        "total": n,
                        "our_wins": our_wins,
                        "draws": draws,
                        "their_wins": their_wins,
                        "our_avg_goals": round(our_g_total / n, 1),
                        "their_avg_goals": round(their_g_total / n, 1),
                    }
            except Exception:
                pass

        return {
            "formation": formation,
            "opponent_name": opponent_name,
            "opponent_team_id": opp_id,
            "starting_xi": _fmt(xi_norm),
            "bench": _fmt(bench_norm),
            "team_stats": team_stats,
            "opponent_stats": opponent_stats,
            "head_to_head": h2h,
        }

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
