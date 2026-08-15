from fastapi import HTTPException, Query, Path, Body, APIRouter, Depends
from models.user_models import User, UserCreate, UserUpdate
from database.postgres import get_postgres
from typing import List
import asyncpg
from loguru import logger

user_router = APIRouter()




# create user -> on create account
@user_router.post("/users", response_model = User)
async def create_user(
    user: UserCreate = Body(...),
    db_pool: asyncpg.Pool = Depends(get_postgres), # what does this mean
) -> User:
    """
    Create a new user.
    Parameters
    ----------
    user : UserCreate
        The user details to create.
    db_pool : asyncpg.Pool
        Database connection pool injected by dependency.
    Returns
    -------
    User
        The newly created user.
    """
    # how are optional fields handled for insertion?
    query = """
    INSERT INTO users (first_name, last_name, profile_photo_url, default_distance_unit, easy_pace, long_run_pace, speed_pace)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING id, first_name, last_name, profile_photo_url, default_distance_unit, easy_pace, long_run_pace, speed_pace
    """

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                user.first_name,
                user.last_name,
                user.profile_photo_url, # how are optional fields handled here
                user.default_distance_units,
                user.easy_pace,
                user.long_run_pace,
                user.speed_pace
            )

            if result:
                return User(**dict(result))
            else:
                logger.error("Failed to create user")
                raise HTTPException(status_code = 500, detail = "Failed to create user")
    except Exception as e:
        logger.error(f"Error during user creation: {e}")
        raise HTTPException(status_code = 500, detail = "Internal server error during user creation")



# get user (for profile)
@user_router.get("/users/{id}", response_model = User)
async def get_user_by_id(
    id: int = Path(..., ge=1),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> User:
    """
    Get a user by its ID.
    Parameters
    ----------
    id : int
        The ID of the user.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    User
        The user details for the given ID.
    """

    query = "SELECT id, first_name, last_name, profile_photo_url, default_distance_unit, easy_pace, long_run_pace, speed_pace FROM users WHERE id = $1"

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, id)
            if result:
                return User(**dict(result))
            else:
                logger.warning(f"User with ID {id} not found")
                raise HTTPException(status_code = 404, detail = "User not found")
    except Exception as e:
        logger.error(f"Error fetching user by ID: {e}")
        raise HTTPException(
            status_code = 500, detail = "Internal server error during user retrieval"
        )

    
# add photo (profile photo) -> same thing as edit profile?


# edit profile
@user_router.put("/users/{id}", response_model = User)
async def update_user(
    id: int = Path(..., ge = 1),
    user: UserUpdate = Body(...),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> User:


    """
    Update a user by its ID.
    Parameters
    ----------
    id : int
        The ID of the user to update.
    user : UserUpdate
        The fields to update (partial updates allowed).
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
        default_distance_units = COALESCE($4, default_distance_units),
        easy_pace = COALESCE($5, easy_pace),
        long_run_pace = COALESCE($6, long_run_pace),
        speed_pace = COALESCE($7, speed_pace)
    WHERE id = $8
    returning id, first_name, last_name, profile_photo_url, default_distance_units, easy_pace, long_run_pace, speed_pace
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
                id
            )

            if result:
                return User(**dict(result))
            else:
                logger.warning(f"User with ID {id} not found for update")
                raise HTTPException(status_code = 404, detail = "User not found")
    except Exception as e:
        logger.error(f"Error updating user: {e}")
        raise HTTPException(status = 500, detail = "Internal server error during user update")
    



# delete user -> need to implement cascade delete?
@user_router.delete("/users/{id}")
async def delete_user(
    id: int = Path(..., ge = 1),
    db_pool: asyncpg.Pool = Depends(get_postgres)
) -> dict:
    """
    Delete a user by its ID.
    Parameters
    ----------
    id : int
        The ID of the user to delete.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    dict
        A message indicating the user was deleted.
    """

    query = "DELETE FROM users WHERE id = $1 RETURNING id"

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, id)
            if result:
                return {"message": "User deleted successfully"}
            else:
                logger.warning(f"User with ID {id} not found for deletion")
                raise HTTPException(status_code = 404, detail = "User not found for deletion")
    except Exception as e:
        logger.error(f"Error deleting product: {e}")
        raise HTTPException(status_code = 500, detail = "Internal server error during user deletion")


# need to handle users relogging in 
