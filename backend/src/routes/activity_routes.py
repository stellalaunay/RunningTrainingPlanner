from fastapi import HTTPException, Query, Path, Body, APIRouter, Depends
from models.activity_models import Activity, ActivityCreate, ActivityUpdate
from database.postgres import get_postgres
from typing import List
import asyncpg
from loguru import logger

activity_router = APIRouter()


# need to include user_id in path? or can we get it by some context?


# create activity 
@activity_router.post("/activities", response_model = Activity)
async def create_activity(
    activity: ActivityCreate = Body(...),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Activity:
    """
    Create a new activity.
    Parameters
    ----------
    activity : ActivityCreate
        The activity details to create.
    db_pool : asyncpg.Pool
        Database connection pool injected by dependency.
    Returns
    -------
    Activity
        The newly created activity.
    """

    query = """
    INSERT INTO activities (plan_id, name, date, time, type, notes, distance, distance_unit, pace, pace_tag, duration)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    RETURNING id, plan_id, name, date, time, type, notes, distance, distance_unit, pace, pace_tag, duration
    """

    try:
        async with db_pool.acquire() as conn:
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
                activity.duration
            )

            if result:
                return Activity(**dict(result))
            else:
                logger.error("Failed to create activity")
                raise HTTPException(status_code = 500, detail = "Failed to create activity")
    except Exception as e:
        logger.error(f"Error during activity creation: {e}")
        raise HTTPException(status_code = 500, detail = "Internal server error during activity creation")



# get activity 
@activity_router.get("/activities/{id}", response_model = Activity)
async def get_activity_by_id(
    id: int = Path(..., ge=1),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Activity:
    """
    Get an activity by its ID.
    Parameters
    ----------
    id : int
        The ID of the activity.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    Activity
        The activity details for the given ID.
    """

    query = "SELECT id, name, date, time, type, notes, distance, distance_unit, pace, pace_tag, duration FROM activities WHERE id = $1"

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, id)
            if result:
                return Activity(**dict(result))
            else:
                logger.warning(f"Activity with ID {id} not found")
                raise HTTPException(status_code = 404, detail = "Activity not found")
    except Exception as e:
        logger.error(f"Error fetching activity by ID: {e}")
        raise HTTPException(
            status_code = 500, detail = "Internal server error during activity retrieval"
        )

    

# edit activity
@activity_router.put("/activities/{id}", response_model = Activity)
async def update_activity(
    id: int = Path(..., ge = 1),
    activity: ActivityUpdate = Body(...),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Activity:


    """
    Update an activity by its ID.
    Parameters
    ----------
    id : int
        The ID of the activity to update.
    activity : ActivityUpdate
        The fields to update (partial updates allowed).
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    Activity
        The updated activity details.
    """


    query = """
    UPDATE activities
    SET name = COALESCE($1, name),
        date = COALESCE($2, date),
        time = COALESCE($3, time),
        type = COALESCE($4, type),
        notes = COALESCE($5, notes),
        distance = COALESCE($6, distance),
        distance_unit = COALESCE($7, distance_unit),
        pace = COALESCE($8, pace),
        pace_tag = COALESCE($9, pace_tag),
        duration = COALESCE($10, duration)
    WHERE id = $11
    returning id, name, date, time, type, notes, distance, distance_unit, pace, pace_tag, duration
    """

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
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
                id
            )

            if result:
                return Activity(**dict(result))
            else:
                logger.warning(f"Activity with ID {id} not found for update")
                raise HTTPException(status_code = 404, detail = "Activity not found")
    except Exception as e:
        logger.error(f"Error updating activity: {e}")
        raise HTTPException(status = 500, detail = "Internal server error during activity update")
    




# delete activity
@activity_router.delete("/activities/{id}")
async def delete_activity(
    id: int = Path(..., ge = 1),
    db_pool: asyncpg.Pool = Depends(get_postgres)
) -> dict:
    """
    Delete an activity by its ID.
    Parameters
    ----------
    id : int
        The ID of the activity to delete.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    dict
        A message indicating the activity was deleted.
    """

    query = "DELETE FROM activities WHERE id = $1 RETURNING id"

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, id)
            if result:
                return {"message": "Activity deleted successfully"}
            else:
                logger.warning(f"Activity with ID {id} not found for deletion")
                raise HTTPException(status_code = 404, detail = "Activity not found for deletion")
    except Exception as e:
        logger.error(f"Error deleting activity: {e}")
        raise HTTPException(status_code = 500, detail = "Internal server error during activity deletion")



# For multi-select delete option, need additional endpoint? Or call delete_activity several times?



# get actvities
@activity_router.get("/activities/filter/price", response_model = List[Activity])
async def filter_activities_by_week(
    monday: str = Query(...),
    sunday: str = Query(...), 
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> List[Activity]:
    """
    Get activities within a specific date range (week).
    Parameters
    ----------
    monday : str
        The starting date for filtering.
    sunday : str
        The ending date for filtering.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    List[Activity]
        A list of activiites within the specified date range.
    """

    query = """"
    SELECT id, plan_id, name, date, time, type, notes, distance, distance_unit, pace, pace_tag, duration
    FROM activities
    WHERE date BETWEEN $1 and $2
    """

    try: 
        async with db_pool.acquire() as conn:
            results = await conn.fetch(query, monday, sunday)
            return [Activity(**dict(result)) for result in results]
    except Exception as e:
        logger.error(f"Error filtering activities by week: {e}")
        raise HTTPException(status_code = 500, detail = "Internal sever error during date filtering")
