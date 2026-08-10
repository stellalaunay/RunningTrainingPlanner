import os
from dotenv import load_dotenv
from fastapi import FastAPI
import asyncpg
from contextlib import asynccontextmanager


load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.pool = await asyncpg.create_pool(DATABASE_URL)
    yield
    await app.state.pool.close()

app = FastAPI(lifespan=lifespan)


# run using: uv run fastapi dev

# create user -> on create account
@app.post("/users")
async def create_user(name: str, email: str):
    async with app.state.pool.acquire() as conn:
        await conn.execute( # returns 200 OK if success, 500 if fail, can catch errors for more robust error handling
            "INSERT INTO users (name, email) VALUES ($1, $2)",
            name, email
        )
        return {"status": "success"}

# need to handle users relogging in 
    
# get user (for profile)
@app.get("/users/{user_id}")
async def get_user(user_id: int):
    async with app.state.pool.acquire() as conn:
        row = await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
        return dict(row)

# create activity
@app.post("/activity")
async def create_activity(name: str, type: str, date: str): # what is date type?
    async with app.state.pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO activities (name, type, date) VALUES ($1, $2, $3)",
            name, type, date
        )
        return {"status": "success"}
    



# create plan

# edit activity

# edit plan

# add photo (profile photo) -> same thing as edit profile?

# edit profile

# get activities (week view) -> can only access day view from week view, need separate operation?
