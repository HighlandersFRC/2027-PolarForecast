from copy import deepcopy
import unittest
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient

from analysis.analysis import OPR
from analysis.event_stats import calculate_event_stats
from Predictions import fit_opr_from_completed_matches


def match(number=1, red=(1, 2, 3), blue=(4, 5, 6), total=101.0):
    return {
        "key": f"2026test_qm{number}",
        "comp_level": "qm",
        "match_number": number,
        "set_number": 1,
        "alliances": {
            "red": {"team_keys": [f"frc{team}" for team in red], "score": 999},
            "blue": {"team_keys": [f"frc{team}" for team in blue], "score": 888},
        },
        "score_breakdown": {
            color: {
                "totalAutoPoints": 10.25,
                "totalTeleopPoints": 50.125,
                "totalTowerPoints": 11.5,
                "totalPoints": total,
                "hubScore": {"autoPoints": 2.0, "teleopPoints": 6.0},
            }
            for color in ("red", "blue")
        },
    }


def scouting(team=1, auto=6, teleop=4):
    return {
        "event": "2026test", "match": "1", "team": team,
        "groupId": "group-1",
        "data": {
            "autoScouting": {"fuel_scored": auto},
            "teleopScouting": {"fuel_scored": teleop},
            "misc": {"died": True, "defense": True, "comments": "Good defense"},
        },
    }


class ExactOprTests(unittest.TestCase):
    def setUp(self):
        self.matches = [match(), match(2, (1, 4, 5), (2, 3, 6), 123.456789)]
        self.rankings = {"rankings": [{"team_key": "frc1", "rank": 2}]}

    def calculate(self, scout_data):
        return {
            row["Team"]: row
            for row in calculate_event_stats(
                self.matches, self.rankings, scouting_data=scout_data,
            )
        }

    def direct(self):
        opr = OPR()
        for raw in self.matches:
            opr.addMatch(raw)
        return opr.calculate()

    def test_api_values_are_exactly_the_calculator_results(self):
        before = deepcopy(self.matches)
        actual = self.calculate([])
        for team, values in self.direct().items():
            self.assertEqual({key: actual[int(team)][key] for key in values}, values)
        self.assertEqual(self.matches, before)
        self.assertEqual(actual[1]["Rank"], 2)
        self.assertEqual(actual[1]["MatchesPlayed"], 2)
        self.assertNotEqual(actual[1]["totalOPR"], round(actual[1]["totalOPR"], 1))

    def test_group_scouting_adjusts_only_observed_team_fuel(self):
        public = self.calculate([])
        group = self.calculate([scouting()])
        self.assertNotEqual(public[1]["totalOPR"], group[1]["totalOPR"])
        self.assertNotEqual(public[1]["autoOPR"], group[1]["autoOPR"])
        self.assertNotEqual(public[1]["teleopOPR"], group[1]["teleopOPR"])
        self.assertEqual(public[1]["towerOPR"], group[1]["towerOPR"])
        for team in public.keys() - {1}:
            for key in ("autoOPR", "teleopOPR", "towerOPR", "totalOPR"):
                self.assertEqual(public[team][key], group[team][key])
        self.assertEqual(group[1]["AverageAutoFuel"], 6)
        self.assertEqual(group[1]["AverageTeleopFuel"], 4)
        self.assertEqual(group[1]["AverageTotalFuel"], 10)
        self.assertEqual(group[1]["DeathRate"], 1)
        self.assertEqual(group[1]["DefenseRate"], 1)
        self.assertEqual(group[1]["Comments"], ["Good defense"])
        self.assertEqual(group[1]["ScoutedMatches"], 1)
        self.assertEqual(group[1]["ScoutingMatchHistory"][0]["Match"], "2026test_qm1")
        for obsolete in ("OPR", "MatchHistory", "CombinedFuelOPR", "FuelOPRWeights", "OPRMethod"):
            self.assertNotIn(obsolete, group[1])

    def test_missing_and_outlier_fuel_stay_missing(self):
        for auto in (None, 11191.5):
            result = self.calculate([scouting(auto=auto)])[1]
            self.assertIsNone(result["AverageAutoFuel"])
            self.assertIsNone(result["AverageTotalFuel"])
            self.assertEqual(result["AverageTeleopFuel"], 4)
            self.assertEqual(result["autoOPR"], self.direct()["1"]["autoOPR"])
            self.assertEqual(result["ScoutingFusion"]["auto_weight"], 0.0)

    def test_zero_is_measured_and_scout_only_team_has_no_invented_opr(self):
        result = self.calculate([scouting(team=99, auto=0, teleop=0)])[99]
        self.assertIsNone(result["totalOPR"])
        self.assertEqual(result["MatchesPlayed"], 0)
        self.assertEqual(result["AverageTotalFuel"], 0)

    def test_playoffs_unplayed_and_missing_breakdowns_use_calculator_rules(self):
        playoff = match(3, total=9999)
        playoff["comp_level"] = "sf"
        upcoming = match(4, total=8888)
        for alliance in upcoming["alliances"].values():
            alliance["score"] = -1
        missing = match(5)
        missing["score_breakdown"] = None
        expected = self.direct()
        self.matches += [playoff, upcoming, missing]
        actual = self.calculate([])
        for team, values in expected.items():
            self.assertEqual({key: actual[int(team)][key] for key in values}, values)
        self.assertEqual(actual[1]["MatchesPlayed"], 2)

    def test_negative_coefficients_are_not_clamped(self):
        self.matches = [match(1, (1, 2), (3,), 10), match(2, (1,), (3,), 20)]
        self.assertLess(self.direct()["2"]["totalOPR"], 0)
        actual = self.calculate([])
        self.assertEqual(actual[2]["totalOPR"], self.direct()["2"]["totalOPR"])

    def test_predictions_use_the_same_exact_total_opr(self):
        self.assertEqual(
            fit_opr_from_completed_matches(self.matches),
            {int(team): values["totalOPR"] for team, values in self.direct().items()},
        )

    def test_empty_event(self):
        self.matches = []
        self.assertEqual(self.calculate([]), {})


