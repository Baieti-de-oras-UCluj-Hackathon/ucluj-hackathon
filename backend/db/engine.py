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
        if "firebase_uid" not in columns:
            await conn.execute(text("ALTER TABLE users ADD COLUMN firebase_uid VARCHAR(128)"))
            await conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_firebase_uid ON users (firebase_uid)"))
        if "full_name" not in columns:
            await conn.execute(text("ALTER TABLE users ADD COLUMN full_name VARCHAR(255)"))

        tables = {r[0] for r in (await conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))).fetchall()}
        print(f"DEBUG: init_db detected tables: {tables}")
        if "messages" in tables:
            msg_cols = {r[1] for r in (await conn.execute(text("PRAGMA table_info(messages)"))).fetchall()}
            if "author_id" not in msg_cols:
                await conn.execute(text("ALTER TABLE messages ADD COLUMN author_id VARCHAR(36) DEFAULT 'legacy-id'"))
                await conn.execute(text("CREATE INDEX IF NOT EXISTS ix_messages_author_id ON messages (author_id)"))
            if "channel_id" not in msg_cols:
                await conn.execute(text("ALTER TABLE messages ADD COLUMN channel_id VARCHAR(255) DEFAULT 'general'"))
                await conn.execute(text("CREATE INDEX IF NOT EXISTS ix_messages_channel_id ON messages (channel_id)"))
        if "sr_standings" in tables:
            sr_cols = {r[1] for r in (await conn.execute(text("PRAGMA table_info(sr_standings)"))).fetchall()}
            if "group_name" not in sr_cols:
                await conn.execute(text("ALTER TABLE sr_standings ADD COLUMN group_name VARCHAR(60) DEFAULT 'Superliga'"))

        if "sr_teams" in tables:
            st_cols = {r[1] for r in (await conn.execute(text("PRAGMA table_info(sr_teams)"))).fetchall()}
            if "venue_id" not in st_cols:
                await conn.execute(text("ALTER TABLE sr_teams ADD COLUMN venue_id VARCHAR(60) DEFAULT ''"))
            if "logo_url" not in st_cols:
                await conn.execute(text("ALTER TABLE sr_teams ADD COLUMN logo_url VARCHAR(512) DEFAULT ''"))

        if "sr_fixtures" in tables:
            sf_cols = {r[1] for r in (await conn.execute(text("PRAGMA table_info(sr_fixtures)"))).fetchall()}
            if "matchday" not in sf_cols:
                await conn.execute(text("ALTER TABLE sr_fixtures ADD COLUMN matchday INTEGER"))
