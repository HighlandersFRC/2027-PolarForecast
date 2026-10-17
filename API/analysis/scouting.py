"""Summarize scouting reports and apply the group-only fuel correction."""

import re
from collections import defaultdict
from typing import Any, Optional

import numpy as np

MAX_SCOUTED_AUTO_FUEL = 300.0
MAX_SCOUTED_TELEOP_FUEL = 1000.0
MAX_SCOUTING_FUEL_WEIGHT = 0.30


def _safe_float(value: Any) -> Optional[float]:
    if isinstance(value, bool):
        return None

    if isinstance(value, (int, float, np.number)):
        number = float(value)
        return number if np.isfinite(number) else None

    if isinstance(value, str):
        try:
            number = float(value.strip())
            return number if np.isfinite(number) else None
        except ValueError:
            return None

    return None


def _safe_scouted_fuel(
    value: Any,
    *,
    maximum: float,
) -> Optional[float]:
    """Parse plausible scouting fuel while quarantining legacy outliers."""
    number = _safe_float(value)
    if number is None or number < 0 or number > maximum:
        return None
    return number


def _safe_int(value: Any) -> Optional[int]:
    if isinstance(value, bool):
        return None

    if isinstance(value, (int, np.integer)):
        return int(value)

    if isinstance(value, float) and value.is_integer():
        return int(value)

    if isinstance(value, str):
        match = re.search(r"\d+", value)
        if match:
            return int(match.group())

    return None


def _safe_bool(value: Any) -> Optional[bool]:
    if isinstance(value, bool):
        return value

    if isinstance(value, (int, float)) and value in (0, 1):
        return bool(value)

    if isinstance(value, str):
        normalized = value.strip().lower()

        if normalized in {"true", "yes", "y", "1"}:
            return True

        if normalized in {"false", "no", "n", "0"}:
            return False

    return None


def rankings(rankings_data: Any, team_key: str) -> Optional[int]:
    if not isinstance(rankings_data, dict):
        return None

    ranking_rows = rankings_data.get("rankings", [])

    if not isinstance(ranking_rows, list):
        return None

    for ranking_row in ranking_rows:
        if (
            isinstance(ranking_row, dict)
            and ranking_row.get("team_key") == team_key
        ):
            return _safe_int(ranking_row.get("rank"))

    return None


def ranking_points(rankings_data: Any, team_key: str) -> Optional[float]:
    """Read total RP from TBA, without deriving it from scores or scouting."""
    if not isinstance(rankings_data, dict):
        return None
    rows = rankings_data.get("rankings")
    if not isinstance(rows, list):
        return None

    info = rankings_data.get("extra_stats_info")
    # Older caches saved the ranking rows without metadata. For the current
    # season, TBA puts total Ranking Points first in extra_stats.
    index = 0
    if info is not None:
        if not isinstance(info, list):
            return None
        index = next((i for i, field in enumerate(info)
                      if isinstance(field, dict)
                      and field.get("name") in (
                          "Total Ranking Points", "Ranking Points",
                      )), None)
        if index is None:
            return None

    for row in rows:
        if not isinstance(row, dict) or row.get("team_key") != team_key:
            continue
        values = row.get("extra_stats")
        if not isinstance(values, list) or index >= len(values):
            return None
        value = _safe_float(values[index])
        return value if value is not None and value >= 0 else None
    return None


def _extract_sequence(value: Any) -> list:
    """
    Accepts raw lists as well as common MongoDB/cache wrapper documents.
    """

    if isinstance(value, list):
        return value

    if not isinstance(value, dict):
        return []

    for key in (
        "matches",
        "data",
        "TBAdata",
        "tbaData",
        "results",
        "stats",
    ):
        nested_value = value.get(key)

        if isinstance(nested_value, list):
            return nested_value

    return []


def _canonical_match_key(
    event_key: Optional[str],
    match_value: Any,
) -> Optional[str]:
    if match_value is None:
        return None

    text = str(match_value).strip().lower()

    if not text:
        return None

    if "_" in text and re.search(
        r"_(?:qm|ef|qf|sf|f)\d",
        text,
    ):
        return text

    if re.fullmatch(
        r"(?:qm\d+|ef\d+m\d+|qf\d+m\d+|sf\d+m\d+|f\d+m\d+)",
        text,
    ):
        return f"{event_key}_{text}" if event_key else text

    match_number = _safe_int(text)

    if match_number is not None:
        suffix = f"qm{match_number}"
        return f"{event_key}_{suffix}" if event_key else suffix

    return f"{event_key}_{text}" if event_key else text


def _match_number_from_key(match_key: Optional[str]) -> Optional[int]:
    if not match_key:
        return None

    match = re.search(r"(?:qm|m)(\d+)$", match_key)

    if match:
        return int(match.group(1))

    return _safe_int(match_key)


