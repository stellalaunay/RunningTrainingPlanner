from fastapi import HTTPException, Query, Path, Body, APIRouter, Depends, status
from models.plan_models import Plan, PlanCreate, PlanUpdate
from database.postgres import get_postgres
from auth.dependencies import get_current_user_id, get_current_firebase_uid
from auth.authorization import is_owner
from typing import List
import asyncpg
from loguru import logger
from uuid import UUID

plan_router = APIRouter()


# ------------- Create Plan ------------

@plan_router.post("/plans", response_model = Plan, status_code=status.HTTP_201_CREATED,)
async def create_plan(
    plan: PlanCreate = Body(...),
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres), 
) -> Plan:

    
    """
    Create a new plan.
    Parameters
    ----------
    plan : PlanCreate
        The plan details to create.
    current_user_id: UUID
        The ID of the user currently logged in.
    db_pool : asyncpg.Pool
        Database connection pool injected by dependency.
    Returns
    -------
    Plan
        The newly created plan.
    """

    query = """
        INSERT INTO plans (user_id, name, distance, race_date, goal_time_seconds, is_public, plan_color)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
    """

    try:
        async with db_pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                current_user_id,
                plan.name,
                plan.distance,
                plan.race_date,
                plan.goal_time_seconds,
                plan.is_public,
                plan.plan_color
            )

            return Plan(**dict(result))
    
    except Exception as e:
        logger.error(f"Error during plan creation: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during plan creation")



