import unittest
from dataclasses import fields
from unittest.mock import Mock, patch

from fastapi import FastAPI
from fastapi.testclient import TestClient

from analysis.scout_stats import calculate_scout_stats
from routers.data import DataDependencies, create_data_router


MEMBERS = [{"user_id": str(i), "username": f"scout{i}"} for i in (1, 2, 3)]
MATCHES = [{
    "key": "2026test_qm1", "comp_level": "qm",
    "alliances": {
        "red": {"score": 100, "team_keys": ["frc1", "frc2", "frc3"]},
        "blue": {"score": 90, "team_keys": ["frc4", "frc5", "frc6"]},
    },
}]


def report(scout=1, team=1, auto=10, teleop=40, match="1", event="2026test", died=False, defense=False):
    return {
        "event": event, "team": team, "match": match,
        "scoutInfo": {"userId": str(scout), "username": f"scout{scout}", "firstName": "Sam"},
        "data": {"autoScouting": {"fuel_scored": auto},
                 "teleopScouting": {"fuel_scored": teleop},
                 "misc": {"died": died, "defense": defense}},
    }


def calculate(reports, matches=MATCHES):
    return {row["ScoutId"]: row for row in calculate_scout_stats(MEMBERS, reports, matches, "2026test")}


def scheduled_matches(count, hub=None):
    return [{**MATCHES[0], "key": f"2026test_qm{i}", "match_number": i,
             "score_breakdown": {color: {"hubScore": hub or {}} for color in ("red", "blue")}}
            for i in range(1, count + 1)]


