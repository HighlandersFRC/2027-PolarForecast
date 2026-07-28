from dataclasses import dataclass
from typing import Any, Callable

from fastapi import APIRouter, HTTPException


@dataclass(frozen=True)
class DataDependencies:
    etags_collection: Any
    tba_collection: Any
    stats_collection: Any
    group_stats_collection: Any
    cache_status_collection: Any
    year: str
    get_stats_from_db: Callable[..., Any]
    require_username_group_member: Callable[..., Any]
    rebuild_group_stats: Callable[..., Any]
    get_predictions_from_db: Callable[..., Any]
    get_events_from_db: Callable[..., Any]
    format_search_key: Callable[..., Any]


def create_data_router(dependencies: DataDependencies) -> APIRouter:
    router = APIRouter()

    @router.get("/", tags=["default"])
    def default():
        return {"Polar", "Forecast"}

    @router.get("/{event}/teams", tags=["stats"])
    def teams_event(event: str):
        document = dependencies.etags_collection.find_one(
            {"key": event},
            {"_id": 0, "teams": 1},
        )

        if not document:
            raise HTTPException(status_code=404, detail="Event not found")

        return document["teams"]

    @router.get("/{event}/{match}/teams", tags=["stats"])
    def teams(event: str, match: int):
        alliances = dependencies.tba_collection.find_one(
            {"event_key": event, "match_key": f"{event}_qm{match}"},
            {"_id": 0, "alliances": 1},
        )

        if not alliances:
            raise HTTPException(status_code=404, detail="Match not found")

        return {
            "blue_teams": alliances["alliances"]["blue"]["team_keys"],
            "red_teams": alliances["alliances"]["red"]["team_keys"],
        }

    @router.get("/{event}/event/{team}/team", tags=["stats"])
    def team_stats(event: str, team: str):
        document = dependencies.stats_collection.find_one(
            {"event_key": event},
            {"_id": 0, "data": 1},
        )

        if not document or "data" not in document:
            raise HTTPException(
                status_code=404,
                detail="No stats found for event",
            )

        try:
            team_number = int(team.replace("frc", "").strip())
        except ValueError as error:
            raise HTTPException(
                status_code=400,
                detail="Invalid team format",
            ) from error

        for entry in document["data"]:
            if entry.get("Team") == team_number:
                return {
                    "event": event,
                    "team": team_number,
                    "stats": entry,
                }

        raise HTTPException(
            status_code=404,
            detail=f"Team {team_number} not found in event {event}",
        )

    @router.get("/{event}/stats", tags=["stats"])
    def stats(event: str, username: str | None = None):
        data = dependencies.get_stats_from_db(
            event=event,
            username=username,
        )

        if data is None:
            raise HTTPException(
                status_code=404,
                detail="Stats are not cached for this event yet",
            )

        return data

    @router.get(
        "/groups/{group_id}/events/{event}/stats",
        tags=["stats", "groups"],
    )
    def group_event_stats(group_id: str, event: str, username: str):
        dependencies.require_username_group_member(group_id, username)

        query = {"group_id": group_id, "event_key": event}
        document = dependencies.group_stats_collection.find_one(
            query,
            {"_id": 0},
        )

        if document is None:
            dependencies.rebuild_group_stats(group_id, event)
            document = dependencies.group_stats_collection.find_one(
                query,
                {"_id": 0},
            )

        if document is None:
            raise HTTPException(
                status_code=404,
                detail="Group stats are not available for this event yet",
            )

        return document

    @router.get(
        "/groups/{group_id}/events/{event}/teams/{team}/stats",
        tags=["stats", "groups"],
    )
    def group_event_team_stats(
        group_id: str,
        event: str,
        team: int,
        username: str,
    ):
        dependencies.require_username_group_member(group_id, username)

        query = {"group_id": group_id, "event_key": event}
        document = dependencies.group_stats_collection.find_one(
            query,
            {"_id": 0, "data": 1},
        )

        if document is None:
            dependencies.rebuild_group_stats(group_id, event)
            document = dependencies.group_stats_collection.find_one(
                query,
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

    @router.get("/{event}/predictions", tags=["stats"])
    def predictions(event: str):
        data = dependencies.get_predictions_from_db(event)

        if data is None:
            raise HTTPException(
                status_code=404,
                detail="Predictions are not cached for this event yet",
            )

        return data

    @router.get("/searchkeys", tags=["miscellaneous"])
    def search_keys(year: str = dependencies.year):
        events = dependencies.get_events_from_db(year)
        return {
            "data": [
                dependencies.format_search_key(event, year)
                for event in events
            ]
        }

    @router.get("/cache/status", tags=["miscellaneous"])
    def cache_status(year: str = dependencies.year):
        status = dependencies.cache_status_collection.find_one(
            {"year": str(year)},
            {"_id": 0},
        )

        if status is None:
            return {"year": str(year), "status": "not_started"}

        return status

    return router
