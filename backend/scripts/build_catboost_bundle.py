from __future__ import annotations

from pathlib import Path
from typing import Any
import sys

import joblib
import pandas as pd
from catboost import CatBoostClassifier

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from ml.feature_config import BASE_FEATURES, OPTIONAL_FEATURES, OPTIMIZABLE_FEATURES, TARGET_COL


def _build_bounds(df: pd.DataFrame) -> dict[str, dict[str, float]]:
    bounds: dict[str, dict[str, float]] = {}
    for feat in OPTIMIZABLE_FEATURES:
        if feat not in df.columns:
            continue
        col = pd.to_numeric(df[feat], errors="coerce").dropna()
        if col.empty:
            continue
        lo = float(col.quantile(0.10))
        hi = float(col.quantile(0.90))
        if hi <= lo:
            hi = float(col.max())
            lo = float(col.min())
        bounds[feat] = {"low": round(lo, 4), "high": round(hi, 4)}
    return bounds


def build_bundle(data_csv: Path, output_joblib: Path) -> dict[str, Any]:
    df = pd.read_csv(data_csv)
    if TARGET_COL not in df.columns:
        # Binary thesis target: Home Win (1) vs Not Home Win (0)
        df[TARGET_COL] = (df["home_score"] > df["away_score"]).astype(int)

    feature_cols = [c for c in BASE_FEATURES + OPTIONAL_FEATURES if c in df.columns]
    if not feature_cols:
        raise RuntimeError("No expected model features found in dataset.")

    X = df[feature_cols].apply(pd.to_numeric, errors="coerce")
    y = pd.to_numeric(df[TARGET_COL], errors="coerce").fillna(0).astype(int)

    medians = {c: float(v) for c, v in X.median(numeric_only=True).to_dict().items()}
    X = X.fillna(medians)

    model = CatBoostClassifier(
        iterations=700,
        depth=6,
        learning_rate=0.05,
        loss_function="Logloss",
        eval_metric="AUC",
        random_seed=42,
        verbose=False,
    )
    model.fit(X, y)

    bundle = {
        "schema_version": "uhack-catboost-v1",
        "model": model,
        "raw_model": model,
        "imputer": None,
        "feature_cols": feature_cols,
        "bounds": _build_bounds(df),
        "medians": medians,
    }

    output_joblib.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(bundle, output_joblib)
    return bundle


if __name__ == "__main__":
    backend_root = Path(__file__).resolve().parents[1]
    data_csv = backend_root.parent / "data" / "All_Data.csv"
    output = backend_root / "ml" / "umbraro_catboost_bundle.joblib"
    bundle = build_bundle(data_csv, output)
    print(f"saved: {output}")
    print(f"features: {len(bundle['feature_cols'])}")
