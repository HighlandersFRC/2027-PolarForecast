import re
from collections import defaultdict
from typing import Any, Iterable, Optional

import numpy as np
import requests

from config import TBA_API_URL, TBA_KEY


HEADERS = {
    "X-TBA-Auth-Key": TBA_KEY,
}


COMP_LEVEL_ORDER = {
    "qm": 0,
    "ef": 1,
    "qf": 2,
    "sf": 3,
    "f": 4,
}


# GroupStats OPR fusion configuration.
# Scouting is intentionally favored over TBA for the fuel contribution.
SCOUTING_OPR_WEIGHT = 0.70
TBA_OPR_WEIGHT = 1.0 - SCOUTING_OPR_WEIGHT

# Convert directly scouted fuel counts into scoring contribution. Change
# these values if auto and teleop fuel have different point values.
SCOUTED_AUTO_FUEL_POINT_VALUE = 1.0
SCOUTED_TELEOP_FUEL_POINT_VALUE = 1.0


# The first matching TBA score-breakdown field is used.
AUTO_FUEL_PATHS = (
    ("hubScore", "autoFuelCount"),
    ("hubScore", "autoFuel"),
    ("hubScore", "autoCount"),
    ("hubScore", "autoFuelScored"),
    ("autoFuelCount",),
    ("hubAutoFuelCount",),
    ("totalAutoFuel",),
    ("auto_fuel_count",),
)


TELEOP_FUEL_PATHS = (
    ("hubScore", "teleopFuelCount"),
    ("hubScore", "teleopFuel"),
    ("hubScore", "teleopCount"),
    ("hubScore", "teleopFuelScored"),
    ("teleopFuelCount",),
    ("hubTeleopFuelCount",),
    ("totalTeleopFuel",),
    ("teleop_fuel_count",),
)


def get_event_rankings(event_key: str) -> dict:
    response = requests.get(
        TBA_API_URL + f"event/{event_key}/rankings",
        headers=HEADERS,
        timeout=20,
    )

    if response.status_code != 200:
        raise RuntimeError(
            f"TBA Error {response.status_code}: {response.text}"
        )

    return response.json()


def get_event_matches(event_key: str) -> list[dict]:
    response = requests.get(
        TBA_API_URL + f"event/{event_key}/matches",
        headers=HEADERS,
        timeout=20,
    )

    if response.status_code != 200:
        raise RuntimeError(
            f"TBA Error {response.status_code}: {response.text}"
        )

    return response.json()


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


def _calculate_scouting_opr(
    average_auto_fuel: Any,
    average_teleop_fuel: Any,
) -> Optional[float]:
    """Converts direct scouting fuel averages into an OPR contribution."""

    auto_fuel = _safe_float(average_auto_fuel)
    teleop_fuel = _safe_float(average_teleop_fuel)

    if auto_fuel is None and teleop_fuel is None:
        return None

    return round(
        (auto_fuel or 0.0) * SCOUTED_AUTO_FUEL_POINT_VALUE
        + (teleop_fuel or 0.0) * SCOUTED_TELEOP_FUEL_POINT_VALUE,
        2,
    )


