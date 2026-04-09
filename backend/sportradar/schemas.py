from __future__ import annotations

from pydantic import BaseModel, Field


# =============================================================================
# COMPETITION / SEASON DISCOVERY
# =============================================================================

class SRCategory(BaseModel):
    id: str = ""
    name: str = ""
    country_code: str = ""


class SRCompetition(BaseModel):
    id: str = ""
    name: str = ""
    gender: str = ""
    category: SRCategory = Field(default_factory=SRCategory)


class SRSeason(BaseModel):
    id: str = ""
    name: str = ""
    start_date: str = ""
    end_date: str = ""
    year: str = ""
    competition_id: str = ""


class SRSeasonCoverage(BaseModel):
    season_id: str = ""
    competition_id: str = ""
    max_coverage_level: str = ""
    max_covered_matches: int | None = None
    scheduled_matches: int | None = None
    players_statistics: bool = False
    team_statistics: bool = False
    lineups: bool = False
    squads: bool = False
    transfers: bool = False
    missing_players: bool = False


# =============================================================================
# VENUE
# =============================================================================

class SRVenue(BaseModel):
    id: str = ""
    name: str = ""
    city_name: str = ""
    country_name: str = ""
    capacity: int | None = None


# =============================================================================
# TEAM / COMPETITOR
# =============================================================================

class SRManager(BaseModel):
    id: str = ""
    name: str = ""
    nationality: str = ""


class SRJersey(BaseModel):
    type: str = ""
    base: str = ""
    sleeve: str = ""
    number: str = ""


class SRTeam(BaseModel):
    id: str = ""
    name: str = ""
    short_name: str = ""
    abbreviation: str = ""
    country: str = ""
    country_code: str = ""
    gender: str = ""
    venue: SRVenue | None = None
    manager: SRManager | None = None


class SRPlayer(BaseModel):
    id: str = ""
    name: str = ""
    type: str = ""
    nationality: str = ""
    date_of_birth: str = ""
    height: int | None = None
    weight: int | None = None
    jersey_number: int | None = None


# =============================================================================
# FIXTURE / SPORT EVENT
# =============================================================================

class SRCompetitorRef(BaseModel):
    id: str = ""
    name: str = ""
    abbreviation: str = ""
    qualifier: str = ""


class SRSportEventContext(BaseModel):
    competition: SRCompetition = Field(default_factory=SRCompetition)
    season: SRSeason = Field(default_factory=SRSeason)
    round: dict | None = None
    stage: dict | None = None
    groups: list[dict] | None = None


class SRScore(BaseModel):
    home: int | None = None
    away: int | None = None


class SRPeriodScore(BaseModel):
    type: str = ""
    home_score: int | None = None
    away_score: int | None = None
    number: int | None = None


class SRSportEventStatus(BaseModel):
    status: str = ""
    match_status: str = ""
    home_score: int | None = None
    away_score: int | None = None
    winner_id: str = ""
    period_scores: list[SRPeriodScore] = Field(default_factory=list)


class SRSportEvent(BaseModel):
    id: str = ""
    scheduled: str = ""
    start_time_tbd: bool = False
    status: str = ""
    competitors: list[SRCompetitorRef] = Field(default_factory=list)
    venue: SRVenue | None = None
    sport_event_context: SRSportEventContext = Field(default_factory=SRSportEventContext)

    @property
    def home_team(self) -> SRCompetitorRef | None:
        return next((c for c in self.competitors if c.qualifier == "home"), None)

    @property
    def away_team(self) -> SRCompetitorRef | None:
        return next((c for c in self.competitors if c.qualifier == "away"), None)

    @property
    def round_number(self) -> int | None:
        r = self.sport_event_context.round
        if r and "number" in r:
            return r["number"]
        return None


# =============================================================================
# MATCH STATISTICS
# =============================================================================

class SRTeamStatistics(BaseModel):
    competitor_id: str = ""
    name: str = ""
    ball_possession: int | None = None
    shots_total: int | None = None
    shots_on_target: int | None = None
    corner_kicks: int | None = None
    fouls: int | None = None
    yellow_cards: int | None = None
    red_cards: int | None = None
    offsides: int | None = None
    free_kicks: int | None = None
    goal_kicks: int | None = None
    throw_ins: int | None = None


class SRSportEventSummary(BaseModel):
    sport_event: SRSportEvent = Field(default_factory=SRSportEvent)
    sport_event_status: SRSportEventStatus = Field(default_factory=SRSportEventStatus)
    statistics: list[SRTeamStatistics] = Field(default_factory=list)


# =============================================================================
# STANDINGS
# =============================================================================

class SRStandingsRow(BaseModel):
    competitor_id: str = ""
    competitor_name: str = ""
    rank: int | None = None
    played: int | None = None
    win: int | None = None
    draw: int | None = None
    loss: int | None = None
    goals_for: int | None = None
    goals_against: int | None = None
    goal_diff: int | None = None
    points: int | None = None
    form: str = ""
    current_outcome: str = ""


class SRStandingsGroup(BaseModel):
    id: str = ""
    name: str = ""
    type: str = ""
    rows: list[SRStandingsRow] = Field(default_factory=list)


# =============================================================================
# NORMALIZED APP-FACING MODELS (returned by sync services)
# =============================================================================

class NormalizedFixture(BaseModel):
    sr_id: str
    season_id: str
    scheduled: str
    status: str
    home_team_id: str
    home_team_name: str
    away_team_id: str
    away_team_name: str
    home_score: int | None = None
    away_score: int | None = None
    venue_name: str = ""
    round_number: int | None = None


class NormalizedTeam(BaseModel):
    sr_id: str
    name: str
    short_name: str = ""
    abbreviation: str = ""
    country: str = ""
    country_code: str = ""
    venue_name: str = ""
    manager_name: str = ""


class NormalizedStandingsRow(BaseModel):
    team_id: str
    team_name: str
    rank: int | None = None
    played: int | None = None
    wins: int | None = None
    draws: int | None = None
    losses: int | None = None
    goals_for: int | None = None
    goals_against: int | None = None
    goal_diff: int | None = None
    points: int | None = None
    form: str = ""
