"""客户端可编辑名称的统一约束；长度按 Unicode 码点计算（与 Python len 一致）。"""
from typing import Annotated

from pydantic import StringConstraints

MEETING_TITLE_MAX = 50
USER_NAME_MAX = 32
ROOM_NAME_MAX = 20

MeetingTitle = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=MEETING_TITLE_MAX)]
MeetingCreateTitle = Annotated[str, StringConstraints(strip_whitespace=True, max_length=MEETING_TITLE_MAX)]
UserName = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=USER_NAME_MAX)]
