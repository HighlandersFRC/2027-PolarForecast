from pydantic import BaseModel, Field


class PicklistTeam(BaseModel):
    team: int = Field(gt=0)
    tier: str = Field(default="", max_length=24)
    note: str = Field(default="", max_length=500)


class PicklistUpdate(BaseModel):
    username: str = Field(min_length=1)
    teams: list[PicklistTeam] = Field(default_factory=list, max_length=100)