def analyze_scout_data(
    Scoutdata: Any,
) -> dict[int, dict]:
    """
    Aggregates individual-team scouting records.

    Fuel values are direct team measurements, so they are averaged directly.
    Death/defense rates use only records containing a valid boolean value.
    """

    scout_rows = _extract_sequence(Scoutdata)

    if isinstance(Scoutdata, dict) and "team" in Scoutdata:
        scout_rows = [Scoutdata]

    team_entries: dict[int, list[dict]] = defaultdict(list)

    for document in scout_rows:
        if not isinstance(document, dict):
            continue

        team = _safe_int(document.get("team"))

        if team is None:
            continue

        data = document.get("data", {})
        data = data if isinstance(data, dict) else {}

        auto_data = data.get("autoScouting", {})
        teleop_data = data.get("teleopScouting", {})
        misc_data = data.get("misc", {})
        scout_info = document.get("scoutInfo", {})

        auto_data = auto_data if isinstance(auto_data, dict) else {}
        teleop_data = (
            teleop_data
            if isinstance(teleop_data, dict)
            else {}
        )
        misc_data = misc_data if isinstance(misc_data, dict) else {}
        scout_info = (
            scout_info
            if isinstance(scout_info, dict)
            else {}
        )

        auto_fuel = _safe_scouted_fuel(
            auto_data.get("fuel_scored"),
            maximum=MAX_SCOUTED_AUTO_FUEL,
        )
        teleop_fuel = _safe_scouted_fuel(
            teleop_data.get("fuel_scored"),
            maximum=MAX_SCOUTED_TELEOP_FUEL,
        )
        died = _safe_bool(misc_data.get("died"))
        defense = _safe_bool(misc_data.get("defense"))


        defense_value = None

        for key in (
            "played_defense",
            "playedDefense",
            "defense",
        ):
            if key in misc_data:
                defense_value = _safe_bool(
                    misc_data.get(key)
                )
                break

        event_key = document.get("event")
        match_key = _canonical_match_key(
            str(event_key) if event_key else None,
            document.get("match"),
        )

        comment = misc_data.get("comments")
        comment = (
            str(comment).strip()
            if comment is not None
            else ""
        )

        team_entries[team].append({
            "Event": event_key,
            "Match": match_key,
            "MatchNumber": _match_number_from_key(match_key),
            "AutoFuel": auto_fuel,
            "TeleopFuel": teleop_fuel,
            "TotalFuel": (
                round(auto_fuel + teleop_fuel, 2)
                if auto_fuel is not None
                and teleop_fuel is not None
                else None
            ),
            "Died": died,
            "Defense": defense,
            "PlayedDefense": defense_value,
            "Comments": comment,
            "Scout": {
                "UserId": scout_info.get("userId"),
                "FirstName": scout_info.get("firstName"),
                "Username": scout_info.get("username"),
                "Team": scout_info.get("team"),
            },
            "GroupId": document.get("groupId"),
        })

    analyzed: dict[int, dict] = {}

    for team, entries in team_entries.items():
        auto_values = [
            entry["AutoFuel"]
            for entry in entries
            if entry["AutoFuel"] is not None
        ]
        teleop_values = [
            entry["TeleopFuel"]
            for entry in entries
            if entry["TeleopFuel"] is not None
        ]
        total_values = [
            entry["TotalFuel"]
            for entry in entries
            if entry["TotalFuel"] is not None
        ]
        death_values = [
            entry["Died"]
            for entry in entries
            if entry["Died"] is not None
        ]
        defense_values = [
            entry["PlayedDefense"]
            for entry in entries
            if entry["PlayedDefense"] is not None
        ]

        per_match_entries: dict[str, list[dict]] = defaultdict(list)

        for entry in entries:
            match_key = entry["Match"] or "unknown"
            per_match_entries[match_key].append(entry)

        scouting_match_history: list[dict] = []

        for match_key, match_entries in per_match_entries.items():
            match_auto_values = [
                entry["AutoFuel"]
                for entry in match_entries
                if entry["AutoFuel"] is not None
            ]
            match_teleop_values = [
                entry["TeleopFuel"]
                for entry in match_entries
                if entry["TeleopFuel"] is not None
            ]
            match_total_values = [
                entry["TotalFuel"]
                for entry in match_entries
                if entry["TotalFuel"] is not None
            ]
            match_death_values = [
                entry["Died"]
                for entry in match_entries
                if entry["Died"] is not None
            ]
            match_defense_values = [
                entry["PlayedDefense"]
                for entry in match_entries
                if entry["PlayedDefense"] is not None
            ]

            comments = [
                entry["Comments"]
                for entry in match_entries
                if entry["Comments"]
            ]

            scouting_match_history.append({
                "Match": (
                    None
                    if match_key == "unknown"
                    else match_key
                ),
                "MatchNumber": _match_number_from_key(
                    None
                    if match_key == "unknown"
                    else match_key
                ),
                "ScoutCount": len(match_entries),
                "AverageAutoFuel": (
                    round(float(np.mean(match_auto_values)), 2)
                    if match_auto_values
                    else None
                ),
                "AverageTeleopFuel": (
                    round(float(np.mean(match_teleop_values)), 2)
                    if match_teleop_values
                    else None
                ),
                "AverageTotalFuel": (
                    round(float(np.mean(match_total_values)), 2)
                    if match_total_values
                    else None
                ),
                "DeathRate": (
                    round(
                        sum(match_death_values)
                        / len(match_death_values),
                        3,
                    )
                    if match_death_values
                    else 0.0
                ),
                "DefenseRate": (
                    round(
                        sum(match_defense_values)
                        / len(match_defense_values),
                        3,
                    )
                    if match_defense_values
                    else 0.0
                ),
                "DeathSamples": len(match_death_values),
                "DefenseSamples": len(match_defense_values),
                "Comments": comments,
            })

        scouting_match_history.sort(
            key=lambda row: (
                row["MatchNumber"] is None,
                row["MatchNumber"] or 0,
                row["Match"] or "",
            )
        )

        analyzed[team] = {
            "ScoutEntries": len(entries),
            "ScoutedMatches": len({
                entry["Match"]
                for entry in entries
                if entry["Match"] is not None
            }),
            "AverageAutoFuel": (
                round(float(np.mean(auto_values)), 2)
                if auto_values
                else None
            ),
            "AverageTeleopFuel": (
                round(float(np.mean(teleop_values)), 2)
                if teleop_values
                else None
            ),
            "AverageTotalFuel": (
                round(float(np.mean(total_values)), 2)
                if total_values
                else None
            ),
            "DeathRate": (
                round(sum(death_values) / len(death_values), 3)
                if death_values
                else 0.0
            ),
            "DefenseRate": (
                round(
                    sum(defense_values) / len(defense_values),
                    3,
                )
                if defense_values
                else 0.0
            ),
            "DiedCount": sum(death_values),
            "DeathSamples": len(death_values),
            "DefenseCount": sum(defense_values),
            "DefenseSamples": len(defense_values),
            "Comments": [
                entry["Comments"]
                for entry in entries
                if entry["Comments"]
            ],
            "ScoutingHistory": sorted(
                entries,
                key=lambda entry: (
                    entry["MatchNumber"] is None,
                    entry["MatchNumber"] or 0,
                    entry["Match"] or "",
                ),
            ),
            "ScoutingMatchHistory": scouting_match_history,
        }

    return analyzed


