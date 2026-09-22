from pydantic import BaseModel

from models.scout_info import ScoutInfo

class AutoScouting(BaseModel):
    fuel_scored: int

class TeleopScouting(BaseModel):
    fuel_scored: int

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

