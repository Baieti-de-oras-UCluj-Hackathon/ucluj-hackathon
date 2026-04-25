"""
Feature Engineering for Football Starting XI Predictor
Transforms raw player stats + player profile data into ML-ready features.
"""

import json
import numpy as np
import pandas as pd
from pathlib import Path
from typing import List, Dict, Optional


# ─── Stat weights by position group ───────────────────────────────────────────
POSITION_STAT_WEIGHTS = {
    "GK": {
        "gkSaves": 3.0, "gkCleanSheets": 3.0, "gkShotsAgainst": -1.0,
        "gkSuccessfulExits": 2.0, "gkAerialDuelsWon": 2.0,
        "successfulPasses": 1.0, "losses": -1.0,
    },
    "DEF": {
        "interceptions": 2.5, "defensiveDuelsWon": 2.5, "aerialDuelsWon": 2.0,
        "clearances": 2.0, "successfulDefensiveAction": 2.0,
        "successfulPasses": 1.5, "losses": -1.5, "fouls": -1.0,
        "yellowCards": -2.0, "redCards": -5.0,
        "recoveries": 1.5, "shotsBlocked": 1.5,
    },
    "MID": {
        "successfulPasses": 2.0, "keyPasses": 3.0, "assists": 3.0,
        "goals": 3.0, "successfulDribbles": 2.0, "interceptions": 1.5,
        "progressivePasses": 2.0, "recoveries": 1.5,
        "losses": -1.5, "fouls": -0.5, "yellowCards": -2.0,
        "passesToFinalThird": 2.0, "xgAssist": 2.5,
    },
    "FWD": {
        "goals": 4.0, "shots": 1.5, "shotsOnTarget": 2.5, "xgShot": 3.0,
        "assists": 2.5, "successfulDribbles": 2.0, "keyPasses": 2.0,
        "touchInBox": 2.0, "offsides": -0.5, "losses": -1.0,
    },
}

ROLE_TO_GROUP = {
    "Goalkeeper": "GK", "GK": "GK",
    "Defender": "DEF", "Centre Back": "DEF", "Left Back": "DEF",
    "Right Back": "DEF", "Wing Back": "DEF",
    "Midfielder": "MID", "Central Midfielder": "MID", "Defensive Midfielder": "MID",
    "Attacking Midfielder": "MID", "Wide Midfielder": "MID",
    "Forward": "FWD", "Striker": "FWD", "Left Winger": "FWD", "Right Winger": "FWD",
}


def role_to_group(role_name: str) -> str:
    for key, group in ROLE_TO_GROUP.items():
        if key.lower() in role_name.lower():
            return group
    return "MID"  # default fallback


def compute_performance_score(stats: Dict, role_group: str) -> float:
    """Compute a weighted performance score for a player given their stats and role."""
    weights = POSITION_STAT_WEIGHTS.get(role_group, POSITION_STAT_WEIGHTS["MID"])
    total = stats.get("minutesOnField", 0)
    if total == 0:
        return 0.0
    per90 = 90.0 / total  # normalize to per-90 minutes
    score = 0.0
    for stat, w in weights.items():
        val = stats.get(stat, 0) or 0
        score += val * per90 * w
    return round(score, 4)


def compute_efficiency_metrics(stats: Dict) -> Dict:
    """Compute % metrics that capture efficiency regardless of volume."""
    def safe_pct(num, denom):
        return round(num / denom * 100, 2) if denom else 0.0

    return {
        "pass_accuracy": safe_pct(stats.get("successfulPasses", 0), stats.get("passes", 0)),
        "duel_win_rate": safe_pct(stats.get("duelsWon", 0), stats.get("duels", 0)),
        "dribble_success": safe_pct(stats.get("successfulDribbles", 0), stats.get("dribbles", 0)),
        "shot_accuracy": safe_pct(stats.get("shotsOnTarget", 0), stats.get("shots", 0)),
        "aerial_win_rate": safe_pct(stats.get("aerialDuelsWon", 0), stats.get("aerialDuels", 0)),
        "cross_accuracy": safe_pct(stats.get("successfulCrosses", 0), stats.get("crosses", 0)),
        "def_action_success": safe_pct(stats.get("successfulDefensiveAction", 0), stats.get("defensiveActions", 0)),
    }


