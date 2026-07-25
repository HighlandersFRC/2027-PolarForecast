import random
import re
import string

from bson import ObjectId
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi import HTTPException
from pymongo import MongoClient
import requests
from datetime import datetime, timedelta, timezone
from threading import Lock, Thread
from time import sleep

from models.Matchscouting import MatchScouting
from models.Pitscouting import Pitscouting
from models.FollowUp import FollowUp
from models.Groups import AddGroupEventRequest, ApproveJoinRequest, GroupCreateRequest, JoinCodeRequest, JoinGroupRequest, RemoveGroupEventRequest
from LinReg import linreg, linreg_TBA
from Predictions import predict as predict_matches
from config import ALLOW_ORIGINS, MONGO_URI, TBA_API_URL, TBA_KEY, KEYCLOAK_BASE_URL, KEYCLOAK_MASTER_REALM, KEYCLOAK_REALM, KEYCLOAK_ADMIN_USERNAME, KEYCLOAK_ADMIN_PASSWORD, KEYCLOAK_ADMIN_CLIENT_ID



YEAR = "2026"

# Wait this long after one cache update finishes before starting the next one.
CACHE_UPDATE_INTERVAL_SECONDS = 300

# Increment this whenever prediction-generation behavior changes.
# Existing cached predictions with an older version will be rebuilt,
# even when TBA returns 304 Not Modified for the event matches.
PREDICTION_CACHE_VERSION = 4

STATS_CACHE_VERSION = 3
GROUP_STATS_CACHE_VERSION = 2
tags_metadata = [
    {
        "name": "default",
        "description": "Default endpoint to see if server is running",
    },
    {
        "name": "stats",
        "description": "All of the stats Get endpoints.",
    },
    {
        "name": "scouting",
        "description": "All of the scouting data Get and Post endpoints.",
    },
    {
        "name": "users",
        "description": "Manage users.",
    },
    {
        "name": "groups",
        "description": "Manage groups.",
    },
    {
        "name": "alliances",
        "description": "Manage alliances.",
    },
    {
        "name": "miscellaneous",
        "description": "Other endpoints.",
    },
    {
        "name": "picklists",
        "description": "All endpoints related to picklists"
    }
]

ROLE_PRIORITY = {
    "member": 0,
    "admin": 1,
    "owner": 2
}

HEADERS = {
    "X-TBA-Auth-Key": TBA_KEY
}

client = MongoClient(MONGO_URI)


db = client["PFDB"]

StatsCollection = db["Stats"]
PredictionCollection = db["Predictions"]
ETagsCollection = db["ETags"]
EventsCollection = db["Events"]
CacheStatusCollection = db["CacheStatus"]
GroupsCollection = db["Groups"]
JoinRequestsCollection = db["JoinRequests"]
GroupMembersCollection = db["GroupMembers"]
MatchScoutingCollection = db["2026MatchScouting"]
PitScoutingCollection = db["2026PitScouting"]
TBACollection = db["TBAData"]
GroupStatsCollection = db["GroupStats"]
GroupPitStatus = db["GroupPitScoutingStatus"]
FollowUpCollection = db["2026FollowUps"]


cache_update_lock = Lock()
cache_update_thread = None

app = FastAPI(openapi_tags=tags_metadata)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOW_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"]
)


@app.get("/", tags=["default"])
def default():
    return {"Polar", "Forecast"}

@app.post("/matchscouting", tags=["scouting"])
def post_match_scouting(scouting_data: MatchScouting):
    document = scouting_data.model_dump()
    group_id = document.get("groupId") or document.get("group_id")
    event = document.get("event")
    team = normalize_team_number(document.get("team"))
    scout_info = document.get("scoutInfo", {})

    if not group_id:
        raise HTTPException(
            status_code=400,
            detail="Match scouting document is missing groupId",
        )

    if not event:
        raise HTTPException(
            status_code=400,
            detail="Match scouting document is missing event",
        )

    if team is None:
        raise HTTPException(
            status_code=400,
            detail="Match scouting document has an invalid team",
        )

    if not scout_info_is_current_group_member(group_id, scout_info):
        raise HTTPException(
            status_code=403,
            detail="Scout is not a current member of this group",
        )

    group_id = str(group_id)
    event = str(event)

    document["groupId"] = group_id
    document["event"] = event
    document["team"] = team
    document["submitted_at"] = now_utc()

    result = MatchScoutingCollection.insert_one(document)
    robot_died = match_scouting_robot_died(document)

    pit_status = None
    if robot_died:
        # Recalculate from the death incidents and match-specific follow-ups.
        # One resolved match cannot clear another unresolved match.
        pit_status = rebuild_group_pit_status(group_id, event)

    stats_refreshed = False
    refresh_error = None

    try:
        rebuild_group_stats(group_id, event)
        stats_refreshed = True
    except Exception as error:
        refresh_error = str(error)
        print(
            f"Could not rebuild GroupStats for {group_id}/{event}: "
            f"{error}"
        )

    team_status = None
    if pit_status is not None:
        team_status = next(
            (
                entry
                for entry in pit_status.get("data", [])
                if normalize_team_number(entry.get("team")) == team
            ),
            None,
        )

    return {
        "success": True,
        "inserted_id": str(result.inserted_id),
        "robot_died": robot_died,
        "followups": (
            team_status.get("followups")
            if team_status is not None
            else True
        ),
        "pending_followup_count": (
            team_status.get("pending_followup_count", 0)
            if team_status is not None
            else 0
        ),
        "group_stats_refreshed": stats_refreshed,
        "group_stats_error": refresh_error,
    }

@app.post("/pitscouting", tags=["scouting"])
def post_pit_scouting(pit_data: Pitscouting):
    document = pit_data.model_dump()
    group_id = document.get("groupId") or document.get("group_id")
    event = document.get("event")
    team = normalize_team_number(document.get("team"))
    scout_info = document.get("scoutInfo", {})

    if not group_id:
        raise HTTPException(
            status_code=400,
            detail="Pit scouting document is missing groupId",
        )

    if not event:
        raise HTTPException(
            status_code=400,
            detail="Pit scouting document is missing event",
        )

    if team is None:
        raise HTTPException(
            status_code=400,
            detail="Pit scouting document has an invalid team",
        )

    if not scout_info_is_current_group_member(group_id, scout_info):
        raise HTTPException(
            status_code=403,
            detail="Scout is not a current member of this group",
        )

    # Store one consistent representation so the status cache can match
    # both newer and older pit-scouting documents reliably.
    document["groupId"] = str(group_id)
    document["event"] = str(event)
    document["team"] = team

    result = PitScoutingCollection.insert_one(document)
    status = rebuild_group_pit_status(str(group_id), str(event))

    return {
        "success": True,
        "inserted_id": str(result.inserted_id),
        "pit_status_refreshed": True,
        "pit_status": status,
    }


