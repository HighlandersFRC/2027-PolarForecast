"""Prepare Stats/GroupStats rows using the OPR calculator in analysis.py."""

from collections import defaultdict
from typing import Any

from .analysis import OPR
from .scouting import (
    _extract_sequence,
    analyze_scout_data,
    fuse_scouting_fuel,
    rankings,
)


def calculate_event_stats(
    matches: Any,
    rankings_data: Any = None,
    *,
    scouting_data: Any = None,
) -> list[dict]:
    """Calculate TBA OPR, then apply a bounded group-only fuel correction."""
    raw_matches = _extract_sequence(matches)
    opr = OPR()
    for match in raw_matches:
        opr.addMatch(match)
    calculated = opr.calculate()

    match_counts = defaultdict(int)
    for alliance in opr.matches:
        for team in set(alliance["teams"]):
            match_counts[int(team)] += 1

    scouted = analyze_scout_data(scouting_data)
    calculated, fusion = fuse_scouting_fuel(
        raw_matches, opr, calculated, scouted, match_counts,
    )
    results = []
    for team in {int(team) for team in calculated} | set(scouted):
        values = calculated.get(str(team), {
            "autoOPR": None,
            "teleopOPR": None,
            "towerOPR": None,
            "totalOPR": None,
        })
        scouting = scouted.get(team, {})
        results.append({
            "Team": team,
            "Rank": rankings(rankings_data, f"frc{team}"),
            **values,
            "MatchesPlayed": match_counts.get(team, 0),
            "ScoutEntries": scouting.get("ScoutEntries", 0),
            "ScoutedMatches": scouting.get("ScoutedMatches", 0),
            "AverageAutoFuel": scouting.get("AverageAutoFuel"),
            "AverageTeleopFuel": scouting.get("AverageTeleopFuel"),
            "AverageTotalFuel": scouting.get("AverageTotalFuel"),
            "DeathRate": scouting.get("DeathRate", 0.0),
            "DefenseRate": scouting.get("DefenseRate", 0.0),
            "DiedCount": scouting.get("DiedCount", 0),
            "DefenseCount": scouting.get("DefenseCount", 0),
            "DeathSamples": scouting.get("DeathSamples", 0),
            "DefenseSamples": scouting.get("DefenseSamples", 0),
            "Comments": scouting.get("Comments", []),
            "ScoutingHistory": scouting.get("ScoutingHistory", []),
            "ScoutingMatchHistory": scouting.get("ScoutingMatchHistory", []),
            **({"ScoutingFusion": fusion[team]} if team in fusion else {}),
        })
    results.sort(key=lambda row: (
        row["totalOPR"] is None,
        -(row["totalOPR"] or 0.0),
        row["Team"],
    ))
    return results
