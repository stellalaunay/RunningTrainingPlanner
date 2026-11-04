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
    name: str # -> defaults to race_event_name, can change
    distance: str
    race_date: date
    goal_time_seconds: Optional[int] # if None, goal is just to finish
    created_at: datetime
    plan_color: str
    race_event_name: Optional[str] = None
    last_evaluated_at: Optional[datetime] = None
    last_evaluation_message: Optional[str] = None
    strava_linked_at_generation: bool


class PlanCreate(BaseModel):
    """
    Represents the required fields to create a new plan.
    """
    name: str 
    distance: str
    race_date: date 
    goal_time_seconds: Optional[int] = None
    plan_color: str = '#808080'
    race_event_name: Optional[str] = None
    last_evaluated_at: Optional[datetime] = None
    last_evaluation_message: Optional[str] = None
    strava_linked_at_generation: bool = False


class PlanUpdate(BaseModel):
    name: Optional[str] = None
    distance: Optional[str] = None
    race_date: Optional[date] = None
    goal_time_seconds: Optional[int] = None
    plan_color: Optional[str] = None
    race_event_name: Optional[str] = None
    last_evaluated_at: Optional[datetime] = None
    last_evaluation_message: Optional[str] = None

