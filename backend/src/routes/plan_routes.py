from fastapi import HTTPException, Query, Path, Body, APIRouter, Depends
from models.plan_models import Plan, PlanCreate, PlanUpdate
from database.postgres import get_postgres
from typing import List
import asyncpg
from loguru import logger

plan_router = APIRouter()


# need to include user_id in paths?


# create plan

@plan_router.post("/plans", response_model = Plan)
async def create_plan(
    plan: PlanCreate = Body(...),
    db_pool: asyncpg.Pool = Depends(get_postgres), 
) -> Plan:
    """
    Create a new plan.
    Parameters
    ----------
    plan : PlanCreate
        The plan details to create.
    db_pool : asyncpg.Pool
        Database connection pool injected by dependency.
    Returns
    -------
    Plan
        The newly created plan.
    """
    query = """
    INSERT INTO plans (user_id, name, distance, race_date, goal_time_seconds)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id, user_id, name, distance, race_date, goal_time_seconds
    """

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                plan.user_id,
                plan.name,
                plan.distance,
                plan.race_date,
                plan.goal_time_seconds,
            )

            if result:
                return Plan(**dict(result))
            else:
                logger.error("Failed to create plan")
                raise HTTPException(status_code = 500, detail = "Failed to create plan")
    except Exception as e:
        logger.error(f"Error during plan creation: {e}")
        raise HTTPException(status_code = 500, detail = "Internal server error during plan creation")



# get plan
@plan_router.get("/plans/{id}", response_model = Plan)
async def get_plan_by_id(
    id: int = Path(..., ge=1),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Plan:
    """
    Get a plan by its ID.
    Parameters
    ----------
    id : int
        The ID of the plan.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    Plan
        The plan details for the given ID.
    """

    query = "SELECT id, user_id, name, distance, race_date, goal_time_seconds FROM plans WHERE id = $1"

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, id)
            if result:
                return Plan(**dict(result))
            else:
                logger.warning(f"Plan with ID {id} not found")
                raise HTTPException(status_code = 404, detail = "Plan not found")
    except Exception as e:
        logger.error(f"Error fetching plan by ID: {e}")
        raise HTTPException(
            status_code = 500, detail = "Internal server error during plan retrieval"
        )

    


# edit plan -> need to disallow changing user_id
@plan_router.put("/plans/{id}", response_model = Plan)
async def update_user(
    id: int = Path(..., ge = 1),
    plan: PlanUpdate = Body(...),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Plan:


    """
    Update a plan by its ID.
    Parameters
    ----------
    id : int
        The ID of the plan to update.
    plan : PlanUpdate
        The fields to update (partial updates allowed).
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    Plan
        The updated plan details.
    """

    # need to return user_id if user cannot change it?
    query = """
    UPDATE plans
    SET name = COALESCE($1, name),
        distance = COALESCE($2, distance),
        race_date = COALESCE($3, race_date),
        goal_time_seconds = COALESCE($4, goal_time_seconds),     
    WHERE id = $5
    returning id, name, distance, race_date, goal_time_seconds
    """

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                plan.name,
                plan.distance,
                plan.race_date,
                plan.goal_time_seconds,
                id
            )

            if result:
                return Plan(**dict(result))
            else:
                logger.warning(f"Plan with ID {id} not found for update")
                raise HTTPException(status_code = 404, detail = "Plan not found")
    except Exception as e:
        logger.error(f"Error updating plan: {e}")
        raise HTTPException(status = 500, detail = "Internal server error during plan update")
    

# delete plan -> need to implement cascade delete?
@plan_router.delete("/plans/{id}")
async def delete_plan(
    id: int = Path(..., ge = 1),
    db_pool: asyncpg.Pool = Depends(get_postgres)
) -> dict:
    """
    Delete a plan by its ID.
    Parameters
    ----------
    id : int
        The ID of the plan to delete.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    dict
        A message indicating the plan was deleted.
    """

    query = "DELETE FROM plans WHERE id = $1 RETURNING id"

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(query, id)
            if result:
                return {"message": "Plan deleted successfully"}
            else:
                logger.warning(f"Plan with ID {id} not found for deletion")
                raise HTTPException(status_code = 404, detail = "Plan not found for deletion")
    except Exception as e:
        logger.error(f"Error deleting plan: {e}")
        raise HTTPException(status_code = 500, detail = "Internal server error during plan deletion")


# get plans
@activity_router.get("/plans/", response_model = List[Plan])
async def get_all_plans(
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> List[Plan]:
    """
    Get a list of all plans.

    Parameters
    ----------
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    List[Plan]
        A list of all plans.
    """

    query = "SELECT id, user_id, name, distance, race_date, goal_time_seconds FROM plans"

    try: 
        async with db_pool.acquire() as conn:
            results = await conn.fetch(query)
            return [Plan(**dict(result)) for result in results]
    except Exception as e:
        logger.error(f"Error fetching plans: {e}")
        raise HTTPException(status_code = 500, detail = "Failed to retrieve plans")