# ------------- Get My Plans ------------
@plan_router.get("/plans/me", response_model = List[Plan])
async def get_all_my_plans(
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> List[Plan]:
    """
    Get a list of all plans for logged in user.

    Parameters
    ----------
    current_user_id: UUID
        The ID of the user currently logged in.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    List[Plan]
        A list of all plans.
    """

    query = """
        SELECT *
        FROM plans
        WHERE user_id = $1
    """

    try:
        async with db_pool.acquire() as conn:
            results = await conn.fetch(
            query,
            current_user_id
            )

            return [Plan(**dict(result)) for result in results]

    except Exception as e:
        logger.error(f"Error fetching plans: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve plans")


# ------------- Get Plan ------------
@plan_router.get("/plans/{plan_id}", response_model = Plan)
async def get_plan_by_id(
    plan_id: UUID = Path(...),
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Plan:
    
    """
    Get a plan by its ID.
    Parameters
    ----------
    plan_id : UUID
        The ID of the plan.
    current_user_id: UUID
        The ID of the user currently logged in.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    Plan
        The plan details for the given ID.
    """

    query = "SELECT * FROM plans WHERE plan_id = $1"


    try:
        async with db_pool.acquire() as conn:

            result = await conn.fetchrow(query, plan_id)

            if result is None:
                logger.warning(f"Plan with ID {plan_id} not found")
                raise HTTPException(status_code=404, detail="Plan not found")
            
            if not result["is_public"] and result["user_id"] != current_user_id:
                logger.warning(f"User ID: {current_user_id} not authorized to view plan with id {plan_id}")
                raise HTTPException(status_code=403, detail="Not authorized to view plan")
                
            return Plan(**dict(result))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching plan by ID: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during plan retrieval")

    


# ------------- Edit Plan ------------
@plan_router.put("/plans/{plan_id}", response_model = Plan)
async def update_plan(
    plan_id: UUID = Path(...),
    current_user_id: UUID = Depends(get_current_user_id),
    plan: PlanUpdate = Body(...),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> Plan:


    """
    Update a plan by its ID.
    Parameters
    ----------
    plan_id : UUID
        The ID of the plan to update.
    current_user_id: UUID
        The ID of the current user logged in.
    plan : PlanUpdate
        The fields to update (partial updates allowed).
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    Plan
        The updated plan details.
    """

    user_query = "SELECT user_id FROM plans WHERE plan_id = $1"

    update_query = """
        UPDATE plans
        SET name = COALESCE($1, name),
            distance = COALESCE($2, distance),
            race_date = COALESCE($3, race_date),
            goal_time_seconds = COALESCE($4, goal_time_seconds),
            is_public = COALESCE($5, is_public) ,
            plan_color = COALESCE($6, plan_color)
        WHERE plan_id = $7
        returning *
    """

    try:
        async with db_pool.acquire() as conn:

            existing = await conn.fetchrow(user_query, plan_id)

            if existing is None:
                raise HTTPException(status_code=404, detail="Plan not found")
            if not is_owner(current_user_id, existing["user_id"]):
                raise HTTPException(status_code=403, detail="Not authorized to edit this plan")

            result = await conn.fetchrow(
                update_query,
                plan.name, plan.distance, plan.race_date, plan.goal_time_seconds, plan.is_public, plan.plan_color, plan_id
            )

            return Plan(**dict(result))
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating plan: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during plan update")
    

# ------------- Delete Plan ------------
@plan_router.delete("/plans/{plan_id}", status_code=status.HTTP_204_NO_CONTENT,)
async def delete_plan(
    plan_id: UUID = Path(...),
    current_user_id: UUID = Depends(get_current_user_id),
    db_pool: asyncpg.Pool = Depends(get_postgres)
) -> None:
    """
    Delete a plan by its ID.
    Parameters
    ----------
    plan_id : UUID
        The ID of the plan to delete.
    current_user_id: UUID
        The ID of the user currently logged in, making the request.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    None
        Return nothing, function exits.
    """

    query = "DELETE FROM plans WHERE plan_id = $1 RETURNING plan_id"
    try:
        async with db_pool.acquire() as conn:
            existing = await conn.fetchrow("SELECT user_id FROM plans WHERE plan_id = $1", plan_id)
            if existing is None:
                logger.warning(f"Plan with ID {plan_id} not found for deletion")
                raise HTTPException(status_code=404, detail="Plan not found")
            if not is_owner(current_user_id, existing["user_id"]):
                logger.warning(f"User ID: {current_user_id} not authorized to delete plan with id {plan_id}")
                raise HTTPException(status_code=403, detail="Not authorized to delete this plan")
                
            result = await conn.fetchrow(query, plan_id)

            if result is None:
                logger.warning(f"Plan with ID {plan_id} not found for deletion")
                raise HTTPException(status_code=404, detail="Plan not found for deletion")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting plan: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during plan deletion")


# ------------- Get Plans By User ------------
@plan_router.get("/plans/user/{resource_user_id}", response_model = List[Plan])
async def get_all_plans_by_user_id(
    resource_user_id: UUID = Path(...),
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> List[Plan]:
    """
    Get a list of all plans for a specific user (view).

    Parameters
    ----------
    resource_user_id: UUID
        The ID of the user being queried.
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    List[Plan]
        A list of all plans.
    """

    query = """
        SELECT *
        FROM plans
        WHERE user_id = $1 AND is_public = TRUE
    """

    try:
        async with db_pool.acquire() as conn:
            results = await conn.fetch(
            query,
            resource_user_id
            )

            return [Plan(**dict(result)) for result in results]
        
    except Exception as e:
        logger.error(f"Error fetching plans: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve plans")





# ------------- Get All Plans ------------
@plan_router.get("/plans/", response_model = List[Plan])
async def get_all_plans(
    db_pool: asyncpg.Pool = Depends(get_postgres),
) -> List[Plan]:
    """
    Get a list of all public plans.

    Parameters
    ----------
    db_pool : asyncpg.Pool, optional
        Database connection pool injected by dependency.
    Returns
    -------
    List[Plan]
        A list of all plans.
    """

    query = """
        SELECT * 
        FROM plans 
        WHERE is_public = TRUE
    """

    try: 
        async with db_pool.acquire() as conn:
            results = await conn.fetch(query)
            return [Plan(**dict(result)) for result in results]
    except Exception as e:
        logger.error(f"Error fetching plans: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve plans")
