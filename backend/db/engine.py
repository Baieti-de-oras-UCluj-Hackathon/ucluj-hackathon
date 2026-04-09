from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy import text

from app.config import settings

engine = create_async_engine(settings.database_url, echo=False)

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def init_db():
    from db.models import Base
    import sportradar.db_models  # noqa: F401 — registers sr_* tables with Base.metadata
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        result = await conn.execute(text("PRAGMA table_info(users)"))
        columns = {row[1] for row in result.fetchall()}
        if "team_name" not in columns:
            await conn.execute(text("ALTER TABLE users ADD COLUMN team_name VARCHAR(120)"))

        tables = {r[0] for r in (await conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))).fetchall()}
        if "sr_standings" in tables:
            sr_cols = {r[1] for r in (await conn.execute(text("PRAGMA table_info(sr_standings)"))).fetchall()}
            if "group_name" not in sr_cols:
                await conn.execute(text("ALTER TABLE sr_standings ADD COLUMN group_name VARCHAR(60) DEFAULT 'Superliga'"))
