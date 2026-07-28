from dataclasses import dataclass
from typing import Any, Callable

from bson import ObjectId
from fastapi import APIRouter, HTTPException

from models.groups import ApproveJoinRequest, JoinCodeRequest, JoinGroupRequest


@dataclass(frozen=True)
class UserDependencies:
    group_members_collection: Any
    groups_collection: Any
    join_requests_collection: Any
    get_keycloak_admin_token: Callable[..., Any]
    find_keycloak_user_id: Callable[..., Any]
    assign_user_to_group: Callable[..., Any]
    now_utc: Callable[..., Any]


def create_user_router(dependencies: UserDependencies) -> APIRouter:
    router = APIRouter()

    @router.post("/groups/join", tags=["groups", "users"])
    def join_group(request: JoinCodeRequest):
        group = dependencies.groups_collection.find_one({
            "join_code": request.join_code.upper(),
        })

        if not group:
            raise HTTPException(status_code=404, detail="Invalid join code")

        admin_token = dependencies.get_keycloak_admin_token()
        user_id = dependencies.find_keycloak_user_id(
            request.username,
            admin_token,
        )

        if not user_id:
            raise HTTPException(status_code=404, detail="User not found")

        dependencies.assign_user_to_group(
            user_id,
            group["group_id"],
            admin_token,
        )
        dependencies.group_members_collection.update_one(
            {"group_id": group["group_id"], "user_id": user_id},
            {
                "$set": {
                    "group_id": group["group_id"],
                    "user_id": user_id,
                    "username": request.username,
                    "role": "member",
                    "joined_at": dependencies.now_utc(),
                }
            },
            upsert=True,
        )

        return {"success": True, "group_name": group["name"]}

    @router.post("/groups/join-request", tags=["groups", "users"])
    def request_join_group(request: JoinGroupRequest):
        existing = dependencies.join_requests_collection.find_one({
            "username": request.username,
            "group_id": request.group_id,
            "status": "pending",
        })

        if existing:
            raise HTTPException(
                status_code=400,
                detail="Request already pending",
            )

        result = dependencies.join_requests_collection.insert_one({
            "username": request.username,
            "group_id": request.group_id,
            "status": "pending",
            "created_at": dependencies.now_utc(),
        })

        return {"success": True, "request_id": str(result.inserted_id)}

    @router.get("/groups/{group_id}/requests", tags=["groups", "users"])
    def get_group_requests(group_id: str):
        return list(dependencies.join_requests_collection.find(
            {"group_id": group_id, "status": "pending"},
            {"_id": 0},
        ))

    @router.post("/groups/approve-request", tags=["groups", "users"])
    def approve_join_request(request: ApproveJoinRequest):
        join_request = dependencies.join_requests_collection.find_one({
            "_id": ObjectId(request.request_id),
        })

        if not join_request:
            raise HTTPException(status_code=404, detail="Request not found")

        if join_request["status"] != "pending":
            raise HTTPException(
                status_code=400,
                detail="Request already processed",
            )

        admin_token = dependencies.get_keycloak_admin_token()
        user_id = dependencies.find_keycloak_user_id(
            join_request["username"],
            admin_token,
        )

        if not user_id:
            raise HTTPException(
                status_code=404,
                detail="User not found in Keycloak",
            )

        dependencies.assign_user_to_group(
            user_id,
            join_request["group_id"],
            admin_token,
        )
        dependencies.group_members_collection.update_one(
            {"group_id": join_request["group_id"], "user_id": user_id},
            {
                "$set": {
                    "group_id": join_request["group_id"],
                    "user_id": user_id,
                    "username": join_request["username"],
                    "role": "member",
                    "joined_at": dependencies.now_utc(),
                }
            },
            upsert=True,
        )
        dependencies.join_requests_collection.update_one(
            {"_id": join_request["_id"]},
            {
                "$set": {
                    "status": "approved",
                    "approved_at": dependencies.now_utc(),
                }
            },
        )

        return {"success": True}

    @router.post("/groups/reject-request", tags=["groups", "users"])
    def reject_join_request(request: ApproveJoinRequest):
        result = dependencies.join_requests_collection.update_one(
            {"_id": ObjectId(request.request_id)},
            {
                "$set": {
                    "status": "rejected",
                    "rejected_at": dependencies.now_utc(),
                }
            },
        )

        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Request not found")

        return {"success": True}

    @router.post("/groups/set-role", tags=["groups", "users"])
    def set_user_role(
        group_id: str,
        username: str,
        new_role: str,
        requester_username: str,
    ):
        if new_role not in {"member", "admin"}:
            raise HTTPException(status_code=400, detail="Invalid role")

        admin_token = dependencies.get_keycloak_admin_token()
        requester_id = dependencies.find_keycloak_user_id(
            requester_username,
            admin_token,
        )

        if not requester_id:
            raise HTTPException(status_code=401, detail="Requester not found")

        requester = dependencies.group_members_collection.find_one({
            "group_id": group_id,
            "user_id": requester_id,
        })

        if not requester:
            raise HTTPException(
                status_code=403,
                detail="Requester is not in this group",
            )

        if requester.get("role") != "owner":
            raise HTTPException(
                status_code=403,
                detail="Only the group owner can change member roles",
            )

        user_id = dependencies.find_keycloak_user_id(username, admin_token)

        if not user_id:
            raise HTTPException(status_code=404, detail="User not found")

        member = dependencies.group_members_collection.find_one({
            "group_id": group_id,
            "user_id": user_id,
        })

        if not member:
            raise HTTPException(status_code=404, detail="User not in group")

        if member.get("role") == "owner":
            raise HTTPException(
                status_code=403,
                detail="The owner role cannot be changed",
            )

        dependencies.group_members_collection.update_one(
            {"group_id": group_id, "user_id": user_id},
            {"$set": {"role": new_role}},
        )

        return {
            "success": True,
            "username": username,
            "new_role": new_role,
        }

    @router.get("/groups/{group_id}/members", tags=["groups", "users"])
    def get_group_members(group_id: str):
        members = list(dependencies.group_members_collection.find(
            {"group_id": group_id},
            {"_id": 0},
        ))
        grouped = {"owner": [], "admin": [], "member": []}

        for member in members:
            role = member.get("role", "member")
            grouped.setdefault(role, []).append(member)

        return grouped

    @router.get("/user/group", tags=["groups", "users"])
    def get_user_group(username: str):
        member = dependencies.group_members_collection.find_one(
            {"username": username},
            {"_id": 0},
        )

        if not member:
            raise HTTPException(
                status_code=404,
                detail="User not in any group",
            )

        group = dependencies.groups_collection.find_one(
            {"group_id": member["group_id"]},
            {"_id": 0},
        )

        if not group:
            raise HTTPException(status_code=404, detail="Group not found")

        return {
            "group_id": member["group_id"],
            "name": group["name"],
            "role": member["role"],
        }

    return router