def _fused_opr_fields(
    tba_opr: Any,
    tba_auto_fuel_opr: Any,
    tba_teleop_fuel_opr: Any,
    scouted_auto_fuel: Any,
    scouted_teleop_fuel: Any,
) -> dict:
    """
    Produces one final OPR while retaining its source components.

    When TBA fuel OPR is available, only the fuel portion is blended.
    The TBA non-fuel remainder stays intact, preserving climb/endgame and
    any other scoring that the scouting form does not directly measure.
    """

    tba_total = _safe_float(tba_opr)
    tba_auto_fuel = _safe_float(tba_auto_fuel_opr)
    tba_teleop_fuel = _safe_float(tba_teleop_fuel_opr)
    scouting_opr = _calculate_scouting_opr(
        scouted_auto_fuel,
        scouted_teleop_fuel,
    )

    tba_fuel_values = [
        value
        for value in (tba_auto_fuel, tba_teleop_fuel)
        if value is not None
    ]
    tba_fuel_opr = (
        round(sum(tba_fuel_values), 2)
        if tba_fuel_values
        else None
    )

    if tba_total is not None and scouting_opr is not None:
        if tba_fuel_opr is not None:
            tba_non_fuel_opr = round(
                tba_total - tba_fuel_opr,
                2,
            )
            fused_fuel_opr = round(
                scouting_opr * SCOUTING_OPR_WEIGHT
                + tba_fuel_opr * TBA_OPR_WEIGHT,
                2,
            )
            fused_opr = round(
                tba_non_fuel_opr + fused_fuel_opr,
                1,
            )
            fusion_mode = "fuel_component_blend"
        else:
            tba_non_fuel_opr = None
            fused_fuel_opr = None
            fused_opr = round(
                scouting_opr * SCOUTING_OPR_WEIGHT
                + tba_total * TBA_OPR_WEIGHT,
                1,
            )
            fusion_mode = "total_opr_fallback_blend"

        scouting_weight = SCOUTING_OPR_WEIGHT
        tba_weight = TBA_OPR_WEIGHT

    elif scouting_opr is not None:
        tba_non_fuel_opr = None
        fused_fuel_opr = scouting_opr
        fused_opr = round(scouting_opr, 1)
        fusion_mode = "scouting_only"
        scouting_weight = 1.0
        tba_weight = 0.0

    else:
        tba_non_fuel_opr = (
            round(tba_total - tba_fuel_opr, 2)
            if tba_total is not None and tba_fuel_opr is not None
            else None
        )
        fused_fuel_opr = tba_fuel_opr
        fused_opr = (
            round(tba_total, 1)
            if tba_total is not None
            else None
        )
        fusion_mode = "tba_only" if tba_total is not None else "unavailable"
        scouting_weight = 0.0
        tba_weight = 1.0 if tba_total is not None else 0.0

    return {
        "OPR": fused_opr,
        "TBAOPR": round(tba_total, 1) if tba_total is not None else None,
        "ScoutingOPR": scouting_opr,
        "TBAFuelOPR": tba_fuel_opr,
        "TBANonFuelOPR": tba_non_fuel_opr,
        "FusedFuelOPR": fused_fuel_opr,
        "OPRFusionMode": fusion_mode,
        "OPRWeights": {
            "scouting": round(scouting_weight, 2),
            "tba": round(tba_weight, 2),
        },
    }


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


def _number_at_path(
    data: dict,
    path: tuple[str, ...],
) -> Optional[float]:
    value: Any = data

    for key in path:
        if not isinstance(value, dict) or key not in value:
            return None

        value = value[key]

    return _safe_float(value)


def _extract_fuel_count(
    breakdown: dict,
    paths: Iterable[tuple[str, ...]],
) -> Optional[float]:
    for path in paths:
        value = _number_at_path(breakdown, path)

        if value is not None:
            return value

    return None


def _raw_match_sort_key(match: dict) -> tuple:
    actual_time = _safe_float(match.get("actual_time"))

    if actual_time is not None and actual_time > 0:
        return 0, actual_time

    return (
        1,
        COMP_LEVEL_ORDER.get(str(match.get("comp_level", "")).lower(), 99),
        _safe_int(match.get("set_number")) or 0,
        _safe_int(match.get("match_number")) or 0,
    )


def _parsed_match_sort_key(match: dict) -> tuple:
    actual_time = _safe_float(match.get("actual_time"))

    if actual_time is not None and actual_time > 0:
        return 0, actual_time

    return (
        1,
        COMP_LEVEL_ORDER.get(str(match.get("comp_level", "")).lower(), 99),
        _safe_int(match.get("set_number")) or 0,
        _safe_int(match.get("match_number")) or 0,
    )