class ConservativeScoutingFusionTests(unittest.TestCase):
    def setUp(self):
        self.matches = [self.fuel_match(1), self.fuel_match(2)]

    @staticmethod
    def fuel_match(number):
        raw = match(number, red=(1,), blue=(2,))
        for breakdown in raw["score_breakdown"].values():
            breakdown.update({
                "totalAutoPoints": 12.0,
                "totalTeleopPoints": 44.0,
                "totalTowerPoints": 12.0,
                "totalPoints": 70.0,
                "hubScore": {"autoPoints": 2.0, "teleopPoints": 40.0},
            })
        return raw

    def calculate(self, observations):
        return {
            row["Team"]: row
            for row in calculate_event_stats(self.matches, scouting_data=observations)
        }

    @staticmethod
    def observation(number, **kwargs):
        entry = scouting(auto=12, teleop=60, **kwargs)
        entry["match"] = str(number)
        return entry

    def test_partial_coverage_only_adjusts_fuel_and_preserves_other_points(self):
        before = deepcopy(self.matches)
        public = self.calculate([])
        fused = self.calculate([self.observation(1)])
        self.assertAlmostEqual(fused[1]["autoOPR"], 13.5)
        self.assertAlmostEqual(fused[1]["teleopOPR"], 47.0)
        self.assertAlmostEqual(fused[1]["totalOPR"], 74.5)
        self.assertEqual(fused[1]["towerOPR"], public[1]["towerOPR"])
        self.assertAlmostEqual(
            fused[1]["totalOPR"] - fused[1]["autoOPR"] - fused[1]["teleopOPR"],
            public[1]["totalOPR"] - public[1]["autoOPR"] - public[1]["teleopOPR"],
        )
        self.assertEqual(fused[2], public[2])
        self.assertEqual(fused[1]["ScoutingFusion"]["auto_weight"], 0.15)
        self.assertEqual(self.matches, before)

    def test_two_scouted_matches_at_full_coverage_are_capped_at_thirty_percent(self):
        fused = self.calculate([self.observation(1), self.observation(2)])[1]
        self.assertEqual(fused["ScoutingFusion"]["auto_weight"], 0.30)
        self.assertEqual(fused["ScoutingFusion"]["teleop_weight"], 0.30)
        self.assertAlmostEqual(fused["autoOPR"], 15.0)
        self.assertAlmostEqual(fused["teleopOPR"], 50.0)
        self.assertAlmostEqual(fused["totalOPR"], 79.0)

    def test_two_reports_out_of_ten_matches_have_six_percent_weight(self):
        self.matches = [self.fuel_match(number) for number in range(1, 11)]
        fused = self.calculate([self.observation(1), self.observation(2)])[1]
        self.assertEqual(fused["ScoutingFusion"]["auto_weight"], 0.06)
        self.assertAlmostEqual(fused["totalOPR"], 71.8)

    def test_duplicate_reports_do_not_increase_match_coverage(self):
        single = self.calculate([self.observation(1)])[1]
        duplicate = self.calculate([self.observation(1)] * 20)[1]
        for key in ("autoOPR", "teleopOPR", "towerOPR", "totalOPR", "ScoutingFusion"):
            self.assertEqual(single[key], duplicate[key])

    def test_zero_fuel_is_evidence_but_missing_phase_is_not_zero(self):
        public = self.calculate([])[1]
        fused = self.calculate([scouting(auto=None, teleop=0)])[1]
        self.assertEqual(fused["autoOPR"], public["autoOPR"])
        self.assertAlmostEqual(fused["teleopOPR"], 38.0)
        self.assertAlmostEqual(fused["totalOPR"], 64.0)
        self.assertEqual(fused["ScoutingFusion"]["auto_weight"], 0)
        self.assertEqual(fused["ScoutingFusion"]["teleop_matches"], 1)

    def test_playoffs_upcoming_wrong_event_and_wrong_alliance_do_not_adjust_opr(self):
        playoff = self.fuel_match(3)
        playoff.update(comp_level="sf", key="2026test_sf1m1")
        upcoming = self.fuel_match(4)
        for alliance in upcoming["alliances"].values():
            alliance["score"] = -1
        self.matches.extend([playoff, upcoming])
        public = self.calculate([])
        observations = [self.observation("sf1m1"), self.observation(4)]
        other_event = self.observation(1)
        other_event["event"] = "2026other"
        observations += [other_event, self.observation(1, team=99)]
        fused = self.calculate(observations)
        for key in ("autoOPR", "teleopOPR", "towerOPR", "totalOPR"):
            self.assertEqual(fused[1][key], public[1][key])
        self.assertIsNone(fused[99]["totalOPR"])
        # Team 1 did not play this completed match, although it was scouted for it.
        self.matches.append(match(5, red=(3,), blue=(4,)))
        public = self.calculate([])
        fused = self.calculate([self.observation(5)])
        self.assertEqual(fused[1]["totalOPR"], public[1]["totalOPR"])

    def test_missing_tba_fuel_keeps_that_phase_unchanged(self):
        self.matches[0]["score_breakdown"]["blue"]["hubScore"].pop("autoPoints")
        public = self.calculate([])[1]
        fused = self.calculate([self.observation(1)])[1]
        self.assertEqual(fused["autoOPR"], public["autoOPR"])
        self.assertEqual(fused["ScoutingFusion"]["auto_weight"], 0)
        self.assertGreater(fused["teleopOPR"], public["teleopOPR"])


