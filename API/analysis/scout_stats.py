"""Scout participation and cautious trust estimates without duplicate coverage."""

from collections import defaultdict
from statistics import mean, median

from .scouting import (
    MAX_SCOUTED_AUTO_FUEL, MAX_SCOUTED_TELEOP_FUEL,
    _canonical_match_key, _extract_sequence, _safe_bool, _safe_float, _safe_int,
    _safe_scouted_fuel,
)


def _object(value):
    return value if isinstance(value, dict) else {}


def _similarity(error, tolerance):
    """Give normal match variation full credit, then penalize gradually."""
    return max(0.0, 1.0 - max(0.0, error - tolerance) / (2 * tolerance))


def _trend_score(identity, values, history, appearances):
    match, team = identity
    position = appearances[identity]
    # Leave the whole target robot/match out, including any duplicate scouts.
    # Nearby appearances matter more than an event-wide robot average.
    neighbors = sorted(
        ((appearances[key], other) for key, other in history.items()
         if key[1] == team and key != identity
         and abs(appearances[key] - position) <= 5),
        key=lambda item: (abs(item[0] - position), item[0]),
    )[:6]
    if len(neighbors) < 3:
        return None
    scores = []
    for phase, floor in ((0, 8.0), (1, 20.0)):
        # A robot playing defense or breaking down can legitimately score less.
        # Those booleans are context, not claims we can verify from TBA.
        if phase == 1 and (values[2] or values[3]):
            continue
        samples = [(x, other[phase]) for x, other in neighbors
                   if phase == 0 or not (other[2] or other[3])]
        if len(samples) < 3:
            continue
        # Robust local line (median pairwise slope) follows gradual improvements
        # while resisting a single bad report in the surrounding history.
        slope = median((yb - ya) / (xb - xa)
                       for i, (xa, ya) in enumerate(samples)
                       for xb, yb in samples[i + 1:] if xb != xa)
        intercept = median(y - slope * x for x, y in samples)
        predicted = max(0.0, intercept + slope * position)
        scatter = median(abs(y - (intercept + slope * x)) for x, y in samples)
        gap = min(abs(x - position) for x, _ in samples)
        tolerance = max(floor, 0.35 * predicted, 3 * scatter) + 0.2 * abs(slope) * gap
        scores.append(_similarity(abs(values[phase] - predicted), tolerance))
    return mean(scores) if scores else None


def _tba_score(identity, values, history, alliance_data):
    alliance = alliance_data[identity]
    hub = alliance["hub"]
    scores = []
    for phase, name, floor in ((0, "auto", 10.0), (1, "teleop", 30.0)):
        # Use fuel counts, never the overall score (tower and fouls differ).
        # Points are a fallback for the 2026 one-point active-hub fuel format.
        official = _safe_float(hub.get(f"{name}Count"))
        if official is None:
            official = _safe_float(hub.get(f"{name}Points"))
        if official is None or official < 0:
            continue
        extra = 0.0
        if phase == 1:
            extra = _safe_float(hub.get("uncounted"))
            # Scouting does not distinguish active/inactive-hub fuel. Without
            # this allowance the teleop comparison could punish correct counts.
            if extra is None or extra < 0:
                continue
        tolerance = max(floor, 0.25 * official)
        teammates = [(identity[0], team) for team in alliance["teams"]]
        if len(teammates) == 3 and all(key in history for key in teammates):
            total = sum(history[key][phase] for key in teammates)
            # Shared alliance compatibility, not blame assigned to one scout.
            error = max(official - total, total - official - extra, 0.0)
            scores.append(_similarity(error, tolerance))
        else:
            # Partial coverage cannot prove a report right. Only an individual
            # count exceeding the entire alliance's upper bound is evidence.
            error = max(0.0, values[phase] - official - extra)
            if error > tolerance:
                scores.append(_similarity(error, tolerance))
    return mean(scores) if scores else None


