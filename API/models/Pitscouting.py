from pydantic import BaseModel, Field

from models.ScoutInfo import ScoutInfo

class PitAutoRoutine(BaseModel):
    name: str
    path: list[str] = Field(default_factory=list)


class AutoPathPit(BaseModel):
    auto_paths: list[PitAutoRoutine] = Field(default_factory=list)


class Auto(BaseModel):
    autos: AutoPathPit

class Data(BaseModel):
    trench: bool
    bump: bool
    shooter_type: str
    climb: str
    bps: float

    # DO NOT TOUCH THIS IS FOR VALIDATION FOR DATA INPUT
    autos: Auto
    driver_events: int
    favorite_robot_part: str
    drive_train: str
    comments: str


class Pitscouting(BaseModel):
    event: str
    team: int
    scoutInfo: ScoutInfo
    data: Data
    groupId: str