from pydantic import BaseModel

from models.ScoutInfo import ScoutInfo


class Data(BaseModel):
    severity: str
    comments: str


class FollowUp(BaseModel):
    event: str
    match: int
    team: int
    scout_info: ScoutInfo
    groupID: str
    data: Data