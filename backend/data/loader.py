import logging
from pathlib import Path
from typing import Any

import joblib
import pandas as pd

logger = logging.getLogger(__name__)


def load_all_data(path: Path) -> pd.DataFrame:
    if not path.exists():
        logger.warning("Data file not found at %s; returning empty DataFrame", path)
        return pd.DataFrame()
    df = pd.read_csv(path)
    df["match_date"] = pd.to_datetime(df["match_date"], errors="coerce")
    df = df.sort_values("match_date").reset_index(drop=True)
    logger.info("Loaded %d matches from %s", len(df), path.name)
    return df


def load_stadium_map(path: Path) -> dict[str, str]:
    if not path.exists():
        logger.warning("Stadium map not found at %s", path)
        return {}
    df = pd.read_csv(path)
    mapping = dict(zip(df["team_name"], df["stadium_name"]))
    logger.info("Loaded %d stadium mappings", len(mapping))
    return mapping


def load_model_bundle(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        logger.warning("Model bundle not found at %s; prediction disabled", path)
        return None
    bundle = joblib.load(path)
    logger.info(
        "Model bundle loaded (schema %s, %d features)",
        bundle.get("schema_version", "unknown"),
        len(bundle.get("feature_cols", [])),
    )
    return bundle
