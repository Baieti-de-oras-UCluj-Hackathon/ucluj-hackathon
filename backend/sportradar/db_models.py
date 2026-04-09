from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import String, Integer, Boolean, DateTime, Text, Float
from sqlalchemy.orm import Mapped, mapped_column

from db.models import Base


class SrCompetition(Base):
    __tablename__ = "sr_competitions"

    id: Mapped[str] = mapped_column(String(60), primary_key=True)
    name: Mapped[str] = mapped_column(String(120), default="")
    category_name: Mapped[str] = mapped_column(String(120), default="")
    country_code: Mapped[str] = mapped_column(String(10), default="")
    gender: Mapped[str] = mapped_column(String(10), default="")


class SrSeason(Base):
    __tablename__ = "sr_seasons"

    id: Mapped[str] = mapped_column(String(60), primary_key=True)
    competition_id: Mapped[str] = mapped_column(String(60), default="")
    name: Mapped[str] = mapped_column(String(120), default="")
    start_date: Mapped[str] = mapped_column(String(20), default="")
    end_date: Mapped[str] = mapped_column(String(20), default="")
    year: Mapped[str] = mapped_column(String(10), default="")


class SrSeasonCoverage(Base):
    __tablename__ = "sr_season_coverage"

    season_id: Mapped[str] = mapped_column(String(60), primary_key=True)
    competition_id: Mapped[str] = mapped_column(String(60), default="")
    max_coverage_level: Mapped[str] = mapped_column(String(40), default="")
    max_covered_matches: Mapped[int | None] = mapped_column(Integer, nullable=True)
    scheduled_matches: Mapped[int | None] = mapped_column(Integer, nullable=True)
    players_statistics: Mapped[bool] = mapped_column(Boolean, default=False)
    team_statistics: Mapped[bool] = mapped_column(Boolean, default=False)
    lineups: Mapped[bool] = mapped_column(Boolean, default=False)
    squads: Mapped[bool] = mapped_column(Boolean, default=False)
    transfers: Mapped[bool] = mapped_column(Boolean, default=False)
    missing_players: Mapped[bool] = mapped_column(Boolean, default=False)
    raw_json: Mapped[str] = mapped_column(Text, default="")
    synced_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )


class SrTeam(Base):
    __tablename__ = "sr_teams"

    id: Mapped[str] = mapped_column(String(60), primary_key=True)
    name: Mapped[str] = mapped_column(String(120), default="")
    short_name: Mapped[str] = mapped_column(String(60), default="")
    abbreviation: Mapped[str] = mapped_column(String(10), default="")
    country: Mapped[str] = mapped_column(String(60), default="")
    country_code: Mapped[str] = mapped_column(String(10), default="")
    venue_id: Mapped[str] = mapped_column(String(60), default="")
    venue_name: Mapped[str] = mapped_column(String(200), default="")
    venue_city: Mapped[str] = mapped_column(String(120), default="")
    venue_capacity: Mapped[int | None] = mapped_column(Integer, nullable=True)
    manager_name: Mapped[str] = mapped_column(String(120), default="")
    squad_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    logo_url: Mapped[str] = mapped_column(String(512), default="")


class SrPlayer(Base):
    __tablename__ = "sr_players"

    id: Mapped[str] = mapped_column(String(60), primary_key=True)
    team_id: Mapped[str] = mapped_column(String(60), default="", index=True)
    name: Mapped[str] = mapped_column(String(120), default="")
    position: Mapped[str] = mapped_column(String(30), default="")
    nationality: Mapped[str] = mapped_column(String(60), default="")
    date_of_birth: Mapped[str] = mapped_column(String(20), default="")
    height: Mapped[int | None] = mapped_column(Integer, nullable=True)
    weight: Mapped[int | None] = mapped_column(Integer, nullable=True)
    jersey_number: Mapped[int | None] = mapped_column(Integer, nullable=True)