def calculate_scout_stats(members, scouting_data, matches, event):
    """Blend validity (30%), local robot trends (50%), and TBA checks (20%)."""
    scouts, identities = {}, {}
    for member in members:
        user_id = str(member.get("user_id") or "").strip()
        username = str(member.get("username") or "").strip()
        key = user_id or username
        if not key:
            continue
        scouts[key] = {
            "ScoutId": key, "Name": member.get("first_name") or username or key,
            "Username": username, "Entries": 0,
        }
        for identity in (user_id, username):
            if identity:
                identities[identity] = key

    eligible, alliance_data = set(), {}
    ordered_matches = sorted(
        (row for row in _extract_sequence(matches) if isinstance(row, dict)),
        key=lambda row: (_safe_int(row.get("match_number")) or
                         _safe_int(str(row.get("key", "")).rsplit("qm", 1)[-1]) or 0,
                         str(row.get("key", ""))),
    )
    appearances, played = {}, defaultdict(int)
    for match in ordered_matches:
        if not isinstance(match, dict) or match.get("comp_level") != "qm":
            continue
        key = match.get("key")
        if not isinstance(key, str) or not key.startswith(f"{event}_qm"):
            continue
        alliances = match.get("alliances") or {}
        # Both scores must be final before coverage earns credit.
        if any((alliances.get(color) or {}).get("score", -1) < 0
               for color in ("red", "blue")):
            continue
        for color, alliance in alliances.items():
            teams = [_safe_int(team) for team in alliance.get("team_keys", [])]
            hub = _object(_object(_object(match.get("score_breakdown")).get(color)).get("hubScore"))
            for team in teams:
                if team is None:
                    continue
                identity = (key, team)
                if identity not in eligible:
                    played[team] += 1
                    appearances[identity] = played[team]
                eligible.add(identity)
                alliance_data[identity] = {"teams": teams, "hub": hub}

    # The latest report from each scout for one robot/match gets one vote.
    reports = {}
    for document in sorted(
        (row for row in scouting_data if isinstance(row, dict)),
        key=lambda row: str(row.get("submitted_at") or ""),
    ):
        if document.get("event") != event:
            continue
        info = _object(document.get("scoutInfo"))
        scout = identities.get(str(info.get("userId") or "")) or identities.get(
            str(info.get("username") or ""))
        if scout is None:
            continue
        row = scouts[scout]
        row["Entries"] += 1
        name = str(info.get("firstName") or "").strip()
        if name:
            row["Name"] = name
        match = _canonical_match_key(event, document.get("match"))
        team = _safe_int(document.get("team"))
        data = _object(document.get("data"))
        auto, teleop, misc = (_object(data.get("autoScouting")),
                              _object(data.get("teleopScouting")), _object(data.get("misc")))
        values = (
            _safe_scouted_fuel(auto.get("fuel_scored"), maximum=MAX_SCOUTED_AUTO_FUEL),
            _safe_scouted_fuel(teleop.get("fuel_scored"), maximum=MAX_SCOUTED_TELEOP_FUEL),
            _safe_bool(misc.get("died")), _safe_bool(misc.get("defense")),
        )
        # Missing match/team identities cannot collapse unrelated bad reports.
        identity = (match, team) if match and team else ("invalid", row["Entries"])
        reports[(scout, identity)] = (values, (match, team) in eligible)

    quality, credit = defaultdict(list), defaultdict(float)
    trends, tba_checks, checked_entries = defaultdict(list), defaultdict(list), defaultdict(set)
    coverage = defaultdict(dict)
    for (scout, identity), (values, valid_match) in reports.items():
        quality[scout].append(sum(value is not None for value in values) / 4 if valid_match else 0)
        if valid_match and all(value is not None for value in values):
            coverage[identity][scout] = values

    # Collapse duplicate observers into one robot/match history observation.
    history = {
        identity: tuple(median(values[index] for values in observers.values())
                        if index < 2 else any(values[index] for values in observers.values())
                        for index in range(4))
        for identity, observers in coverage.items()
    }
    for identity, observers in coverage.items():
        for scout, values in observers.items():
            credit[scout] += 1 / len(observers)
            trend = _trend_score(identity, values, history, appearances)
            tba = _tba_score(identity, values, history, alliance_data)
            if trend is not None:
                trends[scout].append(trend)
            if tba is not None:
                tba_checks[scout].append(tba)
            if trend is not None or tba is not None:
                checked_entries[scout].add(identity)

    total_credit = len(coverage)
    for scout, row in scouts.items():
        checked = len(checked_entries[scout])
        completeness = mean(quality[scout]) if quality[scout] else 0
        # Each channel has five neutral prior reports. Missing evidence retains
        # its neutral weight instead of making the remaining source dominate.
        trend = (sum(trends[scout]) + 2.5) / (len(trends[scout]) + 5)
        tba = (sum(tba_checks[scout]) + 2.5) / (len(tba_checks[scout]) + 5)
        row.update({
            "TrustRating": round(100 * (0.30 * completeness + 0.50 * trend + 0.20 * tba), 1)
            if row["Entries"] else None,
            "Contribution": round(100 * credit[scout] / total_credit, 2) if total_credit else 0.0,
            "CoverageCredit": round(credit[scout], 3),
            "CheckedEntries": checked,
            "ComparedEntries": checked,  # Compatibility with the first UI.
            "TrendEntries": len(trends[scout]),
            "TBAEntries": len(tba_checks[scout]),
            "ValidityScore": round(100 * completeness, 1),
            "TrendScore": round(100 * trend, 1),
            "TBAScore": round(100 * tba, 1),
            "TrustMethod": "robot_trend_tba_v2",
            "UniqueEntries": len(quality[scout]),
            "ValidEntries": sum(scout in observers for observers in coverage.values()),
            "Provisional": checked < 5 or len(trends[scout]) < 3,
        })
    return sorted(scouts.values(), key=lambda row: (row["Name"].casefold(), row["ScoutId"]))
