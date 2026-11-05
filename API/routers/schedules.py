from fastapi import APIRouter, Depends, HTTPException
from pymongo.errors import DuplicateKeyError

from models.event_schedule import AttendanceUpdate, ScheduleUpdate


def create_schedule_router(collection, is_member, get_role, authenticated_user):
    router = APIRouter()

    def authorize(group_id, user_id, *, edit=False):
        role = get_role(group_id, user_id)
        if role not in {"member", "admin", "owner"}:
            raise HTTPException(403, "You must be a current member of this group")
        can_edit = role in {"admin", "owner"}
        if edit and not can_edit:
            raise HTTPException(
                403, "Only group admins and owners can edit the scouting schedule",
            )
        return can_edit

    def schedule_response(document, roster_group_id, can_edit):
        response = {name: document[name] for name in ("groups", "rows", "revision")}
        response["can_edit"] = can_edit
        if can_edit:
            response["attendance"] = [
                {key: mark[key] for key in ("row_id", "group_id", "student", "status")}
                for mark in document.get("attendance", [])
                if mark["roster_group_id"] == roster_group_id
            ]
        return response

    def conflict():
        return HTTPException(409, "Schedule changed. Refresh before editing again.")

    def replace_schedule(document, revision):
        result = collection.replace_one(
            {"_id": document["_id"], "revision": revision}, document,
        )
        if result.matched_count == 0:
            raise conflict()

    @router.get("/events/{event}/schedule", tags=["groups"])
    def get_schedule(
        event: str, roster_group_id: str, user_id: str = Depends(authenticated_user),
    ):
        can_edit = authorize(roster_group_id, user_id)
        document = collection.find_one({"_id": event})
        if document is None:
            document = {"groups": [], "rows": [], "revision": 0}
        return schedule_response(document, roster_group_id, can_edit)

    @router.put("/events/{event}/schedule", tags=["groups"])
    def save_schedule(
        event: str, update: ScheduleUpdate, user_id: str = Depends(authenticated_user),
    ):
        authorize(update.roster_group_id, user_id, edit=True)
        current = None
        if update.revision:
            current = collection.find_one({"_id": event, "revision": update.revision})
            if current is None:
                raise conflict()
        previous_rosters = {
            group["id"]: group["roster_group_id"]
            for group in current["groups"]
        } if current else {}
        for group in update.groups:
            if group.roster_group_id != previous_rosters.get(group.id, update.roster_group_id):
                raise HTTPException(403, "Schedule groups must stay with their assigned roster")
            for username in group.members:
                if not is_member(group.roster_group_id, username):
                    raise HTTPException(400, f"{username} is no longer a member of the assigned roster")
        document = update.model_dump(mode="json", exclude={"roster_group_id"})
        document["rows"].sort(key=lambda row: (row["date"], row["time"]))
        document["revision"] += 1
        document["_id"] = event
        if current is None:
            try:
                collection.insert_one(document)
            except DuplicateKeyError:
                raise conflict()
        else:
            groups = {group.id: group for group in update.groups}
            rows = {row.id: row for row in update.rows}
            document["attendance"] = [
                mark for mark in current.get("attendance", [])
                if (group := groups.get(mark["group_id"])) is not None
                and (row := rows.get(mark["row_id"])) is not None
                and mark["roster_group_id"] == group.roster_group_id
                and mark["student"] in group.members
                and row.activities.get(group.id, "").strip()
            ]
            replace_schedule(document, update.revision)
        return schedule_response(document, update.roster_group_id, True)

    @router.patch("/events/{event}/schedule/attendance", tags=["groups"])
    def save_attendance(
        event: str, update: AttendanceUpdate, user_id: str = Depends(authenticated_user),
    ):
        authorize(update.roster_group_id, user_id, edit=True)
        document = collection.find_one({"_id": event, "revision": update.revision})
        if document is None:
            raise conflict()

        group = next((group for group in document["groups"] if group["id"] == update.group_id), None)
        if group is None or group["roster_group_id"] != update.roster_group_id:
            raise HTTPException(403, "Attendance is private to the assigned roster")
        row = next((row for row in document["rows"] if row["id"] == update.row_id), None)
        if (
            row is None
            or not row["activities"].get(update.group_id, "").strip()
            or update.student not in group["members"]
        ):
            raise HTTPException(400, "Choose a student assigned to this time slot")

        key = update.model_dump(exclude={"revision", "status"})
        marks = [
            mark for mark in document.get("attendance", [])
            if not all(mark[field] == value for field, value in key.items())
        ]
        if update.status is not None:
            marks.append({**key, "status": update.status})
        document["attendance"] = marks
        document["revision"] += 1
        replace_schedule(document, update.revision)
        return schedule_response(document, update.roster_group_id, True)

    return router