class ScoutStatsTests(unittest.TestCase):
    def test_no_entries_has_no_trust_but_keeps_every_member(self):
        rows = calculate([])
        self.assertEqual(len(rows), 3)
        self.assertIsNone(rows["1"]["TrustRating"])
        self.assertEqual(rows["1"]["Contribution"], 0)

    def test_without_history_or_tba_evidence_trust_is_provisional(self):
        row = calculate([report()])["1"]
        self.assertEqual(row["TrustRating"], 65)
        self.assertTrue(row["Provisional"])
        self.assertEqual(row["ComparedEntries"], 0)
        self.assertEqual(row["Contribution"], 100)

    def test_duplicate_submissions_only_increase_entries(self):
        single = calculate([report(), report(2)])
        duplicate = calculate([report(), report(), report(2)])
        for metric in ("Contribution", "TrustRating", "ComparedEntries", "CoverageCredit", "UniqueEntries"):
            self.assertEqual(single["1"][metric], duplicate["1"][metric])
        self.assertEqual(duplicate["1"]["Entries"], 2)
        self.assertEqual(duplicate["1"]["TrustRating"], 65)
        self.assertEqual(duplicate["1"]["CheckedEntries"], 0)
        self.assertEqual(duplicate["1"]["Name"], duplicate["2"]["Name"])
        self.assertNotEqual(duplicate["1"]["ScoutId"], duplicate["2"]["ScoutId"])

    def test_coverage_is_split_between_scouts_and_sums_to_100(self):
        rows = calculate([report(), report(2), report(3, team=2)])
        self.assertEqual([rows[str(i)]["Contribution"] for i in (1, 2, 3)], [25, 25, 50])

    def test_one_scout_per_robot_match_earns_trend_evidence(self):
        reports = [report(1 + i % 3, match=str(i)) for i in range(1, 8)]
        rows = calculate(reports, scheduled_matches(7))
        for row in rows.values():
            self.assertGreater(row["TrustRating"], 65)
            self.assertGreater(row["TrendEntries"], 0)
            self.assertEqual(row["TBAEntries"], 0)

    def test_robot_outlier_lowers_its_scout_rating_without_lowering_contribution(self):
        consistent = [report(1, match=str(i)) for i in range(1, 8) if i != 4]
        rows = calculate(consistent + [report(2, match="4", auto=150, teleop=600)], scheduled_matches(7))
        self.assertLess(rows["2"]["TrustRating"], rows["1"]["TrustRating"])
        self.assertGreater(rows["2"]["Contribution"], 0)
        self.assertEqual(rows["2"]["TrendEntries"], 1)

    def test_gradual_robot_improvement_is_followed_instead_of_penalized(self):
        reports = [report(1, match=str(i), auto=10 * i, teleop=40 * i) for i in range(1, 8)]
        row = calculate(reports, scheduled_matches(7))["1"]
        self.assertEqual(row["TrendEntries"], 7)
        self.assertEqual(row["TrendScore"], 79.2)
        self.assertFalse(row["Provisional"])
        # Input ordering does not change chronological trends.
        self.assertEqual(row, calculate(reports[::-1], scheduled_matches(7)[::-1])["1"])

    def test_a_target_cannot_validate_itself_and_duplicates_do_not_create_history(self):
        rows = calculate([report(1)] * 8 + [report(2)], scheduled_matches(7))
        self.assertEqual(rows["1"]["TrendEntries"], 0)
        self.assertEqual(rows["2"]["TrendEntries"], 0)

    def test_breakdown_or_defense_explains_lower_teleop(self):
        for context in ({"died": True}, {"defense": True}):
            reports = [report(1, match=str(i)) for i in range(1, 8) if i != 4]
            rows = calculate(reports + [report(2, match="4", teleop=0, **context)], scheduled_matches(7))
            self.assertGreater(rows["2"]["TrendScore"], 50)

    def test_tba_reconciles_alliance_without_duplicate_robot_coverage(self):
        matches = scheduled_matches(1, {"autoCount": 30, "teleopCount": 120, "uncounted": 0})
        rows = calculate([report(1, team=1), report(2, team=2), report(3, team=3)], matches)
        for row in rows.values():
            self.assertEqual(row["TBAEntries"], 1)
            self.assertGreater(row["TrustRating"], 65)
            self.assertEqual(row["CheckedEntries"], 1)
            self.assertTrue(row["Provisional"])

    def test_partial_alliance_cannot_earn_trust_just_by_staying_below_total(self):
        matches = scheduled_matches(1, {"autoCount": 30, "teleopCount": 120, "uncounted": 0})
        row = calculate([report()], matches)["1"]
        self.assertEqual(row["TBAEntries"], 0)
        overcount = calculate([report(auto=100, teleop=400)], matches)["1"]
        self.assertEqual(overcount["TBAEntries"], 1)
        self.assertLess(overcount["TrustRating"], 65)

    def test_uncounted_teleop_allowance_and_missing_breakdowns_are_safe(self):
        reports = [report(i, team=i, auto=10, teleop=60) for i in (1, 2, 3)]
        hub = {"autoCount": 30, "teleopCount": 120, "uncounted": 60}
        allowed = calculate(reports, scheduled_matches(1, hub))["1"]
        no_allowance = calculate(reports, scheduled_matches(1, {**hub, "uncounted": 0}))["1"]
        self.assertGreater(allowed["TrustRating"], no_allowance["TrustRating"])
        # No uncounted field means teleop is skipped; missing auto means no evidence.
        missing = calculate(reports, scheduled_matches(1, {"teleopCount": 120}))["1"]
        self.assertEqual(missing["TBAEntries"], 0)

    def test_tba_prefers_counts_and_ignores_tower_and_foul_points(self):
        hub = {"autoCount": 30, "autoPoints": 900, "teleopCount": 120, "uncounted": 0}
        reports = [report(i, team=i) for i in (1, 2, 3)]
        row = calculate(reports, scheduled_matches(1, hub))["1"]
        self.assertGreater(row["TBAScore"], 50)

    def test_missing_tba_does_not_make_trends_dominate(self):
        reports = [report(1, match=str(i)) for i in range(1, 8)]
        row = calculate(reports, scheduled_matches(7))["1"]
        self.assertEqual(row["TBAScore"], 50)
        self.assertLessEqual(row["TrustRating"], 90)

    def test_invalid_future_playoff_wrong_robot_and_wrong_event_cannot_earn_credit(self):
        for bad in (report(auto=-1), report(auto=301), report(teleop=None),
                    report(team=99), report(match="2"), report(match="sf1m1")):
            with self.subTest(report=bad):
                row = calculate([bad])["1"]
                self.assertEqual(row["Contribution"], 0)
                self.assertEqual(row["ComparedEntries"], 0)
                self.assertLess(row["TrustRating"], 65)
        self.assertEqual(calculate([report(event="2026other")])["1"]["Entries"], 0)
        upcoming = [{**MATCHES[0], "alliances": {
            **MATCHES[0]["alliances"], "red": {"score": -1, "team_keys": ["frc1"]},
        }}]
        self.assertEqual(calculate([report()], upcoming)["1"]["Contribution"], 0)

    def test_latest_report_replaces_previous_and_zero_values_are_valid(self):
        old = {**report(auto=100), "submitted_at": "2026-01-01"}
        new = {**report(auto=0, teleop=0), "submitted_at": "2026-01-02"}
        rows = calculate([new, old, report(2, auto=0, teleop=0)])
        self.assertEqual(rows["1"]["TrustRating"], 65)
        self.assertEqual(rows["1"]["ValidEntries"], 1)

    def test_nonmembers_cannot_become_scout_rows(self):
        self.assertEqual(sum(row["Entries"] for row in calculate([report(99)]).values()), 0)

    def test_storage_and_existing_team_endpoints_support_new_data_shape(self):
        import api
        teams = [{"Team": 1, "totalOPR": 42}]
        scouts = list(calculate([report()]).values())
        with patch("api.GroupStatsCollection") as collection:
            api.save_group_stats("group-1", "2026test", teams, 1, 3, scouts)
            document = collection.update_one.call_args.args[1]["$set"]
        self.assertEqual(document["data"], {"Teams": teams, "ScoutStats": scouts})
        with (patch("api.GroupMembersCollection") as members,
              patch("api.GroupsCollection") as groups,
              patch("api.GroupStatsCollection") as cache):
            members.find_one.return_value = {"group_id": "group-1"}
            groups.find_one.return_value = {"_id": 1}
            cache.find_one.return_value = document
            self.assertEqual(api.get_stats_from_db("2026test", "scout1"), teams)

        dependencies = Mock(spec=DataDependencies)
        for field in fields(DataDependencies):
            setattr(dependencies, field.name, Mock())
        dependencies.year = "2026"
        dependencies.group_stats_cache_version = api.GROUP_STATS_CACHE_VERSION
        dependencies.group_stats_collection.find_one.return_value = document
        app = FastAPI()
        app.include_router(create_data_router(dependencies))
        with TestClient(app) as client:
            response = client.get('/groups/group-1/events/2026test/stats?username=scout1')
            self.assertEqual(response.json()["data"]["ScoutStats"], scouts)
            response = client.get('/groups/group-1/events/2026test/teams/1/stats?username=scout1')
            self.assertEqual(response.json()["stats"], teams[0])
        dependencies.require_username_group_member.assert_called_with("group-1", "scout1")


if __name__ == "__main__":
    unittest.main()
