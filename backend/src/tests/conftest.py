import pytest
import pytest_asyncio
import asyncpg
import os
from dotenv import load_dotenv
from main import app

load_dotenv()

@pytest_asyncio.fixture(autouse=True)
async def cleanup_db():
    yield
    conn = await asyncpg.connect(os.getenv("DATABASE_URL"))
    try:
        await conn.execute("TRUNCATE TABLE activities, plans, users CASCADE")
    finally:
        await conn.close()


@pytest.fixture(autouse=True)
def cleanup_dependency_overrides():
    yield
    app.dependency_overrides.clear()