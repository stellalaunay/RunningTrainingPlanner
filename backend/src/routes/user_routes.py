from fastapi import HTTPException, Query, Path, Body, APIRouter, Depends
from models.user_models import User, UserCreate, UserUpdate
from database.postgres import get_postgres
from auth.dependencies import get_current_user_id, get_current_firebase_uid
from typing import List
import asyncpg
from loguru import logger
from firebase_admin import auth
from uuid import UUID

user_router = APIRouter()

# ------------- Create User ------------
@user_router.post("/users", response_model = User)
async def create_user(
    user: UserCreate = Body(...),
    firebase_uid: str = Depends(get_current_firebase_uid),
    db_pool: asyncpg.Pool = Depends(get_postgres), 
) -> User:
    
    """
    Create a new user.
    Parameters
    ----------
    user : UserCreate
        The user details to create.
    firebase_uid: str
        The firebase_uid of the user, from firebase auth
    db_pool : asyncpg.Pool
        Database connection pool injected by dependency.
    Returns
    -------
    User
        The newly created user.
    """


    query = """
    INSERT INTO users (first_name, last_name, profile_photo_url, default_distance_unit, easy_pace, long_run_pace, speed_pace, firebase_uid)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *
    """

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                user.first_name,
                user.last_name,
                user.profile_photo_url, 
                user.default_distance_unit,
                user.easy_pace,
                user.long_run_pace,
                user.speed_pace,
                firebase_uid,
            )

            return User(**dict(result))
           
    except Exception as e:
        logger.error(f"Error during user creation: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during user creation")



# ------------- Get My User ------------
@user_router.get("/users/me", response_model = User)
async def get_my_user(
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> User:
    """
    Get a user by its ID.
    Parameters
    ----------
    current_user_id : UUID
        The ID of the user currentlu logged in, making the request.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    User
        The user details for the given ID.
    """

    query = """
        SELECT * 
        FROM users 
        WHERE user_id = $1
    """

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, current_user_id)
            if result is None:
                logger.warning(f"User with ID {current_user_id} not found")
                raise HTTPException(status_code=404, detail="User not found")
                
            return User(**dict(result))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching user by ID: {e}")
        raise HTTPException(
            status_code=500, detail="Internal server error during user retrieval"
        )

# ------------- Edit User ------------
@user_router.put("/users", response_model = User)
async def update_user(
    user: UserUpdate = Body(...),
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> User:


    """
    Update a user by its ID.
    Parameters
    ----------
    user : UserUpdate
        The fields to update (partial updates allowed).
    current_user_id: UUID
        The ID of the user currently logged in, making the request.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    User
        The updated user details.
    """


    query = """
    UPDATE users
    SET first_name = COALESCE($1, first_name),
        last_name = COALESCE($2, last_name),
        profile_photo_url = COALESCE($3, profile_photo_url),
        default_distance_unit = COALESCE($4, default_distance_unit),
        easy_pace = COALESCE($5, easy_pace),
        long_run_pace = COALESCE($6, long_run_pace),
        speed_pace = COALESCE($7, speed_pace)
    WHERE user_id = $8
    returning *
    """

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                user.first_name,
                user.last_name,
                user.profile_photo_url,
                user.default_distance_unit,
                user.easy_pace,
                user.long_run_pace,
                user.speed_pace,
                current_user_id
            )

            if result is None:
                logger.warning(f"User with ID {current_user_id} not found for update")
                raise HTTPException(status_code=404, detail="User not found")
            
            return User(**dict(result))
                
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating user: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during user update")
    



# ------------- Delete User ------------
@user_router.delete("/users")
async def delete_user(
    current_user_id: UUID = Depends(get_current_user_id),
    firebase_uid: str = Depends(get_current_firebase_uid),
    db_pool: asyncpg.Pool = Depends(get_postgres)
) -> dict:
    """
    Delete a user by its ID.
    Parameters
    ----------
    current_user_id : UUID
        The ID of the user currently logged in, making the request.
    firebase_uid: str
        The firebase_uid of the user, from firebase auth
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    dict
        A message indicating the user was deleted.
    """

    try:
        auth.delete_user(firebase_uid)
    except Exception as e:
        logger.error(f"Error deleting Firebase account for {firebase_uid}: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete account")


    query = "DELETE FROM users WHERE user_id = $1 RETURNING user_id"

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, current_user_id)
            if result is None:
                logger.warning(f"User with ID {current_user_id} not found for deletion")
                raise HTTPException(status_code=404, detail="User not found for deletion")

            return {"message": "User deleted successfully"}                
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"CRITICAL: Firebase account {firebase_uid} deleted but Postgres row "
            f"{current_user_id} deletion failed: {e}"
        )
        raise HTTPException(status_code=500, detail="Internal server error during user deletion")

