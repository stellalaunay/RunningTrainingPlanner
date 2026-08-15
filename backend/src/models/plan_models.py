from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Literal
from uuid import UUID
from datetime import date, time, datetime


class Plan(BaseModel):
    """
    Represents the plan table in the database.
    """
    plan_id: UUID 
    user_id: UUID
    name: str
    distance: float
    race_date: datetime.date
    goal_time_seconds: Optional[int]
    created_at = datetime


class PlanCreate(BaseModel):
    """
    Represents the required fields to create a new plan.
    """
    user_id: UUID # how is this handled? automatic?
    name: str
    distance: float 
    race_date: datetime.date 
    goal_time_seconds: Optional[int] = None

class PlanUpdate(BaseModel):
    name: Optional[str] = None
    distance: Optional[float] = None
    race_date: Optional[datetime.date] = None
    goal_time_seconds: Optional[int] = None