class SrFixture(Base):
    __tablename__ = "sr_fixtures"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    season_id: Mapped[str] = mapped_column(String(60), default="", index=True)
    scheduled: Mapped[str] = mapped_column(String(30), default="")
    status: Mapped[str] = mapped_column(String(30), default="")
    home_team_id: Mapped[str] = mapped_column(String(60), default="")
    home_team_name: Mapped[str] = mapped_column(String(120), default="")
    away_team_id: Mapped[str] = mapped_column(String(60), default="")
    away_team_name: Mapped[str] = mapped_column(String(120), default="")
    home_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    away_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    venue_name: Mapped[str] = mapped_column(String(200), default="")
    round_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    matchday: Mapped[int | None] = mapped_column(Integer, nullable=True)


class SrStanding(Base):
    __tablename__ = "sr_standings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    season_id: Mapped[str] = mapped_column(String(60), default="", index=True)
    group_name: Mapped[str] = mapped_column(String(60), default="Superliga")
    group_id: Mapped[str] = mapped_column(String(60), default="")
    team_id: Mapped[str] = mapped_column(String(60), default="")
    team_name: Mapped[str] = mapped_column(String(120), default="")
    rank: Mapped[int | None] = mapped_column(Integer, nullable=True)
    played: Mapped[int | None] = mapped_column(Integer, nullable=True)
    wins: Mapped[int | None] = mapped_column(Integer, nullable=True)
    draws: Mapped[int | None] = mapped_column(Integer, nullable=True)
    losses: Mapped[int | None] = mapped_column(Integer, nullable=True)
    goals_for: Mapped[int | None] = mapped_column(Integer, nullable=True)
    goals_against: Mapped[int | None] = mapped_column(Integer, nullable=True)
    goal_diff: Mapped[int | None] = mapped_column(Integer, nullable=True)
    points: Mapped[int | None] = mapped_column(Integer, nullable=True)
    form: Mapped[str] = mapped_column(String(20), default="")
    synced_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )


class SrMatchStats(Base):
    __tablename__ = "sr_match_stats"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fixture_id: Mapped[str] = mapped_column(String(80), default="", index=True)
    team_id: Mapped[str] = mapped_column(String(60), default="")
    team_name: Mapped[str] = mapped_column(String(120), default="")
    ball_possession: Mapped[int | None] = mapped_column(Integer, nullable=True)
    shots_total: Mapped[int | None] = mapped_column(Integer, nullable=True)
    shots_on_target: Mapped[int | None] = mapped_column(Integer, nullable=True)
    corner_kicks: Mapped[int | None] = mapped_column(Integer, nullable=True)
    fouls: Mapped[int | None] = mapped_column(Integer, nullable=True)
    yellow_cards: Mapped[int | None] = mapped_column(Integer, nullable=True)
    red_cards: Mapped[int | None] = mapped_column(Integer, nullable=True)
    offsides: Mapped[int | None] = mapped_column(Integer, nullable=True)
    free_kicks: Mapped[int | None] = mapped_column(Integer, nullable=True)
    goal_kicks: Mapped[int | None] = mapped_column(Integer, nullable=True)
    throw_ins: Mapped[int | None] = mapped_column(Integer, nullable=True)


class SrLineup(Base):
    __tablename__ = "sr_lineups"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fixture_id: Mapped[str] = mapped_column(String(80), default="", index=True)
    team_id: Mapped[str] = mapped_column(String(60), default="")
    team_name: Mapped[str] = mapped_column(String(120), default="")
    formation: Mapped[str] = mapped_column(String(20), default="")
    players_json: Mapped[str] = mapped_column(Text, default="[]")


class SrTimelineEvent(Base):
    __tablename__ = "sr_timeline_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fixture_id: Mapped[str] = mapped_column(String(80), default="", index=True)
    event_id: Mapped[str] = mapped_column(String(80), default="")
    event_type: Mapped[str] = mapped_column(String(80), default="")
    minute: Mapped[int | None] = mapped_column(Integer, nullable=True)
    team_id: Mapped[str] = mapped_column(String(60), default="")
    player_name: Mapped[str] = mapped_column(String(200), default="")
    detail: Mapped[str] = mapped_column(Text, default="")
    synced_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )


class SrSyncLog(Base):
    __tablename__ = "sr_sync_log"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    entity_type: Mapped[str] = mapped_column(String(40), default="")
    entity_id: Mapped[str] = mapped_column(String(80), default="")
    operation: Mapped[str] = mapped_column(String(30), default="")
    record_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(20), default="ok")
    error_message: Mapped[str] = mapped_column(Text, default="")
    synced_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