def build_dataset(matches: Iterable[dict]) -> list[dict]:
    """
    Converts completed TBA matches into alliance observations.

    Each completed match creates two rows: one red alliance row and one
    blue alliance row. Those alliance rows are used by least-squares OPR.
    """

    parsed_matches: list[dict] = []

    valid_matches = [
        match
        for match in matches
        if isinstance(match, dict)
    ]

    for match in sorted(valid_matches, key=_raw_match_sort_key):
        score_breakdown = match.get("score_breakdown")

        if not isinstance(score_breakdown, dict):
            continue

        alliance_rows: list[dict] = []

        for alliance_color in ("red", "blue"):
            alliance = (
                match
                .get("alliances", {})
                .get(alliance_color, {})
            )
            breakdown = score_breakdown.get(alliance_color)

            if not isinstance(alliance, dict):
                alliance_rows = []
                break

            if not isinstance(breakdown, dict):
                alliance_rows = []
                break

            team_keys = alliance.get("team_keys", [])

            teams = [
                int(team_key.removeprefix("frc"))
                for team_key in team_keys
                if (
                    isinstance(team_key, str)
                    and team_key.startswith("frc")
                    and team_key.removeprefix("frc").isdigit()
                )
            ]

            if not teams:
                alliance_rows = []
                break

            hub_score = breakdown.get("hubScore", {})

            if not isinstance(hub_score, dict):
                hub_score = {}

            alliance_rows.append({
                "color": alliance_color,
                "teams": teams,
                "score": _safe_float(
                    breakdown.get("totalPoints")
                ) or 0.0,
                "auto": _safe_float(
                    breakdown.get("totalAutoPoints")
                ) or 0.0,
                "teleop": _safe_float(
                    breakdown.get("totalTeleopPoints")
                ) or 0.0,
                "endgame": _safe_float(
                    hub_score.get("endgamePoints")
                ) or 0.0,
                "climb": _safe_float(
                    breakdown.get("totalTowerPoints")
                ) or 0.0,
                "auto_fuel": _extract_fuel_count(
                    breakdown,
                    AUTO_FUEL_PATHS,
                ),
                "teleop_fuel": _extract_fuel_count(
                    breakdown,
                    TELEOP_FUEL_PATHS,
                ),
            })

        if len(alliance_rows) != 2:
            continue

        parsed_matches.append({
            "key": match.get("key"),
            "comp_level": str(
                match.get("comp_level", "")
            ).lower(),
            "set_number": _safe_int(
                match.get("set_number")
            ) or 0,
            "match_number": _safe_int(
                match.get("match_number")
            ) or 0,
            "actual_time": match.get("actual_time"),
            "alliances": alliance_rows,
        })

    return parsed_matches


def solve_opr(
    X: np.ndarray,
    y: np.ndarray,
) -> np.ndarray:
    """
    Solves the least-squares team contribution values.

    np.linalg.lstsq also handles events where the matrix has not reached
    full rank yet, which is common early in an event.
    """

    coefficients, _, _, _ = np.linalg.lstsq(
        X,
        y,
        rcond=None,
    )

    return coefficients


def _solve_optional_metric(
    X: np.ndarray,
    alliance_rows: list[dict],
    field_name: str,
) -> Optional[np.ndarray]:
    row_indexes = [
        index
        for index, row in enumerate(alliance_rows)
        if _safe_float(row.get(field_name)) is not None
    ]

    if not row_indexes:
        return None

    return solve_opr(
        X[row_indexes],
        np.asarray(
            [
                float(alliance_rows[index][field_name])
                for index in row_indexes
            ],
            dtype=float,
        ),
    )


