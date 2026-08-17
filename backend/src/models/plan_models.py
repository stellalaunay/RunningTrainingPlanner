from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Literal
from uuid import UUID
from datetime import datetime, date, time


class Plan(BaseModel):
    """
    Represents the plan table in the database.
    """
    plan_id: UUID 
    user_id: UUID
    name: str
    distance: float
    race_date: date
    goal_time_seconds: Optional[int]
    created_at: datetime
    is_public: bool


class PlanCreate(BaseModel):
    """
    Represents the required fields to create a new plan.
    """
    name: str
    distance: float 
    race_date: date 
    goal_time_seconds: Optional[int] = None
    is_public: bool = False

class PlanUpdate(BaseModel):
    name: Optional[str] = None
    distance: Optional[float] = None
    race_date: Optional[date] = None
    goal_time_seconds: Optional[int] = None
    is_public: Optional[bool] = None