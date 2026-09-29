from typing import Literal

from pydantic import BaseModel, Field


PicklistSort = Literal["manual", "rank", "opr", "defense", "team"]


class PicklistTeam(BaseModel):
    team: int = Field(gt=0)
    tier: str = Field(default="", max_length=24)
    note: str = Field(default="", max_length=500)


class PicklistUpdate(BaseModel):
    username: str = Field(min_length=1)
    name: str = Field(default="Main Picklist", min_length=1, max_length=80)
    sort_by: PicklistSort = "manual"
    teams: list[PicklistTeam] = Field(default_factory=list, max_length=100)


class PicklistCreate(BaseModel):
    username: str = Field(min_length=1)
    name: str = Field(min_length=1, max_length=80)
    sort_by: PicklistSort = "rank"
