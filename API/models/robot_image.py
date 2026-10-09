from pydantic import BaseModel, Field

from models.scout_info import ScoutInfo


class RobotImageUpload(BaseModel):
    event: str = Field(min_length=1, max_length=64)
    team: int = Field(gt=0)
    groupId: str = Field(min_length=1, max_length=128)
    scoutInfo: ScoutInfo
    content_type: str = Field(min_length=1, max_length=64)
    image_base64: str = Field(min_length=1, max_length=12_000_000)
    capture_source: str = Field(default="camera", max_length=32)