@app.post("/followup", tags=["scouting"])
@app.post("/followups", tags=["scouting"])
def post_followup(followup_data: FollowUp):
    document = followup_data.model_dump()
    group_id = (
        document.get("groupID")
        or document.get("groupId")
        or document.get("group_id")
    )
    event = document.get("event")
    team = normalize_team_number(document.get("team"))
    match_value = document.get("match")
    match_key = normalize_match_key(match_value)
    scout_info = (
        document.get("scout_info")
        or document.get("scoutInfo")
        or {}
    )

    if not group_id:
        raise HTTPException(
            status_code=400,
            detail="Follow-up document is missing groupID",
        )

    if not event:
        raise HTTPException(
            status_code=400,
            detail="Follow-up document is missing event",
        )

    if team is None:
        raise HTTPException(
            status_code=400,
            detail="Follow-up document has an invalid team",
        )

    if not match_key:
        raise HTTPException(
            status_code=400,
            detail="Follow-up document has an invalid match",
        )

    if not scout_info_is_current_group_member(group_id, scout_info):
        raise HTTPException(
            status_code=403,
            detail="Scout is not a current member of this group",
        )

    group_id = str(group_id)
    event = str(event)

    incidents = build_death_incidents(
        group_id=group_id,
        event=event,
        team=team,
    )
    incident = next(
        (
            item
            for item in incidents
            if item.get("match_key") == match_key
        ),
        None,
    )

    if incident is None:
        raise HTTPException(
            status_code=404,
            detail=(
                f"No robot-death report was found for Team {team} "
                f"in match {match_value}"
            ),
        )

    document["groupID"] = group_id
    document["groupId"] = group_id
    document["event"] = event
    document["team"] = team
    document["match"] = incident["match"]
    document["match_key"] = match_key
    document["scout_info"] = scout_info
    document["submitted_at"] = now_utc()

    result = FollowUpCollection.update_one(
        {
            "groupId": group_id,
            "event": event,
            "team": team,
            "match_key": match_key,
        },
        {"$set": document},
        upsert=True,
    )

    pit_status = rebuild_group_pit_status(group_id, event)
    refreshed_incidents = build_death_incidents(
        group_id=group_id,
        event=event,
        team=team,
    )
    pending_count = sum(
        1 for item in refreshed_incidents if not item.get("resolved", False)
    )

    return {
        "success": True,
        "inserted_id": (
            str(result.upserted_id)
            if result.upserted_id is not None
            else None
        ),
        "updated_existing": result.upserted_id is None,
        "group_id": group_id,
        "event": event,
        "team": team,
        "match": incident["match"],
        "match_key": match_key,
        "followups": pending_count == 0,
        "pending_followup_count": pending_count,
        "pit_status": pit_status,
    }


@app.get("/joincode/{group_id}", tags=["groups"])
def joincode(group_id: str):
    response = GroupsCollection.find_one(
        {"group_id": group_id},
        {"_id": 0} 
    )

    if not response:
        raise HTTPException(
            status_code=404,
            detail="Group not found"
        )

    return response.get("join_code")


@app.get("/{event}/teams", tags=["stats"])
def teams_event(event: str):
    doc = ETagsCollection.find_one(
        {"key": event},
        {"_id": 0, "teams": 1}
    )

    if not doc:
        raise HTTPException(
            status_code=404,
            detail="Event not found"
        )

    return doc["teams"]

@app.get("/{event}/{match}/teams", tags=["stats"])
def teams(event: str, match: int):
    alliances = TBACollection.find_one(
        {"event_key": event, "match_key": f"{event}_qm{match}"},
        {"_id": 0, "alliances": 1}
    )
    return {
        "blue_teams": alliances["alliances"]["blue"]["team_keys"],
        "red_teams": alliances["alliances"]["red"]["team_keys"]
    }


@app.get("/matchscouting/{group_id}/group/{username}/team/{team}/event/{event}", tags=["scouting"])
def get_match_scouting_filtered(
    group_id: str,
    username: str,
    team: int,
    event: str
):
    # --- Step 1: verify user exists in Keycloak ---
    admin_token = get_keycloak_admin_token()

    user_id = find_keycloak_user_id(username, admin_token)

    if not user_id:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    # --- Step 2: verify user is in group ---
    member = GroupMembersCollection.find_one({
        "group_id": group_id,
        "user_id": user_id
    })

    if not member:
        raise HTTPException(
            status_code=403,
            detail="User not in group"
        )

    # --- Step 3: fetch only records submitted by current members ---
    results = get_group_match_scouting(
        group_id=group_id,
        event=event,
        team=team,
    )

    return {
        "group_id": group_id,
        "event": event,
        "team": team,
        "count": len(results),
        "data": results
    }


@app.get(
    "/groups/{group_id}/events/{event}/matchscouting",
    tags=["scouting", "groups"],
)
def get_group_event_match_scouting(
    group_id: str,
    event: str,
    username: str,
):
    """Return the current group's scouting records for one event."""
    require_username_group_member(group_id, username)

    results = get_group_match_scouting(
        group_id=str(group_id),
        event=str(event),
    )

    return {
        "group_id": str(group_id),
        "event": str(event),
        "count": len(results),
        "data": results,
    }


@app.get(
    "/followup/{group_id}/group/{username}/team/{team}/event/{event}",
    tags=["scouting"],
)
@app.get(
    "/followups/{group_id}/group/{username}/team/{team}/event/{event}",
    tags=["scouting"],
)
@app.get(
    "/followup/{group_id}/group/{username}/team/{team}/event/{event}/incidents",
    tags=["scouting"],
)
def get_followup_incidents(
    group_id: str,
    username: str,
    team: int,
    event: str,
):
    require_username_group_member(group_id, username)

    incidents = build_death_incidents(
        group_id=str(group_id),
        event=str(event),
        team=team,
    )

    pending_count = sum(
        1 for incident in incidents if not incident.get("resolved", False)
    )

    return {
        "group_id": str(group_id),
        "event": str(event),
        "team": team,
        "count": len(incidents),
        "pending_count": pending_count,
        "all_resolved": pending_count == 0,
        "data": incidents,
    }


@app.get("/pitscouting/{group_id}/group/{username}/team/{team}/event/{event}", tags=["stats"])
def get_pit_scouting_filtered( group_id: str,
    username: str,
    team: int,
    event: str):

    admin_token = get_keycloak_admin_token()

    user_id = find_keycloak_user_id(username, admin_token)

    if not user_id:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    member = GroupMembersCollection.find_one({
        "group_id": group_id,
        "user_id": user_id
    })

    if not member:
        raise HTTPException(
            status_code=403,
            detail="User not in group"
        )

    results = list(PitScoutingCollection.find(
        {
            "groupId": group_id,
            "event": event,
            "team": team
        },
        {"_id": 0}
    ))

    return {
        "group_id": group_id,
        "event": event,
        "team": team,
        "count": len(results),
        "data": results
    }


@app.get(
    "/groups/{group_id}/events/{event}/pit-status",
    tags=["scouting", "groups"],
)
def get_group_pit_status(
    group_id: str,
    event: str,
    username: str,
):
    require_username_group_member(group_id, username)

    document = GroupPitStatus.find_one(
        {
            "group_id": group_id,
            "event_key": event,
        },
        {"_id": 0},
    )

    if document is None:
        document = rebuild_group_pit_status(group_id, event)

    return document


@app.get("/{event}/event/{team}/team", tags=["stats"])
def team_stats(event: str, team: str):

    doc = StatsCollection.find_one(
        {"event_key": event},
        {"_id": 0, "data": 1}
    )

    if not doc or "data" not in doc:
        raise HTTPException(status_code=404, detail="No stats found for event")

    # normalize team input
    try:
        team_int = int(team.replace("frc", "").strip())
    except:
        raise HTTPException(status_code=400, detail="Invalid team format")

    # search inside event stats
    for entry in doc["data"]:
        if entry.get("Team") == team_int:
            return {
                "event": event,
                "team": team_int,
                "stats": entry
            }

    raise HTTPException(
        status_code=404,
        detail=f"Team {team_int} not found in event {event}"
    )
@app.get("/{event}/stats", tags=["stats"])
def stats(
    event: str,
    username: str | None = None,
):
    data = get_stats_from_db(
        event=event,
        username=username,
    )

    if data is None:
        raise HTTPException(
            status_code=404,
            detail=(
                "Stats are not cached for this event yet"
            ),
        )

    return data

@app.get("/groups/{group_id}/events/{event}/stats", tags=["stats", "groups"])
def group_event_stats(
    group_id: str,
    event: str,
    username: str,
):
    require_username_group_member(group_id, username)

    document = GroupStatsCollection.find_one(
        {
            "group_id": group_id,
            "event_key": event,
        },
        {"_id": 0},
    )

    if document is None:
        rebuild_group_stats(group_id, event)
        document = GroupStatsCollection.find_one(
            {
                "group_id": group_id,
                "event_key": event,
            },
            {"_id": 0},
        )

    if document is None:
        raise HTTPException(
            status_code=404,
            detail="Group stats are not available for this event yet",
        )

    return document


