from datetime import date
from typing import Literal

from pydantic import BaseModel, Field, ConfigDict, model_validator


class ScheduleGroup(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    id: str = Field(min_length=1, max_length=80)
    name: str = Field(min_length=1, max_length=100)
    roster_group_id: str = Field(min_length=1, max_length=200)
    members: list[str] = Field(min_length=1, max_length=200)
    lead: str = Field(min_length=1, max_length=200)

    @model_validator(mode="after")
    def validate_lead(self):
        if self.lead not in self.members:
            raise ValueError("The lead must be a member of this schedule group")
        if len(set(self.members)) != len(self.members):
            raise ValueError("A person can only appear once in a schedule group")
        return self


class ScheduleRow(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    id: str = Field(min_length=1, max_length=80)
    date: date
    time: str = Field(pattern=r"^([01]\d|2[0-3]):[0-5]\d$")
    activities: dict[str, str] = Field(default_factory=dict)


class ScheduleUpdate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    roster_group_id: str = Field(min_length=1, max_length=200)
    revision: int = Field(default=0, ge=0)
    groups: list[ScheduleGroup] = Field(default_factory=list, max_length=100)
    rows: list[ScheduleRow] = Field(default_factory=list, max_length=2000)

    @model_validator(mode="after")
    def validate_schedule(self):
        ids = [group.id for group in self.groups]
        names = [group.name.casefold() for group in self.groups]
        members = [member for group in self.groups for member in group.members]
        if len(set(ids)) != len(ids) or len(set(names)) != len(names):
            raise ValueError("Schedule group names and IDs must be unique")
        if len(set(members)) != len(members):
            raise ValueError("Assign each person to only one schedule group")
        if len({row.id for row in self.rows}) != len(self.rows):
            raise ValueError("Schedule row IDs must be unique")
        if len({(row.date, row.time) for row in self.rows}) != len(self.rows):
            raise ValueError("Use one row per date and time")
        for row in self.rows:
            if set(row.activities) - set(ids):
                raise ValueError("Activities must reference an existing schedule group")
            if any(len(activity) > 500 for activity in row.activities.values()):
                raise ValueError("Activities must be 500 characters or fewer")
        return self


class AttendanceUpdate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    roster_group_id: str = Field(min_length=1, max_length=200)
    revision: int = Field(ge=1)
    row_id: str = Field(min_length=1, max_length=80)
    group_id: str = Field(min_length=1, max_length=80)
    student: str = Field(min_length=1, max_length=200)
    status: Literal["tardy", "extreme_tardy", "absent"] | None
