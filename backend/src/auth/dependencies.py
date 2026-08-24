from fastapi import Header, HTTPException, Depends
from firebase_admin import auth
import asyncpg
from database.postgres import get_postgres
from uuid import UUID


async def get_current_firebase_uid(authorization: str = Header(...)) -> str:
    token = authorization.replace("Bearer ", "")
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


async def get_current_user_id(
    firebase_uid: str = Depends(get_current_firebase_uid),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> UUID:

    async with db_pool.acquire() as conn:
        row = await conn.fetchrow("SELECT user_id FROM users WHERE firebase_uid = $1", firebase_uid)
        if row is None:
            raise HTTPException(status_code=404, detail="User not found")
        return row["user_id"]