@app.get(
    "/groups/{group_id}/events/{event}/teams/{team}/stats",
    tags=["stats", "groups"],
)
def group_event_team_stats(
    group_id: str,
    event: str,
    team: int,
    username: str,
):
    require_username_group_member(group_id, username)

    document = GroupStatsCollection.find_one(
        {
            "group_id": group_id,
            "event_key": event,
        },
        {"_id": 0, "data": 1},
    )

    if document is None:
        rebuild_group_stats(group_id, event)
        document = GroupStatsCollection.find_one(
            {
                "group_id": group_id,
                "event_key": event,
            },
            {"_id": 0, "data": 1},
        )

    for team_stats in (document or {}).get("data", []):
        if team_stats.get("Team") == team:
            return {
                "group_id": group_id,
                "event": event,
                "team": team,
                "stats": team_stats,
            }

    raise HTTPException(
        status_code=404,
        detail=f"Team {team} was not found in GroupStats for {event}",
    )

@app.get("/{event}/predictions", tags=["stats"])
def predictions(event: str):
    data = get_predictions_from_db(event)
    if data is None:
        
        raise HTTPException(status_code=404, detail="Predictions are not cached for this event yet")

    return data

@app.get("/searchkeys", tags=["miscellaneous"])
def search_keys(year: str = YEAR):
    events = get_events_from_db(year)
    return {
        "data": [format_search_key(event, year) for event in events]
    }


@app.get("/cache/status", tags=["miscellaneous"])
def cache_status(year: str = YEAR):
    status = CacheStatusCollection.find_one({"year": str(year)}, {"_id": 0})
    if status is None:
        return {"year": str(year), "status": "not_started"}

    return status


@app.get("/groups/{group_name}/invite", tags=["groups"])
def get_invite_code(group_name: str):

    group = GroupsCollection.find_one({
        "name": group_name
    })

    if not group:
        raise HTTPException(
            status_code=404,
            detail="Group not found"
        )

    return {
        "join_code": group["join_code"]
    }

@app.post("/groups/join", tags=["groups"])
def join_group(request: JoinCodeRequest):

    group = GroupsCollection.find_one({
        "join_code": request.join_code.upper()
    })

    if not group:
        raise HTTPException(
            status_code=404,
            detail="Invalid join code"
        )

    admin_token = get_keycloak_admin_token()

    user_id = find_keycloak_user_id(
        request.username,
        admin_token
    )

    if not user_id:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    assign_user_to_group(
        user_id,
        group["group_id"],
        admin_token
    )

    # DEFAULT ROLE = MEMBER
    GroupMembersCollection.update_one(
        {
            "group_id": group["group_id"],
            "user_id": user_id
        },
        {
            "$set": {
                "group_id": group["group_id"],
                "user_id": user_id,
                "username": request.username,
                "role": "member",
                "joined_at": now_utc()
            }
        },
        upsert=True
    )

    return {
        "success": True,
        "group_name": group["name"]
    }


