

from pydantic import BaseModel


class ScoutInfo(BaseModel):
    userId: str
    firstName: str
    username: str
    team: str