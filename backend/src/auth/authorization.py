from uuid import UUID
import asyncpg



def is_owner(current_user_id: UUID, resource_user_id: UUID) -> bool:
    return current_user_id == resource_user_id