@app.post("/groups/add-event", tags=["groups"])
def add_group_event(req: AddGroupEventRequest):

    result = GroupsCollection.update_one(
        {"group_id": req.group_id},
        {
            "$addToSet": {   # prevents duplicates
                "events": req.event_code
            }
        }
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Group not found")

    stats_refreshed = False
    pit_status_refreshed = False

    try:
        rebuild_group_stats(req.group_id, req.event_code)
        stats_refreshed = True
    except Exception as error:
        print(
            f"Could not initialize GroupStats for "
            f"{req.group_id}/{req.event_code}: {error}"
        )

    try:
        rebuild_group_pit_status(req.group_id, req.event_code)
        pit_status_refreshed = True
    except Exception as error:
        print(
            f"Could not initialize GroupPitScoutingStatus for "
            f"{req.group_id}/{req.event_code}: {error}"
        )

    return {
        "success": True,
        "group_stats_refreshed": stats_refreshed,
        "pit_status_refreshed": pit_status_refreshed,
    }


@app.post("/groups/remove-event", tags=["groups"])
def remove_group_event(req: RemoveGroupEventRequest):

    result = GroupsCollection.update_one(
        {"group_id": req.group_id},
        {
            "$pull": {
                "events": req.event_code
            }
        }
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Group not found")

    GroupStatsCollection.delete_one({
        "group_id": req.group_id,
        "event_key": req.event_code,
    })
    GroupPitStatus.delete_one({
        "group_id": req.group_id,
        "event_key": req.event_code,
    })
    FollowUpCollection.delete_many({
        "event": req.event_code,
        "$or": [
            {"groupId": req.group_id},
            {"groupID": req.group_id},
            {"group_id": req.group_id},
        ],
    })

    return {"success": True}

@app.get("/groups/{group_id}/events", tags=["groups"])
def get_group_events(group_id: str):
    group = GroupsCollection.find_one({"group_id": group_id}, {"_id": 0})

    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    return {
        "group_id": group_id,
        "events": group.get("events", [])
    }
    
@app.post("/groups/join-request", tags=["groups"])
def request_join_group(request: JoinGroupRequest):
    existing = JoinRequestsCollection.find_one({
        "username": request.username,
        "group_id": request.group_id,
        "status": "pending"
    })

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Request already pending"
        )

    result = JoinRequestsCollection.insert_one({
        "username": request.username,
        "group_id": request.group_id,
        "status": "pending",
        "created_at": now_utc()
    })

    return {
        "success": True,
        "request_id": str(result.inserted_id)
    }

@app.get("/groups/{group_id}/requests", tags=["groups"])
def get_group_requests(group_id: str):
    requests = list(
        JoinRequestsCollection.find(
            {
                "group_id": group_id,
                "status": "pending"
            },
            {"_id": 0}
        )
    )

    return requests

@app.post("/groups/approve-request", tags=["groups"])
def approve_join_request(request: ApproveJoinRequest):
    join_request = JoinRequestsCollection.find_one({
        "_id": ObjectId(request.request_id)
    })

    if not join_request:
        raise HTTPException(
            status_code=404,
            detail="Request not found"
        )

    if join_request["status"] != "pending":
        raise HTTPException(
            status_code=400,
            detail="Request already processed"
        )

    admin_token = get_keycloak_admin_token()

    user_id = find_keycloak_user_id(
        join_request["username"],
        admin_token
    )

    if not user_id:
        raise HTTPException(
            status_code=404,
            detail="User not found in Keycloak"
        )

    assign_user_to_group(
        user_id,
        join_request["group_id"],
        admin_token
    )

    GroupMembersCollection.update_one(
        {
            "group_id": join_request["group_id"],
            "user_id": user_id,
        },
        {
            "$set": {
                "group_id": join_request["group_id"],
                "user_id": user_id,
                "username": join_request["username"],
                "role": "member",
                "joined_at": now_utc(),
            }
        },
        upsert=True,
    )

    JoinRequestsCollection.update_one(
        {"_id": join_request["_id"]},
        {
            "$set": {
                "status": "approved",
                "approved_at": now_utc()
            }
        }
    )

    return {
        "success": True
    }

@app.post('/groups/set-role', tags=['groups'])
def set_user_role(
    group_id: str,
    username: str,
    new_role: str,
    requester_username: str,
):
    if new_role not in ['member', 'admin']:
        raise HTTPException(status_code=400, detail='Invalid role')

    admin_token = get_keycloak_admin_token()

    requester_id = find_keycloak_user_id(
        requester_username,
        admin_token,
    )

    if not requester_id:
        raise HTTPException(status_code=401, detail='Requester not found')

    requester = GroupMembersCollection.find_one({
        'group_id': group_id,
        'user_id': requester_id,
    })

    if not requester:
        raise HTTPException(
            status_code=403,
            detail='Requester is not in this group',
        )

    if requester.get('role') != 'owner':
        raise HTTPException(
            status_code=403,
            detail='Only the group owner can change member roles',
        )

    user_id = find_keycloak_user_id(username, admin_token)

    if not user_id:
        raise HTTPException(status_code=404, detail='User not found')

    member = GroupMembersCollection.find_one({
        'group_id': group_id,
        'user_id': user_id,
    })

    if not member:
        raise HTTPException(status_code=404, detail='User not in group')

    if member.get('role') == 'owner':
        raise HTTPException(
            status_code=403,
            detail='The owner role cannot be changed',
        )

    GroupMembersCollection.update_one(
        {
            'group_id': group_id,
            'user_id': user_id,
        },
        {
            '$set': {
                'role': new_role,
            }
        },
    )

    return {
        'success': True,
        'username': username,
        'new_role': new_role,
    }

@app.get("/groups/{group_id}/members", tags=["groups"])
def get_group_members(group_id: str):

    members = list(GroupMembersCollection.find(
        {"group_id": group_id},
        {"_id": 0}
    ))

    grouped = {
        "owner": [],
        "admin": [],
        "member": []
    }

    for m in members:
        role = m.get("role", "member")
        grouped.setdefault(role, []).append(m)

    return grouped

@app.get("/user/group", tags=["groups"])
def get_user_group(username: str):

    member = GroupMembersCollection.find_one(
        {"username": username},
        {"_id": 0}
    )

    if not member:
        raise HTTPException(status_code=404, detail="User not in any group")

    group = GroupsCollection.find_one(
        {"group_id": member["group_id"]},
        {"_id": 0}
    )

    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    return {
        "group_id": member["group_id"],
        "name": group["name"],
        "role": member["role"]
    }
    
@app.post("/groups/reject-request", tags=["groups"])
def reject_join_request(request: ApproveJoinRequest):
    result = JoinRequestsCollection.update_one(
        {"_id": ObjectId(request.request_id)},
        {
            "$set": {
                "status": "rejected",
                "rejected_at": now_utc()
            }
        }
    )

    if result.matched_count == 0:
        raise HTTPException(
            status_code=404,
            detail="Request not found"
        )

    return {"success": True}

def ensure_database_indexes():
    # Created at startup so importing this module does not require an
    # immediate MongoDB round trip.
    GroupStatsCollection.create_index(
        [("group_id", 1), ("event_key", 1)],
        unique=True,
    )
    MatchScoutingCollection.create_index(
        [("groupId", 1), ("event", 1), ("team", 1)]
    )
    PitScoutingCollection.create_index(
        [("groupId", 1), ("event", 1), ("team", 1)]
    )
    GroupPitStatus.create_index(
        [("group_id", 1), ("event_key", 1)],
        unique=True,
    )
    FollowUpCollection.create_index(
        [
            ("groupId", 1),
            ("event", 1),
            ("team", 1),
            ("match_key", 1),
        ]
    )


@app.on_event("startup")
def updateDatabase():
    ensure_database_indexes()
    start_background_update(YEAR)


def now_utc():
    return datetime.now(timezone.utc)


def get_group_member_identity_sets(group_id: str):
    members = list(GroupMembersCollection.find(
        {"group_id": group_id},
        {
            "_id": 0,
            "user_id": 1,
            "username": 1,
        },
    ))

    user_ids = {
        str(member["user_id"])
        for member in members
        if member.get("user_id") is not None
    }
    usernames = {
        str(member["username"])
        for member in members
        if member.get("username")
    }

    return members, user_ids, usernames


def _scout_info_matches_member_sets(
    scout_info: dict,
    member_user_ids: set[str],
    member_usernames: set[str],
) -> bool:
    if not isinstance(scout_info, dict):
        return False

    scout_user_id = scout_info.get("userId")
    scout_username = scout_info.get("username")

    scout_user_id = (
        str(scout_user_id)
        if scout_user_id is not None
        else None
    )
    scout_username = (
        str(scout_username)
        if scout_username is not None
        else None
    )

    # Older scouting records may store the username inside userId, while
    # newer ones may store the Keycloak UUID. Accept either representation,
    # but only when it resolves to a current GroupMembers row.
    return any((
        scout_user_id in member_user_ids,
        scout_user_id in member_usernames,
        scout_username in member_usernames,
        scout_username in member_user_ids,
    ))


def scout_info_is_current_group_member(
    group_id: str,
    scout_info: dict,
) -> bool:
    _, member_user_ids, member_usernames = (
        get_group_member_identity_sets(group_id)
    )

    return _scout_info_matches_member_sets(
        scout_info,
        member_user_ids,
        member_usernames,
    )


def get_group_match_scouting(
    group_id: str,
    event: str,
    team: int | None = None,
):
    query = {
        "groupId": group_id,
        "event": event,
    }

    if team is not None:
        query["team"] = team

    candidates = list(MatchScoutingCollection.find(
        query,
        {"_id": 0},
    ))

    _, member_user_ids, member_usernames = (
        get_group_member_identity_sets(group_id)
    )

    return [
        document
        for document in candidates
        if (
            document.get("groupId") == group_id
            and _scout_info_matches_member_sets(
                document.get("scoutInfo", {}),
                member_user_ids,
                member_usernames,
            )
        )
    ]



def get_group_followups(
    group_id: str,
    event: str,
    team: int | None = None,
):
    query = {
        "groupId": str(group_id),
        "event": str(event),
    }

    if team is not None:
        query["team"] = team

    candidates = list(FollowUpCollection.find(
        query,
        {"_id": 0},
    ))

    _, member_user_ids, member_usernames = (
        get_group_member_identity_sets(str(group_id))
    )

    return [
        document
        for document in candidates
        if _scout_info_matches_member_sets(
            document.get("scout_info")
            or document.get("scoutInfo")
            or {},
            member_user_ids,
            member_usernames,
        )
    ]



def require_username_group_member(
    group_id: str,
    username: str,
):
    admin_token = get_keycloak_admin_token()
    user_id = find_keycloak_user_id(username, admin_token)

    if not user_id:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    member = GroupMembersCollection.find_one({
        "group_id": group_id,
        "user_id": user_id,
    })

    if not member:
        raise HTTPException(
            status_code=403,
            detail="User not in group",
        )

    return member


def get_cached_event_analysis_inputs(event: str):
    matches = list(TBACollection.find(
        {"event_key": event},
        {
            "_id": 0,
            "event_key": 0,
            "match_key": 0,
            "updated_at": 0,
        },
    ))

    etag_document = ETagsCollection.find_one(
        {"key": event},
        {
            "_id": 0,
            "rankings": 1,
        },
    ) or {}

    rankings_data = {
        "rankings": etag_document.get("rankings", []),
    }

    return matches, rankings_data


def normalize_team_number(value) -> int | None:
    if value is None or isinstance(value, bool):
        return None

    if isinstance(value, int):
        return value

    text = str(value).strip().lower()
    if text.startswith("frc"):
        text = text[3:]

    try:
        return int(text)
    except (TypeError, ValueError):
        return None


def get_event_team_numbers(event: str) -> list[int]:
    team_numbers: set[int] = set()

    event_document = ETagsCollection.find_one(
        {"key": event},
        {"_id": 0, "teams": 1},
    ) or {}

    for team_value in event_document.get("teams", []):
        team_number = normalize_team_number(team_value)
        if team_number is not None:
            team_numbers.add(team_number)

    # Fall back to cached matches when the event team list has not been
    # fetched yet. This also keeps the checklist usable during cache startup.
    if not team_numbers:
        matches = TBACollection.find(
            {"event_key": event},
            {"_id": 0, "alliances": 1},
        )

        for match in matches:
            alliances = match.get("alliances", {})
            for alliance_name in ("red", "blue"):
                alliance = alliances.get(alliance_name, {})
                for team_value in alliance.get("team_keys", []):
                    team_number = normalize_team_number(team_value)
                    if team_number is not None:
                        team_numbers.add(team_number)

    return sorted(team_numbers)


def get_completed_pit_teams(group_id: str, event: str) -> set[int]:
    completed: set[int] = set()

    documents = PitScoutingCollection.find(
        {
            "event": event,
            "$or": [
                {"groupId": group_id},
                {"group_id": group_id},
            ],
        },
        {"_id": 0, "team": 1},
    )

    for document in documents:
        team_number = normalize_team_number(document.get("team"))
        if team_number is not None:
            completed.add(team_number)

    return completed



def normalize_match_key(value) -> str:
    if value is None:
        return ""

    return str(value).strip().lower()


def match_sort_key(value) -> tuple[int, int, int, str]:
    text = normalize_match_key(value)

    qualification = re.search(r"(?:^|_)qm(\d+)$", text)
    if qualification:
        return 0, int(qualification.group(1)), 0, text

    if text.isdigit():
        return 0, int(text), 0, text

    semifinal = re.search(r"(?:^|_)sf(\d+)(?:m(\d+))?$", text)
    if semifinal:
        return (
            1,
            int(semifinal.group(1)),
            int(semifinal.group(2) or 0),
            text,
        )

    final = re.search(r"(?:^|_)f(\d+)$", text)
    if final:
        return 2, int(final.group(1)), 0, text

    numbers = re.findall(r"\d+", text)
    return 3, int(numbers[-1]) if numbers else 0, 0, text


def match_scouting_robot_died(document: dict) -> bool:
    data = document.get("data") or {}
    misc = data.get("misc") or {}
    return misc.get("died") is True


def _public_scout_name(scout_info: dict) -> str:
    if not isinstance(scout_info, dict):
        return "Unknown"

    return str(
        scout_info.get("firstName")
        or scout_info.get("username")
        or "Unknown"
    )


def _followup_public_data(document: dict | None):
    if not document:
        return None

    data = document.get("data") or {}
    scout_info = (
        document.get("scout_info")
        or document.get("scoutInfo")
        or {}
    )

    return {
        "severity": str(data.get("severity") or ""),
        "comments": str(data.get("comments") or ""),
        "scout_name": _public_scout_name(scout_info),
        "submitted_at": document.get("submitted_at"),
    }

def _document_order_key(document: dict) -> tuple[datetime, str]:
    """
    Returns a stable chronological ordering key.

    New documents use submitted_at. Older documents fall back to updated_at,
    created_at, or the MongoDB ObjectId creation timestamp.
    """
    timestamp = None

    for field_name in ("submitted_at", "updated_at", "created_at"):
        value = document.get(field_name)

        if isinstance(value, datetime):
            timestamp = value

        elif isinstance(value, str) and value.strip():
            try:
                timestamp = datetime.fromisoformat(
                    value.strip().replace("Z", "+00:00")
                )
            except ValueError:
                timestamp = None

        if timestamp is not None:
            break

    document_id = document.get("_id")

    if timestamp is None and isinstance(document_id, ObjectId):
        timestamp = document_id.generation_time

    if timestamp is None:
        timestamp = datetime.min.replace(tzinfo=timezone.utc)
    elif timestamp.tzinfo is None:
        timestamp = timestamp.replace(tzinfo=timezone.utc)
    else:
        timestamp = timestamp.astimezone(timezone.utc)

    return timestamp, str(document_id or "")


def build_death_incidents(
    group_id: str,
    event: str,
    team: int | None = None,
) -> list[dict]:
    group_id = str(group_id)
    event = str(event)

    query = {
        "event": event,
        "$or": [
            {"groupId": group_id},
            {"groupID": group_id},
            {"group_id": group_id},
        ],
    }

    if team is not None:
        normalized_team = normalize_team_number(team)
        if normalized_team is None:
            return []
        query["team"] = normalized_team

    _, member_user_ids, member_usernames = (
        get_group_member_identity_sets(group_id)
    )

    incidents: dict[tuple[int, str], dict] = {}

    for document in MatchScoutingCollection.find(query):
        if not match_scouting_robot_died(document):
            continue

        scout_info = document.get("scoutInfo") or {}
        if not _scout_info_matches_member_sets(
            scout_info,
            member_user_ids,
            member_usernames,
        ):
            continue

        team_number = normalize_team_number(document.get("team"))
        match_key = normalize_match_key(document.get("match"))

        if team_number is None or not match_key:
            continue

        key = (team_number, match_key)
        misc = ((document.get("data") or {}).get("misc") or {})
        comments = str(misc.get("comments") or "").strip()
        report_order = _document_order_key(document)

        incident = incidents.setdefault(
            key,
            {
                "incident_id": f"{event}:{team_number}:{match_key}",
                "event": event,
                "team": team_number,
                "match": str(document.get("match")),
                "match_key": match_key,
                "report_count": 0,
                "death_reports": [],
                "latest_death_order": report_order,
                "latest_followup_order": (
                    datetime.min.replace(tzinfo=timezone.utc),
                    0,
                ),
                "followup_document": None,
            },
        )

        incident["report_count"] += 1
        incident["death_reports"].append({
            "comments": comments,
            "scout_name": _public_scout_name(scout_info),
            "scout_username": str(scout_info.get("username") or ""),
            "submitted_at": document.get("submitted_at"),
        })

        if report_order > incident["latest_death_order"]:
            incident["latest_death_order"] = report_order
            incident["match"] = str(document.get("match"))

    if not incidents:
        return []

    followup_query = dict(query)
    for document in FollowUpCollection.find(followup_query):
        scout_info = (
            document.get("scout_info")
            or document.get("scoutInfo")
            or {}
        )
        if not _scout_info_matches_member_sets(
            scout_info,
            member_user_ids,
            member_usernames,
        ):
            continue

        team_number = normalize_team_number(document.get("team"))
        match_key = (
            document.get("match_key")
            or normalize_match_key(document.get("match"))
        )
        key = (team_number, str(match_key))

        incident = incidents.get(key)
        if incident is None:
            continue

        followup_order = _document_order_key(document)
        if followup_order >= incident["latest_followup_order"]:
            incident["latest_followup_order"] = followup_order
            incident["followup_document"] = document

    public_incidents = []
    for incident in incidents.values():
        resolved = (
            incident["followup_document"] is not None
            and incident["latest_followup_order"]
            >= incident["latest_death_order"]
        )

        death_reports = incident["death_reports"]
        death_reports.sort(
            key=lambda item: str(item.get("submitted_at") or "")
        )

        public_incidents.append({
            "incident_id": incident["incident_id"],
            "event": incident["event"],
            "team": incident["team"],
            "match": incident["match"],
            "match_key": incident["match_key"],
            "resolved": resolved,
            "report_count": incident["report_count"],
            "death_reports": death_reports,
            "followup": (
                _followup_public_data(incident["followup_document"])
                if resolved
                else None
            ),
        })

    public_incidents.sort(
        key=lambda item: (
            item["team"],
            match_sort_key(item["match"]),
        )
    )
    return public_incidents


def get_pending_followup_teams(group_id: str, event: str) -> set[int]:
    return {
        incident["team"]
        for incident in build_death_incidents(group_id, event)
        if not incident.get("resolved", False)
    }


def get_pending_followup_counts(group_id: str, event: str) -> dict[int, int]:
    counts: dict[int, int] = {}

    for incident in build_death_incidents(group_id, event):
        if incident.get("resolved", False):
            continue

        team = incident["team"]
        counts[team] = counts.get(team, 0) + 1

    return counts


def _followup_status_counts(data: list[dict]) -> dict:
    complete_count = sum(
        1 for entry in data if entry.get("followups", True)
    )
    needed_count = len(data) - complete_count

    return {
        "followup_complete_count": complete_count,
        "followup_needed_count": needed_count,
        "all_followups_complete": needed_count == 0,
    }

def get_collection_team_numbers(
    collection,
    group_id: str,
    event: str,
) -> set[int]:
    """
    Return every normalized team number stored in a collection
    for the specified group and event.

    Supports older and newer group ID field names.
    """
    group_id = str(group_id)
    event = str(event)

    team_numbers: set[int] = set()

    documents = collection.find(
        {
            "event": event,
            "$or": [
                {"groupId": group_id},
                {"groupID": group_id},
                {"group_id": group_id},
            ],
        },
        {
            "_id": 0,
            "team": 1,
        },
    )

    for document in documents:
        team_number = normalize_team_number(
            document.get("team")
        )

        if team_number is not None:
            team_numbers.add(team_number)

    return team_numbers
def rebuild_group_pit_status(group_id: str, event: str):
    group_id = str(group_id)
    event = str(event)

    group = GroupsCollection.find_one(
        {"group_id": group_id},
        {"_id": 1},
    )

    if not group:
        raise HTTPException(
            status_code=404,
            detail="Group not found",
        )

    existing_document = GroupPitStatus.find_one(
        {
            "group_id": group_id,
            "event_key": event,
        },
        {"_id": 0, "data": 1},
    ) or {}

    existing_teams = {
        team_number
        for entry in existing_document.get("data", [])
        if (
            team_number := normalize_team_number(entry.get("team"))
        ) is not None
    }

    pending_followup_counts = get_pending_followup_counts(group_id, event)
    pending_followup_teams = set(pending_followup_counts)

    event_teams = set(get_event_team_numbers(event))
    completed_teams = get_completed_pit_teams(group_id, event)
    match_scouting_teams = get_collection_team_numbers(
        MatchScoutingCollection,
        group_id,
        event,
    )
    followup_teams = get_collection_team_numbers(
        FollowUpCollection,
        group_id,
        event,
    )

    all_teams = sorted(
        event_teams
        | completed_teams
        | match_scouting_teams
        | followup_teams
        | existing_teams
        | pending_followup_teams
    )

    data = [
        {
            "team": team,
            "pitscouting": team in completed_teams,
            "followups": team not in pending_followup_teams,
            "pending_followup_count": pending_followup_counts.get(team, 0),
        }
        for team in all_teams
    ]

    completed_count = sum(
        1 for entry in data if entry["pitscouting"]
    )
    total_count = len(data)
    followup_counts = _followup_status_counts(data)

    document = {
        "group_id": group_id,
        "groupId": group_id,
        "event_key": event,
        "event": event,
        "data": data,
        "completed_count": completed_count,
        "remaining_count": total_count - completed_count,
        "total_count": total_count,
        "all_complete": total_count > 0 and completed_count == total_count,
        **followup_counts,
        "updated_at": now_utc(),
    }

    GroupPitStatus.update_one(
        {
            "group_id": group_id,
            "event_key": event,
        },
        {"$set": document},
        upsert=True,
    )

    return document


def refresh_group_pit_status_for_event(event: str):
    refreshed = 0

    for group_id in group_ids_for_event(event):
        if not GroupsCollection.find_one(
            {"group_id": group_id},
            {"_id": 1},
        ):
            continue

        try:
            rebuild_group_pit_status(group_id, event)
            refreshed += 1
        except Exception as error:
            print(
                f"Skipping GroupPitScoutingStatus rebuild for "
                f"{group_id}/{event}: {error}"
            )

    return refreshed


def save_group_stats(
    group_id: str,
    event: str,
    stats_data,
    scout_document_count: int,
    member_count: int,
):
    GroupStatsCollection.update_one(
        {
            "group_id": group_id,
            "event_key": event,
        },
        {
            "$set": {
                # Keep both forms because match scouting currently uses
                # groupId while the rest of the backend uses group_id.
                "group_id": group_id,
                "groupId": group_id,
                "event_key": event,
                "data": stats_data,
                "scout_document_count": scout_document_count,
                "member_count": member_count,
                "cache_version": GROUP_STATS_CACHE_VERSION,
                "updated_at": now_utc(),
            }
        },
        upsert=True,
    )


def rebuild_group_stats(
    group_id: str,
    event: str,
    matches=None,
    rankings_data=None,
):
    group = GroupsCollection.find_one(
        {"group_id": group_id},
        {"_id": 0, "group_id": 1},
    )

    if not group:
        raise HTTPException(
            status_code=404,
            detail="Group not found",
        )

    if matches is None or rankings_data is None:
        cached_matches, cached_rankings = (
            get_cached_event_analysis_inputs(event)
        )

        if matches is None:
            matches = cached_matches

        if rankings_data is None:
            rankings_data = cached_rankings

    scout_data = get_group_match_scouting(
        group_id=group_id,
        event=event,
    )
    members, _, _ = get_group_member_identity_sets(group_id)

    stats_data = linreg(
        TBAdata=matches,
        Scoutdata=scout_data,
        matches=matches,
        rankings_data=rankings_data,
    )

    save_group_stats(
        group_id=group_id,
        event=event,
        stats_data=stats_data,
        scout_document_count=len(scout_data),
        member_count=len(members),
    )

    return stats_data


def group_ids_for_event(event: str) -> list[str]:
    group_ids = {
        str(group_id)
        for group_id in GroupsCollection.distinct(
            "group_id",
            {"events": event},
        )
        if group_id
    }

    # Also rebuild groups with existing scouting data, even if an older
    # group document did not yet store the event in its events array.
    group_ids.update({
        str(group_id)
        for group_id in MatchScoutingCollection.distinct(
            "groupId",
            {"event": event},
        )
        if group_id
    })
    group_ids.update({
        str(group_id)
        for group_id in PitScoutingCollection.distinct(
            "groupId",
            {"event": event},
        )
        if group_id
    })
    group_ids.update({
        str(group_id)
        for group_id in PitScoutingCollection.distinct(
            "group_id",
            {"event": event},
        )
        if group_id
    })
    group_ids.update({
        str(group_id)
        for group_id in FollowUpCollection.distinct(
            "groupId",
            {"event": event},
        )
        if group_id
    })
    group_ids.update({
        str(group_id)
        for group_id in FollowUpCollection.distinct(
            "groupID",
            {"event": event},
        )
        if group_id
    })

    return sorted(group_ids)


def refresh_group_stats_for_event(
    event: str,
    matches,
    rankings_data,
):
    refreshed = 0

    for group_id in group_ids_for_event(event):
        # Ignore scouting records whose group was deleted.
        if not GroupsCollection.find_one(
            {"group_id": group_id},
            {"_id": 1},
        ):
            continue

        try:
            rebuild_group_stats(
                group_id=group_id,
                event=event,
                matches=matches,
                rankings_data=rankings_data,
            )
            refreshed += 1
        except Exception as error:
            print(
                f"Skipping GroupStats rebuild for "
                f"{group_id}/{event}: {error}"
            )

    return refreshed


def collection_data(collection, query):
    document = collection.find_one(query, {"_id": 0})
    if document is None:
        return None

    return document.get("data")


def save_collection_data(collection, query, data):
    collection.update_one(
        query,
        {
            "$set": {
                **query,
                "data": data,
                "updated_at": now_utc(),
            }
        },
        upsert=True,
    )


def format_search_key(event, year: str = YEAR):
    event_year = str(event.get("year", year))
    event_key = event.get("key", "")
    event_code = event_key.removeprefix(event_year)

    return {
        "key": event_key,
        "event_code": event_code,
        "display": f"{event_year} {event.get('name', event_key)} [{event_code}]",
        "page": f"/event/{event_code}",
        "start": event.get("start_date"),
        "end": event.get("end_date"),
    }


def save_etag(cache_key: str, etag: str | None):
    if not etag:
        return

    ETagsCollection.update_one(
        {"key": cache_key},
        {
            "$set": {
                "key": cache_key,
                "etag": etag,
                "updated_at": now_utc(),
            }
        },
        upsert=True,
    )


def fetch_tba_json(path: str, cache_key: str, cached_data=None):
    headers = dict(HEADERS)
    etag_document = ETagsCollection.find_one({"key": cache_key}, {"_id": 0})

    if etag_document and etag_document.get("etag"):
        headers["If-None-Match"] = etag_document["etag"]

    response = requests.get(TBA_API_URL + path, headers=headers, timeout=20)

    if response.status_code == 304 and cached_data is not None:
        return cached_data, False

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"TBA Error {response.status_code}: {response.text}",
        )

    data = response.json()
    save_etag(cache_key, response.headers.get("ETag"))
    return data, True


