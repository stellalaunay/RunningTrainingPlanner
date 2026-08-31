from pydantic import BaseModel, Field, ConfigDict, field_serializer
from typing import Optional, Literal
from uuid import UUID
from datetime import datetime, date as date_type, time as time_type

# name: str -> required, cannot be null
# name: Optional[str] -> required, can be null
# name: Optional[str] = None -> not required, defaults to null if not given


class Activity(BaseModel):
    """
    Represents the activity table in the database.
    """
    activity_id: UUID 
    plan_id: Optional[UUID]
    name: str
    date: date_type 
    time: Optional[time_type] 
    type: Literal["Run", "Strength Training", "Walk", "Rock Climb", "Other"]
    notes: Optional[str]
    distance: Optional[float] 
    distance_unit: Optional[Literal["km", "mi"]]
    pace: Optional[int]
    run_type: Optional[str]
    duration: Optional[int]
    created_at: datetime
    user_id: UUID
    plan_name: Optional[str] = None
    plan_color: Optional[str] = None
    user_edited: bool

    @field_serializer('time')
    def serialize_time(self, value: time_type | None) -> str | None:
        if value is None:
            return None
        return value.strftime('%H:%M')

class ActivityCreate(BaseModel):
    """
    Represents the required fields to create a new activity.
    """
    plan_id: Optional[UUID] = None
    name: str
    date: date_type
    time: Optional[time_type] = None
    type: Literal["Run", "Strength Training", "Walk", "Rock Climb", "Other"]
    notes: Optional[str] = None
    distance: Optional[float] = None
    distance_unit: Optional[Literal["km", "mi"]] = None
    pace: Optional[int] = None
    run_type: Optional[str] = None
    duration: Optional[int] = None
    user_edited: bool = False



class ActivityUpdate(BaseModel):
    """
    Represents optional fields to update an existing activity.
    Allows partial updates.
    """
    plan_id: Optional[UUID] = None
    name: Optional[str] = None
    date: Optional[date_type] = None
    time: Optional[time_type] = None
    type: Optional[Literal["Run", "Strength Training", "Walk", "Rock Climb", "Other"]] = None
    notes: Optional[str] = None
    distance: Optional[float] = None
    distance_unit: Optional[Literal["km", "mi"]] = None
    pace: Optional[int] = None
    run_type: Optional[str] = None
    duration: Optional[int] = None
    user_edited: Optional[bool] = None