class StatsPipelineTests(unittest.TestCase):
    def test_two_scouting_submissions_change_event_and_team_stats_only_for_the_group(self):
        import api
        matches = [match(number, red=(4499, 1, 2), blue=(3, 4, 5)) for number in range(1, 13)]
        public = calculate_event_stats(matches)
        cache = {"data": public, "cache_version": api.GROUP_STATS_CACHE_VERSION}
        reports = []

        def save_cache(query, update, **kwargs):
            for key in update.get("$unset", {}):
                cache.pop(key, None)
            cache.update(update.get("$set", {}))

        def save_report(document):
            reports.append(deepcopy(document))
            return Mock(inserted_id=str(len(reports)))

        with (
            patch("api.GroupStatsCollection") as group_cache,
            patch("api.StatsCollection") as public_cache,
            patch("api.MatchScoutingCollection") as scouting_collection,
            patch("api.GroupsCollection") as groups,
            patch("api.GroupMembersCollection") as members,
            patch("api.get_cached_event_analysis_inputs", return_value=(matches, {})),
        ):
            group_cache.find_one.return_value = cache
            group_cache.update_one.side_effect = save_cache
            public_cache.find_one.return_value = {
                "data": public, "cache_version": api.STATS_CACHE_VERSION,
            }
            scouting_collection.insert_one.side_effect = save_report
            scouting_collection.find.return_value = reports
            groups.find_one.return_value = {"group_id": "group-1", "events": ["2026test"]}
            members.find_one.return_value = {"group_id": "group-1"}
            members.find.return_value = [{"username": "scout", "user_id": "scout"}]
            client = TestClient(api.app)
            self.addCleanup(client.close)

            for number, auto, teleop in ((1, 0, 0), (2, 130, 575)):
                report = scouting(team=4499, auto=auto, teleop=teleop)
                report["match"] = str(number)
                report["scoutInfo"] = {
                    "userId": "scout", "username": "scout", "firstName": "Scout", "team": "4499",
                }
                report["data"]["autoPath"] = {"path": []}
                report["data"]["misc"]["died"] = False
                response = client.post("/matchscouting", json=report)
                self.assertEqual(response.status_code, 200, response.text)
                self.assertTrue(response.json()["group_stats_refreshed"])

            event = client.get("/2026test/stats", params={"username": "scout"}).json()
            team = client.get("/2026test/event/4499/team", params={"username": "scout"}).json()["stats"]
            self.assertEqual(team, next(row for row in event if row["Team"] == 4499))
            self.assertEqual(team["ScoutedMatches"], 2)
            self.assertAlmostEqual(team["ScoutingFusion"]["auto_weight"], 0.05)
            public_team = next(row for row in public if row["Team"] == 4499)
            for key in ("autoOPR", "teleopOPR", "totalOPR"):
                self.assertNotEqual(team[key], public_team[key])
            self.assertEqual(team["towerOPR"], public_team["towerOPR"])
            self.assertEqual(client.get("/2026test/stats").json(), public)
            public_cache.update_one.assert_not_called()

    def test_refresh_saves_exact_analysis_results_to_stats_and_refreshes_groups(self):
        import api
        matches = [match()]
        rankings = {"rankings": []}
        raw = OPR()
        raw.addMatch(matches[0])
        with (
            patch("api.TBACollection") as tba,
            patch("api.StatsCollection") as public_cache,
            patch("api.refresh_event_predictions", return_value={}) as predictions,
            patch("api.refresh_group_stats_for_event") as groups,
        ):
            stats, _ = api.build_and_save_event("2026test", matches, rankings)
        self.assertEqual(public_cache.update_one.call_args.args[1]["$set"]["data"], stats)
        self.assertEqual(
            {
                str(row["Team"]): {
                    key: row[key]
                    for key in ("autoOPR", "teleopOPR", "towerOPR", "totalOPR")
                }
                for row in stats
            },
            raw.calculate(),
        )
        self.assertEqual(public_cache.update_one.call_args.args[1]["$set"]["cache_version"], api.STATS_CACHE_VERSION)
        predictions.assert_called_once_with("2026test", matches)
        groups.assert_called_once_with(event="2026test", matches=matches, rankings_data=rankings)
        self.assertEqual(tba.update_one.call_count, 1)

    def test_group_rebuild_attaches_only_its_scouting_data(self):
        import api
        matches = [match()]
        with (
            patch("api.GroupsCollection") as groups,
            patch("api.get_group_match_scouting", return_value=[scouting()]) as scouting_data,
            patch("api.get_group_member_identity_sets", return_value=([], set(), set())),
            patch("api.save_group_stats") as save,
        ):
            groups.find_one.return_value = {"group_id": "group-1"}
            stats = api.rebuild_group_stats("group-1", "2026test", matches, {"rankings": []})
        scouting_data.assert_called_once_with(group_id="group-1", event="2026test")
        team = next(row for row in stats if row["Team"] == 1)
        self.assertEqual(team["AverageAutoFuel"], 6)
        public_team = next(
            row for row in calculate_event_stats(matches) if row["Team"] == 1
        )
        self.assertNotEqual(team["totalOPR"], public_team["totalOPR"])
        self.assertEqual(save.call_args.kwargs["stats_data"], stats)


if __name__ == "__main__":
    unittest.main()