def _solve_snapshot(
    alliance_rows: list[dict],
) -> dict[int, dict]:
    """
    Calculates the current team statistics from all alliance observations
    received up to one point in the event.
    """

    teams = sorted({
        team
        for row in alliance_rows
        for team in row.get("teams", [])
        if isinstance(team, int)
    })

    if not teams:
        return {}

    team_index = {
        team: index
        for index, team in enumerate(teams)
    }

    X = np.zeros(
        (len(alliance_rows), len(teams)),
        dtype=float,
    )

    metric_values = {
        "score": [],
        "auto": [],
        "teleop": [],
        "endgame": [],
        "climb": [],
    }

    for row_index, row in enumerate(alliance_rows):
        for team in row.get("teams", []):
            if team in team_index:
                X[row_index, team_index[team]] = 1.0

        for metric_name in metric_values:
            metric_values[metric_name].append(
                _safe_float(row.get(metric_name)) or 0.0
            )

    solved = {
        metric_name: solve_opr(
            X,
            np.asarray(values, dtype=float),
        )
        for metric_name, values in metric_values.items()
    }

    auto_fuel_opr = _solve_optional_metric(
        X,
        alliance_rows,
        "auto_fuel",
    )
    teleop_fuel_opr = _solve_optional_metric(
        X,
        alliance_rows,
        "teleop_fuel",
    )

    snapshot: dict[int, dict] = {}

    for team, index in team_index.items():
        snapshot[team] = {
            "OPR": round(float(solved["score"][index]), 1),
            "Auto": round(float(solved["auto"][index]), 1),
            "Teleop": round(float(solved["teleop"][index]), 1),
            "Endgame": round(float(solved["endgame"][index]), 1),
            "Climb": round(float(solved["climb"][index]), 1),
            "AutoFuelOPR": (
                round(float(auto_fuel_opr[index]), 1)
                if auto_fuel_opr is not None
                else None
            ),
            "TeleopFuelOPR": (
                round(float(teleop_fuel_opr[index]), 1)
                if teleop_fuel_opr is not None
                else None
            ),
        }

    return snapshot


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


def _looks_like_parsed_match(value: Any) -> bool:
    if not isinstance(value, dict):
        return False

    alliances = value.get("alliances")

    return (
        isinstance(alliances, list)
        and any(
            isinstance(row, dict)
            and isinstance(row.get("teams"), list)
            for row in alliances
        )
    )


def _looks_like_raw_tba_match(value: Any) -> bool:
    return (
        isinstance(value, dict)
        and isinstance(value.get("alliances"), dict)
        and "score_breakdown" in value
    )


