from pydantic import BaseModel, Field

from models.scout_info import ScoutInfo

class AutoScouting(BaseModel):
    # 300 is already an extremely generous ceiling for the autonomous
    # period. Rejecting anything above it keeps accidental long-presses and
    # period mix-ups out of the shared statistics.
    fuel_scored: int = Field(ge=0, le=300)

class TeleopScouting(BaseModel):
    fuel_scored: int = Field(ge=0, le=1000)

class AutoPath(BaseModel):
    path: list[str]

class Misc(BaseModel):
    died: bool
    defense: bool
    comments:str

class Data(BaseModel):
    autoPath: AutoPath
    autoScouting: AutoScouting
    teleopScouting: TeleopScouting
    misc: Misc

class MatchScouting(BaseModel):
    event: str
    match: str
    team: int
    scoutInfo: ScoutInfo
    data: Data
    groupId: str

