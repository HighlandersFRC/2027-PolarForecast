from dataclasses import dataclass
from typing import Any, Callable

from fastapi import APIRouter, HTTPException

from models.groups import (
    AddGroupEventRequest,
    GroupCreateRequest,
    RemoveGroupEventRequest,
)


@dataclass(frozen=True)
class GroupDependencies:
    groups_collection: Any
    group_members_collection: Any
    group_stats_collection: Any
    group_pit_status_collection: Any
    follow_up_collection: Any
    rebuild_group_stats: Callable[..., Any]
    rebuild_group_pit_status: Callable[..., Any]
    get_keycloak_admin_token: Callable[..., Any]
    create_keycloak_group: Callable[..., Any]
    generate_join_code: Callable[..., Any]
    find_keycloak_user_id: Callable[..., Any]
    assign_user_to_group: Callable[..., Any]
    now_utc: Callable[..., Any]


def create_group_router(dependencies: GroupDependencies) -> APIRouter:
    router = APIRouter()

    @router.get("/joincode/{group_id}", tags=["groups"])
    def joincode(group_id: str):
        group = dependencies.groups_collection.find_one(
            {"group_id": group_id},
            {"_id": 0},
        )

        if not group:
            raise HTTPException(status_code=404, detail="Group not found")

        return group.get("join_code")

    @router.get("/groups/{group_name}/invite", tags=["groups"])
    def get_invite_code(group_name: str):
        group = dependencies.groups_collection.find_one({"name": group_name})

        if not group:
            raise HTTPException(status_code=404, detail="Group not found")

        return {"join_code": group["join_code"]}

    @router.post("/groups/add-event", tags=["groups"])
    def add_group_event(request: AddGroupEventRequest):
        result = dependencies.groups_collection.update_one(
            {"group_id": request.group_id},
            {"$addToSet": {"events": request.event_code}},
        )

        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Group not found")

        stats_refreshed = False
        pit_status_refreshed = False

        try:
            dependencies.rebuild_group_stats(
                request.group_id,
                request.event_code,
            )
            stats_refreshed = True
        except Exception as error:
            print(
                "Could not initialize GroupStats for "
                f"{request.group_id}/{request.event_code}: {error}"
            )

        try:
            dependencies.rebuild_group_pit_status(
                request.group_id,
                request.event_code,
            )
            pit_status_refreshed = True
        except Exception as error:
            print(
                "Could not initialize GroupPitScoutingStatus for "
                f"{request.group_id}/{request.event_code}: {error}"
            )

        return {
            "success": True,
            "group_stats_refreshed": stats_refreshed,
            "pit_status_refreshed": pit_status_refreshed,
        }

    @router.post("/groups/remove-event", tags=["groups"])
    def remove_group_event(request: RemoveGroupEventRequest):
        result = dependencies.groups_collection.update_one(
            {"group_id": request.group_id},
            {"$pull": {"events": request.event_code}},
        )

        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Group not found")

        query = {
            "group_id": request.group_id,
            "event_key": request.event_code,
        }
        dependencies.group_stats_collection.delete_one(query)
        dependencies.group_pit_status_collection.delete_one(query)
        dependencies.follow_up_collection.delete_many({
            "event": request.event_code,
            "$or": [
                {"groupId": request.group_id},
                {"groupID": request.group_id},
                {"group_id": request.group_id},
            ],
        })

        return {"success": True}

    @router.get("/groups/{group_id}/events", tags=["groups"])
    def get_group_events(group_id: str):
        group = dependencies.groups_collection.find_one(
            {"group_id": group_id},
            {"_id": 0},
        )

        if not group:
            raise HTTPException(status_code=404, detail="Group not found")

        return {
            "group_id": group_id,
            "events": group.get("events", []),
        }

    @router.post("/groups", tags=["groups"])
    def create_group(group: GroupCreateRequest):
        admin_token = dependencies.get_keycloak_admin_token()
        group_id = dependencies.create_keycloak_group(
            group.name,
            admin_token,
        )
        join_code = dependencies.generate_join_code()

        dependencies.groups_collection.insert_one({
            "group_id": group_id,
            "name": group.name,
            "join_code": join_code,
            "created_at": dependencies.now_utc(),
        })

        if group.username:
            owner_user_id = dependencies.find_keycloak_user_id(
                group.username,
                admin_token,
            )

            if owner_user_id:
                dependencies.assign_user_to_group(
                    owner_user_id,
                    group_id,
                    admin_token,
                )
                dependencies.group_members_collection.insert_one({
                    "group_id": group_id,
                    "user_id": owner_user_id,
                    "username": group.username,
                    "role": "owner",
                    "joined_at": dependencies.now_utc(),
                })

        return {
            "success": True,
            "group_id": group_id,
            "join_code": join_code,
        }

    return router
