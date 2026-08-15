from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Literal
from uuid import UUID
from datetime import date, time, datetime


class Activity(BaseModel):
    """
    Represents the activity table in the database.
    """
    activity_id: UUID 
    plan_id: Optional[UUID]
    name: str
    date: date 
    time: Optional[str] 
    type: str
    notes: Optional[str] = Field(None, max_length = 255) # word limit? Is None default
    distance: Optional[int] # double?
    distance_unit: str
    pace: Optional[int]
    pace_tag = Optional[str]
    duration = Optional[str]

class ActivityCreate(BaseModel):
    """
    Represents the required fields to create a new activity.
    """
    name: str
    date: str
    type: str


    # need to include all optional fields?


class ActivityUpdate(BaseModel):
    """
    Represents optional fields to update an existing activity.
    Allows partial updates.
    """
    plan_id: Optional[UUID] = None
    name: Optional[str] = None
    date: Optional[datetime.date] = None
    time: Optional[datetime.time] = None
    type: Optional[str] = None
    notes: Optional[str] = None
    distance: Optional[int] = None
    distance_unit: Optional[str] = None
    pace: Optional[int] = None
    pace_tag: Optional[str] = None
    duration: Optional[str] = None