from __future__ import annotations

import asyncio
import json
import logging
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, Depends, Query

from clients.sportradar_client import SportradarClient
from core.security import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()

_CACHE_DIR = Path(__file__).parent / "_sr_match_cache"
_CACHE_TTL = 24 * 3600  # completed matches don't change


def _cache_path(match_id: str) -> Path:
    safe = match_id.replace(":", "_").replace("/", "_")
    return _CACHE_DIR / f"{safe}.json"


def _load_cache(match_id: str) -> dict | None:
    try:
        p = _cache_path(match_id)
        if not p.exists():
            return None
        data = json.loads(p.read_text(encoding="utf-8"))
        cached_at = datetime.fromisoformat(data["cached_at"])
        age = (datetime.now(timezone.utc) - cached_at).total_seconds()
        if age > _CACHE_TTL:
            return None
        return data["details"]
    except Exception:
        return None


def _save_cache(match_id: str, details: dict) -> None:
    try:
        _CACHE_DIR.mkdir(parents=True, exist_ok=True)
        payload = {
            "cached_at": datetime.now(timezone.utc).isoformat(),
            "details": details,
        }
        _cache_path(match_id).write_text(
            json.dumps(payload, default=str), encoding="utf-8"
        )
    except Exception as exc:
        logger.warning("Could not write match details cache: %s", exc)


@router.get("/match-details")
async def match_details(
    match_id: str = Query(..., description="Sportradar sport_event ID"),
    _user=Depends(get_current_user),
):
    """Return official lineups + team statistics for a completed match."""
    cached = _load_cache(match_id)
    if cached:
        return cached

    client = SportradarClient()
    try:
        summary, lineups = await asyncio.gather(
            client.sport_event_summary(match_id),
            client.sport_event_lineups(match_id),
            return_exceptions=True,
        )
    except Exception as exc:
        logger.warning("match-details fetch failed for %s: %s", match_id, exc)
        summary, lineups = None, None

    if isinstance(summary, Exception):
        summary = None
    if isinstance(lineups, Exception):
        lineups = None

    result = _build_details(match_id, summary, lineups)

    if result.get("home_stats") or result.get("home_lineup"):
        _save_cache(match_id, result)

    return result


# ---------------------------------------------------------------------------

def _build_details(match_id: str, summary: dict | None, lineups: dict | None) -> dict:
    home_stats: dict = {}
    away_stats: dict = {}
    home_lineup: list[dict] = []
    away_lineup: list[dict] = []

    # Player stats by id from summary, keyed by side
    home_player_stats: dict[str, dict] = {}
    away_player_stats: dict[str, dict] = {}

    if summary:
        totals = (summary.get("statistics") or {}).get("totals", {})
        for comp in totals.get("competitors") or []:
            s = comp.get("statistics", {})
            qual = comp.get("qualifier", "")
            parsed = {
                "ball_possession": s.get("ball_possession"),
                "shots_on_target": s.get("shots_on_target"),
                "shots_off_target": s.get("shots_off_target"),
                "shots_total": s.get("shots_total"),
                "corner_kicks": s.get("corner_kicks"),
                "yellow_cards": s.get("yellow_cards"),
                "red_cards": s.get("red_cards"),
                "offsides": s.get("offsides"),
                "fouls": s.get("fouls"),
                "goalkeeper_saves": s.get("shots_saved"),  # Sportradar uses shots_saved
            }
            # Build per-player stats lookup
            player_stats_map: dict[str, dict] = {}
            for p in comp.get("players") or []:
                pid = p.get("id", "")
                stat = p.get("statistics") or {}
                player_stats_map[pid] = {
                    "starter": p.get("starter", False),
                    "goals_scored": stat.get("goals_scored", 0),
                    "assists": stat.get("assists", 0),
                    "yellow_cards": stat.get("yellow_cards", 0),
                    "red_cards": stat.get("red_cards", 0),
                    "shots_on_target": stat.get("shots_on_target", 0),
                }
            if qual == "home":
                home_stats = parsed
                home_player_stats = player_stats_map
            elif qual == "away":
                away_stats = parsed
                away_player_stats = player_stats_map

    if lineups:
        lineup_block = lineups.get("lineups", {})
        for comp in lineup_block.get("competitors") or []:
            qual = comp.get("qualifier", "")
            player_stats_map = home_player_stats if qual == "home" else away_player_stats
            players = []
            for p in comp.get("players") or []:
                pid = p.get("id", "")
                pstat = player_stats_map.get(pid, {})
                # Position: map verbose names to short codes
                pos_raw = p.get("position", p.get("type", ""))
                pos = _short_position(pos_raw)
                is_starter = p.get("starter", False) or pstat.get("starter", False)
                players.append({
                    "name": p.get("name", ""),
                    "jersey_number": p.get("jersey_number"),
                    "type": "starter" if is_starter else "substitute",
                    "position": pos,
                    "goals_scored": pstat.get("goals_scored", 0),
                    "assists": pstat.get("assists", 0),
                    "yellow_cards": pstat.get("yellow_cards", 0),
                    "red_cards": pstat.get("red_cards", 0),
                    "shots_on_target": pstat.get("shots_on_target", 0),
                    "minutes_played": None,
                })
            # Sort: starters first
            players.sort(key=lambda x: (0 if x["type"] == "starter" else 1))
            if qual == "home":
                home_lineup = players
            elif qual == "away":
                away_lineup = players

    return {
        "match_id": match_id,
        "home_stats": home_stats,
        "away_stats": away_stats,
        "home_lineup": home_lineup,
        "away_lineup": away_lineup,
    }


def _short_position(pos: str) -> str:
    p = pos.lower()
    if "goalkeeper" in p or p == "g":
        return "G"
    if "back" in p or "defender" in p or p == "d":
        return "D"
    if "midfield" in p or "midfielder" in p or p == "m":
        return "M"
    if "forward" in p or "winger" in p or "striker" in p or "attack" in p or p == "f":
        return "F"
    return pos[:1].upper() if pos else "?"