def get_events_from_db(year: str = YEAR):
    query = {"year": str(year)}
    cached_events = collection_data(EventsCollection, query)

    if cached_events is not None:
        return cached_events

    events, _ = fetch_tba_json(f"events/{year}", f"events/{year}")
    save_collection_data(EventsCollection, query, events)
    return events


def fetch_events(year: str = YEAR):
    query = {"year": str(year)}
    cached_events = collection_data(EventsCollection, query)
    events, changed = fetch_tba_json(
        f"events/{year}",
        f"events/{year}",
        cached_data=cached_events,
    )

    if changed or cached_events is None:
        save_collection_data(EventsCollection, query, events)

    return events

def generate_join_code(length=6):
    return ''.join(
        random.choices(
            string.ascii_uppercase + string.digits,
            k=length
        )
    )

def seed_event_etags(events):
    for event in events:
        event_key = event.get("key")
        if not event_key:
            continue

        existing = ETagsCollection.find_one({"key": event_key}, {"_id": 0}) or {}

        ETagsCollection.update_one(
            {"key": event_key},
            {
                "$set": {
                    "key": event_key,
                    "event": event,
                    "year": str(event.get("year", YEAR)),
                    "updated_at": now_utc(),
                },
                "$setOnInsert": {
                    "etag": "",
                    "up_to_date": False,
                },
            },
            upsert=True,
        )


        if existing.get("teams") is None:
            try:
                team_resp = requests.get(
                    f"{TBA_API_URL}/event/{event_key}/teams",
                    headers=HEADERS,
                    timeout=20,
                )

                if team_resp.status_code == 200:
                    teams_json = team_resp.json()

                    team_keys = [
                        team["key"]
                        for team in teams_json
                        if "key" in team
                    ]

                    ETagsCollection.update_one(
                        {"key": event_key},
                        {
                            "$set": {
                                "teams": team_keys,
                                "teams_etag": team_resp.headers.get("ETag", "")
                            }
                        }
                    )

            except Exception as e:
                print(f"Teams fetch failed for {event_key}: {e}")

        if existing.get("event") != event:
            ETagsCollection.update_one(
                {"key": event_key},
                {"$set": {"up_to_date": False}},
            )

        # Rebuild each group's checklist after the event team list is known.
        refresh_group_pit_status_for_event(event_key)


