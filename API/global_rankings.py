"""Public season rankings, using each team's latest event OPR unchanged."""

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from math import isfinite
from threading import Lock
from uuid import uuid4


class RankingSnapshotExpired(Exception):
    pass


class GlobalRankings:
    refresh_seconds = 300
    snapshot_seconds = 1800

    def __init__(self, stats, events, etags, fetch_json, year, stats_version, clock=None):
        self.stats = stats
        self.events = events
        self.etags = etags
        self.fetch_json = fetch_json
        self.year = int(year)
        self.stats_version = stats_version
        self.clock = clock or (lambda: datetime.now(timezone.utc))
        self._lock = Lock()
        self._snapshots = {}
        self._current = None

    def _names(self, teams, now):
        """Cache bulk name pages daily; avatars are loaded only for visible rows."""
        pages = sorted({team // 500 for team in teams})
        today = now.date().isoformat()

        def load(page):
            key = f"ranking-team-names:{self.year}:{page}"
            cached = self.etags.find_one({"key": key}, {"_id": 0}) or {}
            rows = cached.get("teams", [])
            if cached.get("date") != today:
                fresh = self.fetch_json(
                    f"teams/{self.year}/{page}/simple",
                    default=None, expected_type=list, timeout=6,
                )
                if fresh is None:
                    fresh = self.fetch_json(
                        f"teams/{self.year}/{page}/simple",
                        default=None, expected_type=list, timeout=6,
                    )
                if fresh is not None:
                    rows = fresh
                    self.etags.update_one(
                        {"key": key},
                        {"$set": {"teams": rows, "date": today}},
                        upsert=True,
                    )
            return rows

        names = {}
        with ThreadPoolExecutor(max_workers=6) as executor:
            for rows in executor.map(load, pages):
                for row in rows:
                    team = row.get("team_number")
                    if isinstance(team, int):
                        names[team] = row.get("nickname") or row.get("name") or f"Team {team}"
        return names

    def _build(self, now):
        document = self.events.find_one({"year": str(self.year)}, {"_id": 0, "data": 1}) or {}
        metadata = {event["key"]: event for event in document.get("data", []) if event.get("key")}
        # Event dates, not the order in which the cache happened to refresh,
        # decide which event is the latest for a team.
        latest = {}
        documents = self.stats.find(
            {"event_key": {"$regex": f"^{self.year}"}, "cache_version": self.stats_version},
            {"_id": 0, "event_key": 1, "data.Team": 1, "data.totalOPR": 1,
             "data.autoOPR": 1, "data.teleopOPR": 1, "data.MatchesPlayed": 1},
        )
        for stats in documents:
            event_key = stats.get("event_key", "")
            event = metadata.get(event_key, {})
            date = event.get("end_date") or event.get("start_date")
            if not date:
                continue
            order = (date, event.get("start_date") or date, event_key)
            for row in stats.get("data", []):
                team, opr = row.get("Team"), row.get("totalOPR")
                if (isinstance(team, bool) or not isinstance(team, int) or team <= 0
                        or isinstance(opr, bool) or not isinstance(opr, (int, float))
                        or not isfinite(opr) or row.get("MatchesPlayed", 0) <= 0):
                    continue
                if team not in latest or order > latest[team][0]:
                    phases = {}
                    for phase in ("auto", "teleop"):
                        value = row.get(f"{phase}OPR")
                        phases[phase] = value if (
                            not isinstance(value, bool)
                            and isinstance(value, (int, float)) and isfinite(value)
                        ) else None
                    latest[team] = (order, {
                        "team": team, "opr": opr, **phases, "event_key": event_key,
                        "event_name": event.get("name") or event_key,
                        "event_date": date,
                    })

        names = self._names(latest, now)
        rows = sorted((value[1] for value in latest.values()), key=lambda row: (-row["opr"], row["team"]))
        for rank, row in enumerate(rows, 1):
            row.update(rank=rank, name=names.get(row["team"], f"Team {row['team']}"))
        ranges = {}
        for metric in ("rank", "opr", "auto", "teleop"):
            values = [row[metric] for row in rows if row[metric] is not None]
            if values:
                ranges[metric] = {"min": min(values), "max": max(values)}
        return {"id": uuid4().hex, "at": now, "rows": rows, "ranges": ranges}

    def page(self, offset=0, limit=50, query="", snapshot=None):
        now = self.clock()
        with self._lock:
            self._snapshots = {
                key: value for key, value in self._snapshots.items()
                if (now - value["at"]).total_seconds() < self.snapshot_seconds
            }
            if snapshot:
                selected = self._snapshots.get(snapshot)
                if selected is None:
                    raise RankingSnapshotExpired()
            else:
                selected = self._snapshots.get(self._current)
                if selected is None or (now - selected["at"]).total_seconds() >= self.refresh_seconds:
                    selected = self._build(now)
                    self._current = selected["id"]
                    self._snapshots[self._current] = selected

        text = query.strip().casefold()
        if text.startswith("frc") and text[3:].strip().isdigit():
            text = text[3:].strip()
        rows = selected["rows"]
        filtered = [row for row in rows if text in str(row["team"]) or text in row["name"].casefold()] if text else rows
        limit = min(50, max(1, limit))
        page = filtered[offset:offset + limit]
        next_offset = offset + len(page)
        return {
            "year": self.year, "data": page, "total": len(rows), "matched": len(filtered),
            "offset": offset, "next_offset": next_offset if next_offset < len(filtered) else None,
            "snapshot": selected["id"], "updated_at": selected["at"].isoformat(),
            "ranges": selected["ranges"],
            "refresh_interval_seconds": self.refresh_seconds,
        }