def _coerce_parsed_matches(
    TBAdata: Any,
    matches: Any,
) -> list[dict]:
    """
    TBAdata may be:
      * raw TBA matches,
      * build_dataset(...) output,
      * a wrapper containing either of those,
      * or precomputed team stats.

    If TBAdata is not match data, matches is used.
    """

    for candidate in (
        _extract_sequence(TBAdata),
        _extract_sequence(matches),
    ):
        if not candidate:
            continue

        if any(_looks_like_parsed_match(row) for row in candidate):
            return sorted(
                [
                    row
                    for row in candidate
                    if _looks_like_parsed_match(row)
                ],
                key=_parsed_match_sort_key,
            )

        if any(_looks_like_raw_tba_match(row) for row in candidate):
            return build_dataset(candidate)

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

    # Already a full TBA match key.
    if "_" in text and re.search(
        r"_(?:qm|ef|qf|sf|f)\d",
        text,
    ):
        return text

    # qm12, sf2m1, f1m2, etc.
    if re.fullmatch(
        r"(?:qm\d+|ef\d+m\d+|qf\d+m\d+|sf\d+m\d+|f\d+m\d+)",
        text,
    ):
        return f"{event_key}_{text}" if event_key else text

    # Your DB example stores qualification match 12 as "12".
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

    # A single MongoDB document can be passed directly.
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

        auto_fuel = _safe_float(
            auto_data.get("fuel_scored")
        )
        teleop_fuel = _safe_float(
            teleop_data.get("fuel_scored")
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
            entry["Defense"]
            for entry in entries
            if entry["Defense"] is not None
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
            match_defense_value = [
                entry["Defense"]
                for entry in match_entries
                if entry["Defense"] is not None
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
            "DefenseCount": sum(defense_values),
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


def _build_tba_results(
    parsed_matches: list[dict],
    rankings_data: Any,
) -> dict[int, dict]:
    if not parsed_matches:
        return {}

    cumulative_alliance_rows: list[dict] = []
    match_counts: dict[int, int] = defaultdict(int)
    team_history: dict[int, list[dict]] = defaultdict(list)
    final_snapshot: dict[int, dict] = {}

    for parsed_match in parsed_matches:
        cumulative_alliance_rows.extend(
            parsed_match.get("alliances", [])
        )

        final_snapshot = _solve_snapshot(
            cumulative_alliance_rows
        )

        teams_in_match = {
            team
            for alliance in parsed_match.get("alliances", [])
            for team in alliance.get("teams", [])
            if isinstance(team, int)
        }

        for team in teams_in_match:
            current_stats = final_snapshot.get(team)

            if current_stats is None:
                continue

            match_counts[team] += 1

            team_history[team].append({
                "Match": parsed_match.get("key"),
                "CompLevel": parsed_match.get("comp_level"),
                "SetNumber": parsed_match.get("set_number", 0),
                "MatchNumber": parsed_match.get("match_number", 0),
                "ActualTime": parsed_match.get("actual_time"),
                "MatchesPlayed": match_counts[team],
                "OPR": current_stats["OPR"],
                "Auto": current_stats["Auto"],
                "Teleop": current_stats["Teleop"],
                "Endgame": current_stats["Endgame"],
                "Climb": current_stats["Climb"],
                "AutoFuelOPR": current_stats["AutoFuelOPR"],
                "TeleopFuelOPR": current_stats["TeleopFuelOPR"],
            })

    results: dict[int, dict] = {}

    for team, stats in final_snapshot.items():
        results[team] = {
            "Team": team,
            "Rank": rankings(
                rankings_data,
                f"frc{team}",
            ),
            **stats,
            "MatchesPlayed": match_counts.get(team, 0),
            "MatchHistory": team_history.get(team, []),
        }

    return results


def _precomputed_team_rows(TBAdata: Any) -> dict[int, dict]:
    """
    Preserves extra fields when TBAdata is already a team-stat list.

    Calculated linreg values still take priority over duplicate fields.
    """

    rows = _extract_sequence(TBAdata)

    if isinstance(TBAdata, dict) and "Team" in TBAdata:
        rows = [TBAdata]

    result: dict[int, dict] = {}

    for row in rows:
        if not isinstance(row, dict):
            continue

        team = _safe_int(
            row.get("Team", row.get("team"))
        )

        if team is None:
            continue

        if _looks_like_raw_tba_match(row):
            continue

        if _looks_like_parsed_match(row):
            continue

        result[team] = dict(row)
        result[team]["Team"] = team

    return result


def _merge_scout_history(
    match_history: list[dict],
    scouting_match_history: list[dict],
) -> list[dict]:
    scout_by_match = {
        row.get("Match"): row
        for row in scouting_match_history
        if row.get("Match")
    }

    merged_history: list[dict] = []
    used_scout_matches: set[str] = set()

    for history_row in match_history:
        merged_row = dict(history_row)
        match_key = history_row.get("Match")
        scout_row = scout_by_match.get(match_key)

        if scout_row is not None:
            used_scout_matches.add(match_key)
            merged_row.update({
                "ScoutedAutoFuel": scout_row.get(
                    "AverageAutoFuel"
                ),
                "ScoutedTeleopFuel": scout_row.get(
                    "AverageTeleopFuel"
                ),
                "ScoutedTotalFuel": scout_row.get(
                    "AverageTotalFuel"
                ),
                "DeathRate": scout_row.get("DeathRate"),
                "DefenseRate": scout_row.get("DefenseRate"),
                "ScoutCount": scout_row.get("ScoutCount"),
                "Comments": scout_row.get("Comments", []),
            })
        else:
            merged_row.update({
                "ScoutedAutoFuel": None,
                "ScoutedTeleopFuel": None,
                "ScoutedTotalFuel": None,
                "DeathRate": None,
                "DefenseRate": None,
                "ScoutCount": 0,
                "Comments": [],
            })

        merged_history.append(merged_row)

    # Keep scouting observations even when TBA has not produced a completed
    # score breakdown for that match yet.
    for scout_row in scouting_match_history:
        match_key = scout_row.get("Match")

        if not match_key or match_key in used_scout_matches:
            continue

        merged_history.append({
            "Match": match_key,
            "CompLevel": None,
            "SetNumber": 0,
            "MatchNumber": scout_row.get("MatchNumber"),
            "ActualTime": None,
            "MatchesPlayed": None,
            "OPR": None,
            "Auto": None,
            "Teleop": None,
            "Endgame": None,
            "Climb": None,
            "AutoFuelOPR": None,
            "TeleopFuelOPR": None,
            "ScoutedAutoFuel": scout_row.get(
                "AverageAutoFuel"
            ),
            "ScoutedTeleopFuel": scout_row.get(
                "AverageTeleopFuel"
            ),
            "ScoutedTotalFuel": scout_row.get(
                "AverageTotalFuel"
            ),
            "DeathRate": scout_row.get("DeathRate"),
            "DefenseRate": scout_row.get("DefenseRate"),
            "ScoutCount": scout_row.get("ScoutCount"),
            "Comments": scout_row.get("Comments", []),
        })

    merged_history.sort(
        key=lambda row: (
            row.get("ActualTime") is None,
            row.get("ActualTime") or 0,
            COMP_LEVEL_ORDER.get(
                str(row.get("CompLevel", "")).lower(),
                99,
            ),
            row.get("SetNumber") or 0,
            row.get("MatchNumber") or 0,
        )
    )

    # Build cumulative scouting averages so every historical OPR point is
    # fused using all scouting information available up through that match.
    cumulative_auto_total = 0.0
    cumulative_auto_samples = 0
    cumulative_teleop_total = 0.0
    cumulative_teleop_samples = 0

    for row in merged_history:
        scout_count = _safe_int(row.get("ScoutCount")) or 0
        scout_auto = _safe_float(row.get("ScoutedAutoFuel"))
        scout_teleop = _safe_float(row.get("ScoutedTeleopFuel"))

        if scout_count > 0 and scout_auto is not None:
            cumulative_auto_total += scout_auto * scout_count
            cumulative_auto_samples += scout_count

        if scout_count > 0 and scout_teleop is not None:
            cumulative_teleop_total += scout_teleop * scout_count
            cumulative_teleop_samples += scout_count

        cumulative_auto = (
            cumulative_auto_total / cumulative_auto_samples
            if cumulative_auto_samples > 0
            else None
        )
        cumulative_teleop = (
            cumulative_teleop_total / cumulative_teleop_samples
            if cumulative_teleop_samples > 0
            else None
        )

        fusion = _fused_opr_fields(
            tba_opr=row.get("OPR"),
            tba_auto_fuel_opr=row.get("AutoFuelOPR"),
            tba_teleop_fuel_opr=row.get("TeleopFuelOPR"),
            scouted_auto_fuel=cumulative_auto,
            scouted_teleop_fuel=cumulative_teleop,
        )

        row.update(fusion)
        row["CumulativeScoutedAutoFuel"] = (
            round(cumulative_auto, 2)
            if cumulative_auto is not None
            else None
        )
        row["CumulativeScoutedTeleopFuel"] = (
            round(cumulative_teleop, 2)
            if cumulative_teleop is not None
            else None
        )

    return merged_history


def linreg(
    TBAdata: Any,
    Scoutdata: Any,
    matches: Any,
    rankings_data: Any,
) -> list[dict]:
    """
    Returns one combined analyzed row per team.

    Parameters
    ----------
    TBAdata:
        Raw TBA matches, build_dataset(...) output, cached TBA wrapper data,
        or an existing list of team-stat dictionaries.
    Scoutdata:
        One MongoDB match-scouting document or a list/wrapper containing
        match-scouting documents.
    matches:
        Raw TBA match list used when TBAdata is not itself match data.
    rankings_data:
        The TBA event rankings response.

    Returns
    -------
    list[dict]
        OPR/Auto/Teleop/Endgame/Climb and fuel OPR from TBA linear
        regression, plus direct scouting averages, death rate, defense
        rate, comments, and merged match history.
    """

    parsed_matches = _coerce_parsed_matches(
        TBAdata,
        matches,
    )
    tba_results = _build_tba_results(
        parsed_matches,
        rankings_data,
    )
    scout_results = analyze_scout_data(Scoutdata)
    precomputed_results = _precomputed_team_rows(TBAdata)

    all_teams = (
        set(tba_results)
        | set(scout_results)
        | set(precomputed_results)
    )

    combined_results: list[dict] = []

    for team in all_teams:
        precomputed = precomputed_results.get(team, {})
        calculated = tba_results.get(team, {})
        scouted = scout_results.get(team, {})

        # Extra cached fields are retained, but freshly calculated linreg
        # fields override duplicate cached values.
        result = {
            **precomputed,
            **calculated,
        }

        result.setdefault("Team", team)
        result.setdefault(
            "Rank",
            rankings(rankings_data, f"frc{team}"),
        )
        result.setdefault("OPR", None)
        result.setdefault("Auto", None)
        result.setdefault("Teleop", None)
        result.setdefault("Endgame", None)
        result.setdefault("Climb", None)
        result.setdefault("AutoFuelOPR", None)
        result.setdefault("TeleopFuelOPR", None)
        result.setdefault("MatchesPlayed", 0)
        result.setdefault("MatchHistory", [])

        result.update({
            "ScoutEntries": scouted.get("ScoutEntries", 0),
            "ScoutedMatches": scouted.get("ScoutedMatches", 0),
            "AverageAutoFuel": scouted.get(
                "AverageAutoFuel"
            ),
            "AverageTeleopFuel": scouted.get(
                "AverageTeleopFuel"
            ),
            "AverageTotalFuel": scouted.get(
                "AverageTotalFuel"
            ),
            "DeathRate": scouted.get("DeathRate", 0.0),
            "DefenseRate": scouted.get("DefenseRate", 0.0),
            "DiedCount": scouted.get("DiedCount", 0),
            "DefenseCount": scouted.get("DefenseCount", 0),
            "DeathSamples": scouted.get("DeathSamples", 0),
            "DefenseCount": scouted.get("DefenseCount", 0),
            "DefenseSamples": scouted.get(
                "DefenseSamples",
                0,
            ),
            "Comments": scouted.get("Comments", []),
            "ScoutingHistory": scouted.get(
                "ScoutingHistory",
                [],
            ),
            "ScoutingMatchHistory": scouted.get(
                "ScoutingMatchHistory",
                [],
            ),
        })

        # Replace the public OPR with one fused value. Raw source values
        # remain available as TBAOPR and ScoutingOPR for diagnostics.
        result.update(_fused_opr_fields(
            tba_opr=result.get("OPR"),
            tba_auto_fuel_opr=result.get("AutoFuelOPR"),
            tba_teleop_fuel_opr=result.get("TeleopFuelOPR"),
            scouted_auto_fuel=result.get("AverageAutoFuel"),
            scouted_teleop_fuel=result.get("AverageTeleopFuel"),
        ))

        result["MatchHistory"] = _merge_scout_history(
            result.get("MatchHistory", []),
            result["ScoutingMatchHistory"],
        )

        combined_results.append(result)

    combined_results.sort(
        key=lambda row: (
            row.get("OPR") is None,
            -(row.get("OPR") or 0.0),
            row.get("Team") or 0,
        )
    )

    return combined_results


# Backward-compatible wrapper for older code that only uses TBA.
def linreg_TBA(
    event_key: str,
    matches: Optional[list[dict]] = None,
    rankings_data: Optional[dict] = None,
) -> list[dict]:
    if matches is None:
        matches = get_event_matches(event_key)

    if rankings_data is None:
        rankings_data = get_event_rankings(event_key)

    return linreg(
        TBAdata=matches,
        Scoutdata=[],
        matches=matches,
        rankings_data=rankings_data,
    )