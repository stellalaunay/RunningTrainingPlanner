from uuid import UUID
import asyncpg



def is_owner(current_user_id: UUID, resource_user_id: UUID) -> bool:
    return current_user_id == resource_user_id


async def is_activity_visible(
    activity_row: dict,
    current_user_id: UUID,
    db_pool: asyncpg.Pool,
) -> bool:
    """
    An activity's visibility depends on whether it belongs to a plan:
    - Linked to a plan: inherits the plan's current is_public value (checked live,
      not cached, so it always reflects the plan's latest setting).
    - Not linked to a plan: uses its own is_public column directly.
    Parameters
        ----------
        activity_row : dict
            []
        current_user_id : UUID
            []
        db_pool : asyncpg.Pool, optional
            Database connection pool injected by dependency.
        Returns
        -------
        bool
            []
    """
    if is_owner(current_user_id, activity_row["user_id"]):
        return True
    if activity_row["plan_id"] is not None:
        async with db_pool.acquire() as conn:
            plan_row = await conn.fetchrow(
                "SELECT is_public FROM plans WHERE plan_id = $1", activity_row["plan_id"]
            )
        return plan_row["is_public"]
    return activity_row["is_public"]