def build_player_feature_vector(
    player_profile: Dict,
    match_stats_list: List[Dict],  # list of per-match stat blocks for this player
    opponent_team_id: Optional[int] = None,
) -> Optional[Dict]:
    """
    Merge player profile + aggregated match stats into a flat feature dict.
    
    Args:
        player_profile: The player JSON object (wyId, role, birthDate, etc.)
        match_stats_list: List of stat dicts (total block) from each match JSON
        opponent_team_id: If provided, can filter or weight recent form
    
    Returns:
        Feature dict ready to be put in a DataFrame row, or None if no valid stats.
    """
    valid_stats = [s for s in match_stats_list if s.get("minutesOnField", 0) > 0]
    if not valid_stats:
        return None

    role_name = player_profile.get("role", {}).get("name", "Midfielder")
    role_group = role_to_group(role_name)

    # ── Aggregate stats across matches ──────────────────────────────────────
    agg = {}
    count = len(valid_stats)
    all_keys = valid_stats[0].keys()
    for k in all_keys:
        try:
            agg[k] = sum((s.get(k, 0) or 0) for s in valid_stats
                         if isinstance(s.get(k, 0), (int, float)))
        except TypeError:
            agg[k] = 0

    minutes_total = agg.get("minutesOnField", 1) or 1

    # Per-90 stats
    per90 = {k: round(v / minutes_total * 90, 4) for k, v in agg.items()
              if isinstance(v, (int, float))}

    # ── Performance score ────────────────────────────────────────────────────
    perf_score = compute_performance_score(agg, role_group)

    # ── Efficiency metrics ───────────────────────────────────────────────────
    efficiency = compute_efficiency_metrics(agg)

    # ── Recent form (last 3 matches weighted more) ───────────────────────────
    recent = valid_stats[-3:]
    recent_score = np.mean([
        compute_performance_score(s, role_group) for s in recent
    ]) if recent else 0.0

    # ── Age ──────────────────────────────────────────────────────────────────
    birth = player_profile.get("birthDate", "")
    age = 0
    if birth:
        try:
            from datetime import date, datetime
            bd = datetime.strptime(birth, "%Y-%m-%d").date()
            age = (date.today() - bd).days / 365.25
        except Exception:
            pass

    # ── Positions played (encoded as set of codes) ───────────────────────────
    # Passed in via match_stats_list items that may have a "positions" list
    all_positions = set()
    for s in match_stats_list:
        for pos in s.get("positions", []):
            code = pos.get("position", {}).get("code", "")
            if code:
                all_positions.add(code)

    feature = {
        "playerId": player_profile.get("wyId"),
        "shortName": player_profile.get("shortName", ""),
        "role": role_name,
        "role_group": role_group,
        "age": round(age, 1),
        "matches_played": count,
        "total_minutes": minutes_total,
        "performance_score": perf_score,
        "recent_form_score": round(recent_score, 4),
        **{f"per90_{k}": v for k, v in per90.items()},
        **efficiency,
        "positions_played": ",".join(sorted(all_positions)),
    }
    return feature


def load_match_stats_json(filepath: str) -> List[Dict]:
    """Load a match stats JSON file and return the players list."""
    with open(filepath) as f:
        data = json.load(f)
    return data.get("players", [])


def build_dataset_from_files(
    match_stat_files: List[str],
    player_profiles: Dict[int, Dict],  # playerId -> profile dict
    opponent_team_id: Optional[int] = None,
) -> pd.DataFrame:
    """
    Given multiple match stat files and a player profile lookup, 
    build a full feature DataFrame.
    
    Args:
        match_stat_files: List of paths to match JSON files
        player_profiles: Dict mapping wyId -> player profile dict
        opponent_team_id: Filter/weight for a specific opponent

    Returns:
        DataFrame with one row per player
    """
    # Collect all stats per player
    player_stats_map: Dict[int, List[Dict]] = {}

    for filepath in match_stat_files:
        match_players = load_match_stats_json(filepath)
        for entry in match_players:
            pid = entry.get("playerId")
            if pid is None:
                continue
            if pid not in player_stats_map:
                player_stats_map[pid] = []
            # Attach positions and total stats together for convenience
            combined = dict(entry.get("total", {}))
            combined["positions"] = entry.get("positions", [])
            combined["matchId"] = entry.get("matchId")
            player_stats_map[pid].append(combined)

    rows = []
    for pid, stats_list in player_stats_map.items():
        profile = player_profiles.get(pid, {"wyId": pid, "role": {"name": "Midfielder"}})
        row = build_player_feature_vector(profile, stats_list, opponent_team_id)
        if row:
            rows.append(row)

    return pd.DataFrame(rows)
