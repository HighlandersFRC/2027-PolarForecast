from pydantic import BaseModel


class JoinCodeRequest(BaseModel):
    username: str
    join_code: str

class ApproveJoinRequest(BaseModel):
    request_id: str

class JoinGroupRequest(BaseModel):
    username: str
    group_id: str

class AddGroupEventRequest(BaseModel):
    group_id: str
    event_code: str

class RemoveGroupEventRequest(BaseModel):
    group_id: str
    event_code: str

class GroupCreateRequest(BaseModel):
    name: str
    username: str | None = None