def save_event_stats(event: str, stats_data):
    StatsCollection.update_one(
        {"event_key": event},
        {
            "$set": {
                "event_key": event,
                "data": stats_data,
                "cache_version": STATS_CACHE_VERSION,
                "updated_at": now_utc(),
            }
        },
        upsert=True,
    )


def save_tba_matches(event: str, matches):
    for match in matches:
        TBACollection.update_one(
            {
                "event_key": event,
                "match_key": match["key"],
            },
            {
                "$set": {
                    **match,
                    "event_key": event,
                    "updated_at": now_utc(),
                }
            },
            upsert=True,
        )


def save_event_predictions(event: str, predictions_data):
    PredictionCollection.update_one(
        {"event_key": event},
        {
            "$set": {
                "event_key": event,
                "data": predictions_data,
                "cache_version": PREDICTION_CACHE_VERSION,
                "updated_at": now_utc(),
            }
        },
        upsert=True,
    )


def refresh_event_predictions(event: str, matches):
    """
    Rebuild predictions from the exact TBA match list used for this
    event's stats refresh, then save them immediately.
    """

    predictions_data = predict_matches(
        event,
        matches=matches,
    )
    save_event_predictions(event, predictions_data)

    return predictions_data


def build_and_save_event(event: str, matches, rankings_data):
    """
    Rebuild one event's cached matches, stats, and predictions.

    The order is intentional:
      1. Save the newest TBA matches.
      2. Calculate and save the newest stats.
      3. Immediately regenerate and save predictions.

    This ensures that every successful stats refresh also refreshes the
    predictions during the same cache update.
    """

    # Save the exact match data used by this cache update first.
    save_tba_matches(event, matches)

    stats_data = linreg_TBA(
        event,
        matches=matches,
        rankings_data=rankings_data,
    )
    save_event_stats(event, stats_data)

    # Predictions are refreshed every time the stats are refreshed.
    predictions_data = refresh_event_predictions(event, matches)

    # Each group receives the same TBA regression, combined only with
    # scouting records submitted by that group's current members.
    refresh_group_stats_for_event(
        event=event,
        matches=matches,
        rankings_data=rankings_data,
    )

    return stats_data, predictions_data


