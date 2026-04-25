
import asyncio
from sqlalchemy import text
from db.engine import engine

async def check():
    async with engine.connect() as conn:
        res = await conn.execute(text("SELECT email, full_name FROM users"))
        rows = res.fetchall()
        print("Users in DB:")
        for r in rows:
            print(f"Email: {r[0]}, Full Name: {r[1]}")

if __name__ == "__main__":
    asyncio.run(check())
