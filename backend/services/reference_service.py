from __future__ import annotations

import csv
from functools import lru_cache

from app.config import settings


@lru_cache(maxsize=1)
def get_supported_teams() -> set[str]:
    path = settings.resolved_stadium_map_path
    if not path.exists():
        return set()

    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return {row["team_name"].strip() for row in reader if row.get("team_name")}