def tba_get(path: str, headers):
    response = requests.get(TBA_API_URL + path, headers=headers, timeout=20)
    if response.status_code not in [200, 304]:
        raise HTTPException(
            status_code=502,
            detail=f"TBA Error {response.status_code}: {response.text}",
        )

    return response


def update_event_cache(event_document):
    event_key = event_document["key"]
    headers = dict(HEADERS)

    if event_document.get("etag"):
        headers["If-None-Match"] = event_document["etag"]

    match_response = tba_get(
        f"event/{event_key}/matches",
        headers,
    )

    stats_document = StatsCollection.find_one(
        {"event_key": event_key},
        {
            "_id": 1,
            "cache_version": 1,
        },
    )

    prediction_document = PredictionCollection.find_one(
        {"event_key": event_key},
        {
            "_id": 1,
            "cache_version": 1,
        },
    )

    stats_are_current = (
        stats_document is not None
        and stats_document.get("cache_version")
        == STATS_CACHE_VERSION
    )

    predictions_are_current = (
        prediction_document is not None
        and prediction_document.get("cache_version")
        == PREDICTION_CACHE_VERSION
    )

    # Only skip rebuilding if both cached structures
    # use the latest versions.
    if (
        match_response.status_code == 304
        and event_document.get("up_to_date")
        and stats_are_current
        and predictions_are_current
    ):
        cached_matches, cached_rankings = (
            get_cached_event_analysis_inputs(event_key)
        )
        refresh_group_stats_for_event(
            event=event_key,
            matches=cached_matches,
            rankings_data=cached_rankings,
        )
        return

    # TBA data did not change, but our local calculation
    # code or cache format changed. Fetch the data again
    # without If-None-Match so it can be recalculated.
    if match_response.status_code == 304:
        match_response = tba_get(
            f"event/{event_key}/matches",
            dict(HEADERS),
        )

    matches = match_response.json()

    ranking_response = tba_get(
        f"event/{event_key}/rankings",
        dict(HEADERS),
    )

    rankings_data = (
        ranking_response.json()
        if ranking_response.status_code == 200
        else {"rankings": []}
    )

    stats_data, predictions_data = build_and_save_event(
        event_key,
        matches,
        rankings_data,
    )

    if stats_data:
        first_team = stats_data[0]

        print(
            f"Rebuilt stats for {event_key}: "
            f"{len(stats_data)} teams, "
            f"MatchHistory present: "
            f"{'MatchHistory' in first_team}"
        )

    updates = {
        "up_to_date": True,
        "rankings": rankings_data.get(
            "rankings",
            [],
        ),
        "updated_at": now_utc(),
    }

    if match_response.status_code == 200:
        updates["etag"] = (
            match_response.headers.get(
                "ETag",
                "",
            )
        )

    ETagsCollection.update_one(
        {"key": event_key},
        {"$set": updates},
    )

def update_database(year: str = YEAR):
    events = fetch_events(year)
    seed_event_etags(events)

    event_documents = list(ETagsCollection.find({"year": str(year)}, {"_id": 0}))

    for event_document in event_documents:
        try:
            update_event_cache(event_document)
        except Exception as error:
            print(f"Skipping {event_document.get('key')}: {error}")





def get_keycloak_admin_token() -> str:
    token_url = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_MASTER_REALM}/protocol/openid-connect/token"
    response = requests.post(
        token_url,
        data={
            "grant_type": "password",
            "client_id": KEYCLOAK_ADMIN_CLIENT_ID,
            "username": KEYCLOAK_ADMIN_USERNAME,
            "password": KEYCLOAK_ADMIN_PASSWORD,
        },
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=20,
    )

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Keycloak admin login failed: {response.status_code} {response.text}",
        )

    token_data = response.json()
    return token_data.get("access_token")


