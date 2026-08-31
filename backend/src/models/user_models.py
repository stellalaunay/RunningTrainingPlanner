from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Literal
from uuid import UUID
from datetime import date, time, datetime


# move paces into plan?


class User(BaseModel):
    """
    Represents the user table in the database.
    """
    user_id: UUID 
    first_name: str
    last_name: str
    profile_photo_url: Optional[str] 
    default_distance_unit: Optional[Literal["km", "mi"]]
    easy_pace: Optional[int] 
    long_run_pace: Optional[int]
    speed_pace: Optional[int]
    created_at: datetime
    firebase_uid: str
    sports: Optional[list[str]]
    sports_frequency: Optional[dict[str, int]]
    strava_athlete_id: Optional[int]
    strava_access_token: Optional[str]
    strava_refresh_token: Optional[str]
    strava_token_expires_at: Optional[datetime]

class UserResponse(BaseModel):
    """
    Represents the user response to the client.
    """
    user_id: UUID 
    first_name: str
    last_name: str
    profile_photo_url: Optional[str] 
    default_distance_unit: Optional[Literal["km", "mi"]]
    easy_pace: Optional[int] 
    long_run_pace: Optional[int]
    speed_pace: Optional[int]
    created_at: datetime
    firebase_uid: str
    sports: Optional[list[str]]
    sports_frequency: Optional[dict[str, int]]
    strava_connected: bool



class UserCreate(BaseModel):
    """
    Represents the required fields to create a new user
    """
    first_name: str
    last_name: str
    profile_photo_url: Optional[str] = None
    default_distance_unit: Optional[Literal["km", "mi"]] = None
    easy_pace: Optional[int] = None
    long_run_pace: Optional[int] = None
    speed_pace: Optional[int] = None
    sports: Optional[list[str]] = None
    sports_frequency: Optional[dict[str, int]] = None

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    profile_photo_url: Optional[str] = None
    default_distance_unit: Optional[Literal["km", "mi"]] = None
    easy_pace: Optional[int] = None
    long_run_pace: Optional[int] = None
    speed_pace: Optional[int] = None
    sports: Optional[list[str]] = None
    sports_frequency: Optional[dict[str, int]] = None

