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
    distance: Literal['5K', '10K', 'Half Marathon', 'Marathon']
    race_date: date
    goal_time_seconds: Optional[int]
    created_at: datetime
    plan_color: str


class PlanCreate(BaseModel):
    """
    Represents the required fields to create a new plan.
    """
    name: str
    distance: Literal['5K', '10K', 'Half Marathon', 'Marathon']
    race_date: date 
    goal_time_seconds: Optional[int] = None
    plan_color: str = '#808080'

class PlanUpdate(BaseModel):
    name: Optional[str] = None
    distance: Optional[Literal['5K', '10K', 'Half Marathon', 'Marathon']] = None
    race_date: Optional[date] = None
    goal_time_seconds: Optional[int] = None
    plan_color: Optional[str] = None