def _extract_group_id_from_location(location: str | None) -> str | None:
    if not location:
        return None
    return location.rstrip('/').split('/')[-1]


def find_keycloak_user_id(username: str, token: str) -> str | None:
    users_url = f"{KEYCLOAK_BASE_URL}/admin/realms/{KEYCLOAK_REALM}/users"
    response = requests.get(
        users_url,
        params={"username": username},
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        timeout=20,
    )

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Keycloak user lookup failed: {response.status_code} {response.text}",
        )

    users = response.json()
    if not users:
        return None

    return users[0].get("id")


def assign_user_to_group(user_id: str, group_id: str, token: str):
    group_membership_url = (
        f"{KEYCLOAK_BASE_URL}/admin/realms/{KEYCLOAK_REALM}/users/{user_id}/groups/{group_id}"
    )
    response = requests.put(
        group_membership_url,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        timeout=20,
    )

    if response.status_code not in [204, 201]:
        raise HTTPException(
            status_code=502,
            detail=f"Keycloak user group assignment failed: {response.status_code} {response.text}",
        )


def create_keycloak_group(name: str, token: str):
    group_url = f"{KEYCLOAK_BASE_URL}/admin/realms/{KEYCLOAK_REALM}/groups"
    response = requests.post(
        group_url,
        json={"name": name},
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        timeout=20,
    )

    if response.status_code not in [201, 204]:
        raise HTTPException(
            status_code=502,
            detail=f"Keycloak group creation failed: {response.status_code} {response.text}",
        )

    return _extract_group_id_from_location(response.headers.get("Location"))


@app.post("/groups", tags=["groups"])
def api_create_group(group: GroupCreateRequest):
    admin_token = get_keycloak_admin_token()

    group_id = create_keycloak_group(
        group.name,
        admin_token
    )

    join_code = generate_join_code()

    # Save group metadata
    GroupsCollection.insert_one({
        "group_id": group_id,
        "name": group.name,
        "join_code": join_code,
        "created_at": now_utc()
    })

    owner_user_id = None

    # If creator exists, assign as OWNER
    if group.username:
        owner_user_id = find_keycloak_user_id(group.username, admin_token)

        if owner_user_id:
            assign_user_to_group(owner_user_id, group_id, admin_token)

            GroupMembersCollection.insert_one({
                "group_id": group_id,
                "user_id": owner_user_id,
                "username": group.username,
                "role": "owner",
                "joined_at": now_utc()
            })

    return {
        "success": True,
        "group_id": group_id,
        "join_code": join_code
    }

def format_datetime_utc(value: datetime) -> str:
    return value.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


def set_cache_status(
    year: str,
    status: str,
    error: str | None = None,
    started_at: datetime | None = None,
    completed_at: datetime | None = None,
    next_update_at: datetime | None = None,
):
    current_time = now_utc()

    update = {
        "year": str(year),
        "status": status,
        "update_interval_seconds": CACHE_UPDATE_INTERVAL_SECONDS,
        "updated_at": current_time,
        "updated_at_display": format_datetime_utc(current_time),
    }

    if started_at is not None:
        update["started_at"] = started_at
        update["started_at_display"] = format_datetime_utc(started_at)

    if completed_at is not None:
        update["last_completed_at"] = completed_at
        update["last_completed_at_display"] = format_datetime_utc(completed_at)

    if next_update_at is not None:
        update["next_update_at"] = next_update_at
        update["next_update_at_display"] = format_datetime_utc(next_update_at)

    database_update = {"$set": update}
    fields_to_unset = {}

    if error:
        update["error"] = error
    else:
        # Remove an old error after a later update succeeds or starts again.
        fields_to_unset["error"] = ""

    if status == "running":
        # The previously scheduled time is no longer relevant once this run starts.
        fields_to_unset["next_update_at"] = ""
        fields_to_unset["next_update_at_display"] = ""

    if fields_to_unset:
        database_update["$unset"] = fields_to_unset

    CacheStatusCollection.update_one(
        {"year": str(year)},
        database_update,
        upsert=True,
    )


def run_update_database_background(year: str = YEAR):
    while True:
        started_at = now_utc()
        set_cache_status(
            year,
            "running",
            started_at=started_at,
        )

        try:
            update_database(year)

            completed_at = now_utc()
            next_update_at = completed_at + timedelta(
                seconds=CACHE_UPDATE_INTERVAL_SECONDS
            )

            set_cache_status(
                year,
                "done",
                completed_at=completed_at,
                next_update_at=next_update_at,
            )

            print(
                f"Cache update completed at "
                f"{format_datetime_utc(completed_at)}. "
                f"Next update: {format_datetime_utc(next_update_at)}"
            )

        except Exception as error:
            failed_at = now_utc()
            next_update_at = failed_at + timedelta(
                seconds=CACHE_UPDATE_INTERVAL_SECONDS
            )

            set_cache_status(
                year,
                "error",
                error=str(error),
                next_update_at=next_update_at,
            )

            print(
                f"Background cache update failed at "
                f"{format_datetime_utc(failed_at)}: {error}. "
                f"Retrying at {format_datetime_utc(next_update_at)}"
            )

        # The next update starts only after the previous one has fully finished.
        sleep(CACHE_UPDATE_INTERVAL_SECONDS)


def start_background_update(year: str = YEAR):
    global cache_update_thread

    with cache_update_lock:
        if cache_update_thread is not None and cache_update_thread.is_alive():
            return

        cache_update_thread = Thread(
            target=run_update_database_background,
            args=(year,),
            daemon=True,
        )
        cache_update_thread.start()


def get_stats_from_db(
    event: str,
    username: str | None = None,
):
    """
    Returns group-specific stats when:

    1. A username was provided.
    2. The user belongs to a group.
    3. That group has the requested event.
    4. GroupStats contains non-empty data for that event.

    Otherwise, returns the regular event stats.
    """

    if username:
        username = username.strip()

        member = GroupMembersCollection.find_one(
            {
                "username": username,
            },
            {
                "_id": 0,
                "group_id": 1,
            },
        )

        if member:
            group_id = member.get("group_id")

            group_has_event = GroupsCollection.find_one(
                {
                    "group_id": group_id,
                    "events": event,
                },
                {
                    "_id": 1,
                },
            )

            if group_has_event:
                group_stats_document = (
                    GroupStatsCollection.find_one(
                        {
                            "group_id": group_id,
                            "event_key": event,
                        },
                        {
                            "_id": 0,
                            "data": 1,
                        },
                    )
                )

                if group_stats_document:
                    group_stats = (
                        group_stats_document.get("data")
                    )

                    if (
                        isinstance(group_stats, list)
                        and len(group_stats) > 0
                    ):
                        return group_stats

    # Logged out, no group, event not added to group,
    # or no group scouting data.
    return collection_data(
        StatsCollection,
        {
            "event_key": event,
        },
    )


def get_group_stats_from_db(group_id: str, event: str):
    return collection_data(
        GroupStatsCollection,
        {
            "group_id": group_id,
            "event_key": event,
        },
    )


def get_predictions_from_db(event: str):
    return collection_data(PredictionCollection, {"event_key": event})
    
def get_user_role(group_id: str, user_id: str):
    member = GroupMembersCollection.find_one({
        "group_id": group_id,
        "user_id": user_id
    })

    if not member:
        return None

    return member.get("role")

def require_role(group_id: str, user_id: str, allowed_roles: list):
    role = get_user_role(group_id, user_id)

    if role is None:
        raise HTTPException(
            status_code=403,
            detail="Not a group member"
        )

    if role not in allowed_roles:
        raise HTTPException(
            status_code=403,
            detail="Insufficient permissions"
        )
    
def can_manage(actor_role: str, target_role: str):
    return ROLE_PRIORITY.get(actor_role, 0) > ROLE_PRIORITY.get(target_role, 0)
