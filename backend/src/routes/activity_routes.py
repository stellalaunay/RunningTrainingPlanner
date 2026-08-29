from fastapi import HTTPException, Query, Path, Body, APIRouter, Depends, status
from models.activity_models import Activity, ActivityCreate, ActivityUpdate
from database.postgres import get_postgres
from auth.dependencies import get_current_user_id
from auth.authorization import is_owner
from typing import List
import asyncpg
from loguru import logger
from uuid import UUID
from datetime import datetime, date as date_type, time as time_type


activity_router = APIRouter()


# ------------- Create Activity ------------
@activity_router.post("/activities", response_model = Activity, status_code=status.HTTP_201_CREATED,)
async def create_activity(
    activity: ActivityCreate = Body(...),
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Activity:

    """
    Create a new activity.
    Parameters
    ----------
    activity : ActivityCreate
        The activity details to create.
    current_user_id: UUID
        The ID of the user currently logged in, making the request.
    db_pool : asyncpg.Pool
        Database connection pool injected by dependency.
    Returns
    -------
    Activity
        The newly created activity.
    """

    

    query = """
    INSERT INTO activities (plan_id, name, date, time, type, notes, distance, distance_unit, pace, pace_tag, duration, user_id)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
    RETURNING *
    """

    try:
        async with db_pool.acquire() as conn:
            distance_unit = activity.distance_unit
            if distance_unit is None:
                user_row = await conn.fetchrow(
                    "SELECT default_distance_unit FROM users WHERE user_id = $1",
                    current_user_id
                )
                distance_unit = user_row["default_distance_unit"]
            result = await conn.fetchrow(
                query,
                activity.plan_id,
                activity.name,
                activity.date,
                activity.time,
                activity.type,
                activity.notes,
                activity.distance,
                distance_unit,
                activity.pace,
                activity.pace_tag,
                activity.duration,
                current_user_id,
            )

            return Activity(**dict(result))
    except Exception as e:
        logger.error(f"Error during activity creation: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during activity creation")



# ------------- Get All My Activities ------------
@activity_router.get("/activities/me", response_model = List[Activity])
async def get_all_my_activities(
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> List[Activity]:
    """
    Get all actvities for logged in user
    Parameters
    ----------
    current_user_id: UUID
        The ID of the user currently logged in, making the request.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    List[Activity]
        The list of all activities for given user id.
    """


    query = """
        SELECT a.*, p.name as plan_name, p.plan_color
        FROM activities a 
        LEFT JOIN plans p on a.plan_id = p.plan_id
        WHERE a.user_id = $1
    """

    try:
        async with db_pool.acquire() as conn:
            results = await conn.fetch(query, current_user_id)


            return [Activity(**dict(result)) for result in results]
    except Exception as e:
        logger.error(f"Error fetching activities for user ID {current_user_id}: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during activities retrieval")



# ------------- Get Activity ------------
@activity_router.get("/activities/{activity_id}", response_model = Activity)
async def get_activity_by_id(
    activity_id: UUID = Path(...),
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Activity:
    
    """
    Get an activity by its ID.
    Parameters
    ----------
    activity_id : UUID
        The ID of the activity.
    current_user_id: UUID
        The ID of the user currently logged in, making the request.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    Activity
        The activity details for the given ID.
    """

    query = """
        SELECT a.*, p.name as plan_name, p.plan_color
        FROM activities a
        LEFT JOIN plans p on a.plan_id = p.plan_id
        WHERE a.activity_id = $1
    """


    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, activity_id)

            if result is None:
                logger.warning(f"Activity with ID {activity_id} not found")
                raise HTTPException(status_code=404, detail="Activity not found")
            
            if not is_owner(current_user_id, result["user_id"]):
                logger.warning(f"User ID: {current_user_id} not authorized to view activity with id {activity_id}")
                raise HTTPException(status_code=403, detail="Not authorized to view activity")
            
            return Activity(**dict(result))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching activity by ID: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during activity retrieval")

    

# ------------- Edit Activity ------------
@activity_router.put("/activities/{activity_id}", response_model = Activity)
async def update_activity(
    activity_id: UUID = Path(...),
    activity: ActivityUpdate = Body(...),
    current_user_id = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Activity:


    """
    Update an activity by its ID.
    Parameters
    ----------
    activity_id : UUID
        The ID of the activity to update.
    activity : ActivityUpdate
        The fields to update (partial updates allowed).
    current_user_id: UUID
        The ID of the user currently logged in, making the request.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    Activity
        The updated activity details.
    """


    query = """
    UPDATE activities
    SET plan_id = $1, 
        name = COALESCE($2, name),
        date = COALESCE($3, date),
        time = $4,
        type = COALESCE($5, type),
        notes = $6,
        distance = $7,
        distance_unit = $8,
        pace = $9,
        pace_tag = $10,
        duration = $11,
    WHERE activity_id = $13
    returning *
    """

    try:
        async with db_pool.acquire() as conn:

            existing = await conn.fetchrow("SELECT user_id FROM activities WHERE activity_id = $1", activity_id)
            if existing is None:
                logger.warning(f"Activity with ID {activity_id} not found for update")
                raise HTTPException(status_code=404, detail="Activity not found")
            if not is_owner(current_user_id, existing["user_id"]):
                logger.warning(f"User ID: {current_user_id} not authorized to edit activity with id {activity_id}")
                raise HTTPException(status_code=403, detail="Not authorized to edit this activity")

            result = await conn.fetchrow(
                query,
                activity.plan_id,
                activity.name,
                activity.date,
                activity.time,
                activity.type,
                activity.notes,
                activity.distance,
                activity.distance_unit,
                activity.pace,
                activity.pace_tag,
                activity.duration,
                activity_id
            )
            
            return Activity(**dict(result))     
    except HTTPException:
        raise           
    except Exception as e:
        logger.error(f"Error updating activity: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during activity update")
    




# ------------- Delete Activity ------------
@activity_router.delete("/activities/{activity_id}", status_code=status.HTTP_204_NO_CONTENT,)
async def delete_activity(
    activity_id: UUID = Path(...),
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres)
) -> None:
    """
    Delete an activity by its ID.
    Parameters
    ----------
    activity_id : UUID
        The ID of the activity to delete.
    current_user_id: UUID
        The ID of the user currently logged in, making the request.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    None
        Return nothing, function exits.
    """

    query = "DELETE FROM activities WHERE activity_id = $1 RETURNING activity_id"

    try:
        async with db_pool.acquire() as conn:
            existing = await conn.fetchrow("SELECT user_id FROM activities WHERE activity_id = $1", activity_id)
            if existing is None:
                logger.warning(f"Activity with ID {activity_id} not found for deletion")
                raise HTTPException(status_code=404, detail="Activity not found")
            if not is_owner(current_user_id, existing["user_id"]):
                logger.warning(f"User ID: {current_user_id} not authorized to delete activity with id {activity_id}")
                raise HTTPException(status_code=403, detail="Not authorized to delete this activity")
            
            result = await conn.fetchrow(query, activity_id)
            if result is None:
                logger.warning(f"Activity with ID {activity_id} not found for deletion")
                raise HTTPException(status_code = 404, detail = "Activity not found for deletion")
    except HTTPException:
        raise                
    except Exception as e:
        logger.error(f"Error deleting activity: {e}")
        raise HTTPException(status_code = 500, detail = "Internal server error during activity deletion")



# For multi-select delete option, need additional endpoint -> use post method



# ------------- Filter Activities By Week ------------
@activity_router.get("/activities/filter/week", response_model = List[Activity])
async def filter_activities_by_week(
    monday: date_type = Query(...),
    sunday: date_type = Query(...), 
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> List[Activity]:
    """
    Get activities within a specific date range (week).
    Parameters
    ----------
    monday : date
        The starting date for filtering.
    sunday : date
        The ending date for filtering.
    current_user_id: UUID
        The ID of the user currently logged in, making the request.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    List[Activity]
        A list of activiites within the specified date range.
    """

    query = """
    SELECT a.*, p.name as plan_name, p.plan_color
    FROM activities a
    LEFT JOIN plans p on a.plan_id = p.plan_id
    WHERE a.user_id = $1 AND a.date BETWEEN $2 and $3
    """

    try: 
        async with db_pool.acquire() as conn:
            
            results = await conn.fetch(query, current_user_id, monday, sunday)
            return [Activity(**dict(result)) for result in results]
    except Exception as e:
        logger.error(f"Error filtering activities by week: {e}")
        raise HTTPException(status_code=500, detail="Internal sever error during date filtering")