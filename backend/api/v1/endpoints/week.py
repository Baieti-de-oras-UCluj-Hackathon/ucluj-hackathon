import os
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends

from core.dependencies import get_feature_service, get_model_service, get_stadium_map
from core.security import get_current_user
from services.explanation_service import ExplanationService
from services.feature_service import FeatureService
from services.fixture_service import FixtureService
from services.model_service import ModelService

router = APIRouter()

TRACKED_TEAM = "Universitatea Cluj"


def _get_fixture_service(
    feature_svc: FeatureService = Depends(get_feature_service),
    stadium_map: dict = Depends(get_stadium_map),
) -> FixtureService:
    return FixtureService(feature_svc._df, stadium_map)


@router.get("/week-fixtures")
def week_fixtures(
    _user=Depends(get_current_user),
    feature_svc: FeatureService = Depends(get_feature_service),
    model_svc: ModelService = Depends(get_model_service),
    fixture_svc: FixtureService = Depends(_get_fixture_service),
):
    """Return all Liga 1 fixtures for the current week (Mon–Sun).
    
    Because the dataset covers historical matches (up to 2024-2025 season),
    we also fall back to the most recent 5 real fixtures of the tracked team
    plus generate a predictive upcoming block so the UI always has content.
    """
    now = datetime.now(timezone.utc)
    # Monday of current week
    monday = (now - timedelta(days=now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    sunday = monday + timedelta(days=7)

    df = fixture_svc._df.copy()
    df["match_date_parsed"] = df["match_date"].apply(_parse_dt)

    mask = (df["match_date_parsed"] >= monday) & (df["match_date_parsed"] < sunday)
    week_df = df[mask].sort_values("match_date_parsed")

    fixtures = [fixture_svc._row_to_fixture(r) for _, r in week_df.iterrows()]

    # Team name normalization map: JSON name -> CSV name
    NAME_MAP = {
        "Universitatea Cluj": "U Cluj",
        "FCS Bucureşti": "FCSB",
        "FCS Bucuresti": "FCSB",
        "Dinamo Bucureşti": "Dinamo Bucuresti",
        "Rapid Bucureşti": "Rapid Bucuresti",
        "Oţelul": "Otelul Galati",
        "Otelul": "Otelul Galati",
        "Botoşani": "FC Botosani",
        "Botosani": "FC Botosani",
        "Hermannstadt": "FC Hermannstadt",
        "Farul Constanţa": "Farul Constanta",
        "Farul Constanta": "Farul Constanta",
        "Universitatea Craiova": "Univ. Craiova",
        "Argeș": "FC Arges",
        "Arges": "FC Arges",
        "Unirea Slobozia": "Unirea Slobozia",
        "Csikszereda Miercurea Ciuc": "Csikszereda M. Ciuc",
        "Metaloglobus": "Metaloglobus Bucuresti",
        "Petrolul 52": "Petrolul Ploiesti",
        "UTA Arad": "UTA Arad",
        "CFR Cluj": "CFR Cluj",
    }

    # NEW: Load fixtures EXCLUSIVELY from JSON files in drive_cache
    json_fixtures = []
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
    json_path = os.path.join(base_dir, "ml", "data", "drive_cache")
    
    if os.path.exists(json_path):
        import glob
        import re
        # Get all player stats JSONs
        files = glob.glob(os.path.join(json_path, "*_players_stats.json"))
        # Filter for U Cluj
        u_files = [f for f in files if "Universitatea Cluj" in f or "U Cluj" in f]
        # Sort them to be consistent
        u_files.sort()
        # Take up to 7 for the week
        selected_files = u_files[:7] 
        
        for idx, f in enumerate(selected_files):
            fname = os.path.basename(f)
            # Pattern to extract teams and score
            match = re.search(r"^(.*?) - (.*?), (.*?)[_]", fname)
            if match:
                h_raw, a_raw, score_str = match.groups()
                h_raw, a_raw = h_raw.strip(), a_raw.strip()
                
                # Normalize names for feature lookup
                h = NAME_MAP.get(h_raw, h_raw)
                a = NAME_MAP.get(a_raw, a_raw)

                try:
                    hs, as_ = map(int, score_str.split("-"))
                except:
                    hs, as_ = 0, 0
                
                # Assign a specific day of this week (Mon=0, Tue=1, ...)
                mock_dt = monday + timedelta(days=idx)
                
                json_fixtures.append({
                    "match_id": f"json_{idx}",
                    "season": "2025-2026",
                    "home_team": h, # Use normalized name for UI and ML
                    "away_team": a,
                    "home_score": hs,
                    "away_score": as_,
                    "venue": "Cluj Arena" if h == "U Cluj" else "Stadion Advers",
                    "competition": "SuperLiga",
                    "match_date": mock_dt.strftime("%Y-%m-%dT18:00:00Z")
                })

    # OVERWRITE: Only use JSON fixtures if found, else empty (as requested: "ia doar de aici")
    fixtures = json_fixtures
    if not fixtures:
        return [] # Return empty if no JSONs found in that specific folder

    # Attach ML probability + key drivers + MOCK DATES for 2026
    result = []
    # Generate dates: Mon to Sun of current week
    mock_dates = [(monday + timedelta(days=i)) for i in range(len(fixtures))]
    
    for idx, f in enumerate(fixtures):
        item = dict(f)
        # Force date to 2026 mock date
        mock_dt = mock_dates[idx] if idx < len(mock_dates) else sunday
        item["match_date"] = mock_dt.strftime("%Y-%m-%dT%H:%M:%SZ")
        
        try:
            if model_svc.is_ready:
                feat = feature_svc.build_feature_vector(
                    f["home_team"], f["away_team"], model_svc.feature_cols
                )
                prob = round(model_svc.predict_proba(feat), 4)
                expl = ExplanationService(model_svc).explain(feat, prob)
                item["home_win_probability"] = prob
                item["key_drivers"] = expl["top_drivers"][:3]
                item["top_risks"] = expl["top_risks"][:2]
                item["narrative"] = expl["narrative"]
            else:
                item["home_win_probability"] = None
                item["key_drivers"] = []
                item["top_risks"] = []
                item["narrative"] = "Model not ready."
        except Exception:
            item["home_win_probability"] = None
            item["key_drivers"] = []
            item["top_risks"] = []
            item["narrative"] = ""
        result.append(item)

    return result


def _parse_dt(val) -> datetime:
    if isinstance(val, datetime):
        return val if val.tzinfo else val.replace(tzinfo=timezone.utc)
    try:
        s = str(val)
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except Exception:
        return datetime(1970, 1, 1, tzinfo=timezone.utc)