def fuse_scouting_fuel(raw_matches, opr, calculated, scouted, match_counts):
    """Blend only observed fuel; leave the original OPR solve and tower intact.

    Each distinct scouted qualification match gets one vote, irrespective of
    how many scouts reported it. Weight = 0.30 * scouted / played matches.
    Only the fuel delta is added to phase/total OPR, preserving non-fuel points.
    """
    if not scouted or not calculated:
        return calculated, {}

    teams = sorted(calculated)
    team_index = {team: index for index, team in enumerate(teams)}
    matrix = np.zeros((len(opr.matches), len(teams)))
    for row_index, row in enumerate(opr.matches):
        for team in row["teams"]:
            matrix[row_index, team_index[team]] = 1

    fuel = {"auto": [], "teleop": []}
    eligible = set()
    for match in raw_matches:
        if match.get("comp_level") != "qm" or not match.get("score_breakdown"):
            continue
        for color in ("red", "blue"):
            alliance = match["alliances"][color]
            if alliance.get("score", -1) < 0:
                continue
            hub = match["score_breakdown"][color].get("hubScore", {})
            hub = hub if isinstance(hub, dict) else {}
            for phase in fuel:
                value = _safe_float(hub.get(f"{phase}Points"))
                fuel[phase].append(value if value is not None and value >= 0 else None)
            key = match.get("key")
            if isinstance(key, str) and "_" in key:
                event = key.rsplit("_", 1)[0]
                for team in alliance["team_keys"]:
                    eligible.add((event, key, int(team.removeprefix("frc"))))

    estimates = {}
    for phase, values in fuel.items():
        # A partial fuel breakdown cannot reliably separate fuel from tower.
        if len(values) == len(opr.matches) and all(value is not None for value in values):
            estimates[phase] = np.linalg.lstsq(matrix, np.asarray(values), rcond=None)[0]

    fused = {team: dict(values) for team, values in calculated.items()}
    diagnostics = {}
    for team, scouting in scouted.items():
        if str(team) not in calculated:
            continue
        applied = {}
        for phase in fuel:
            by_match = defaultdict(list)
            for entry in scouting.get("ScoutingHistory", []):
                if (entry.get("Event"), entry.get("Match"), team) not in eligible:
                    continue
                value = entry.get(f"{phase.title()}Fuel")
                if value is not None:
                    by_match[entry["Match"]].append(value)

            weight = 0.0
            if by_match and phase in estimates:
                coverage = len(by_match) / match_counts[team]
                weight = MAX_SCOUTING_FUEL_WEIGHT * min(1.0, coverage)
                measured = float(np.mean([np.mean(values) for values in by_match.values()]))
                tba_fuel = float(estimates[phase][team_index[str(team)]])
                delta = weight * (measured - tba_fuel)
                fused[str(team)][f"{phase}OPR"] += delta
                fused[str(team)]["totalOPR"] += delta
            applied[f"{phase}_weight"] = weight
            applied[f"{phase}_matches"] = len(by_match)
        diagnostics[team] = applied
    return fused, diagnostics
