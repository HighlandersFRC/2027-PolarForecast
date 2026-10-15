from datetime import datetime, timedelta, timezone
from unittest import TestCase
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient

from global_rankings import GlobalRankings, RankingSnapshotExpired


class GlobalRankingsTests(TestCase):
    def setUp(self):
        self.now = datetime(2026, 10, 14, tzinfo=timezone.utc)
        self.stats, self.events, self.etags, self.tba = Mock(), Mock(), Mock(), Mock()
        self.events.find_one.return_value = {"data": [
            {"key": "2026old", "name": "Earlier Event", "start_date": "2026-03-01", "end_date": "2026-03-03"},
            {"key": "2026new", "name": "Latest Event", "start_date": "2026-04-01", "end_date": "2026-04-03"},
            {"key": "2026future", "name": "Upcoming Event", "start_date": "2026-11-01", "end_date": "2026-11-03"},
        ]}
        self.documents = [{"event_key": "2026old", "data": [self.row(1, 50)]}]
        self.stats.find.side_effect = lambda *args: self.documents
        self.etags.find_one.return_value = None
        self.tba.side_effect = lambda path, **kwargs: [
            {"team_number": team, "nickname": f"Robot {team}"}
            for team in range(int(path.split('/')[2]) * 500, (int(path.split('/')[2]) + 1) * 500)
        ]
        self.service = GlobalRankings(self.stats, self.events, self.etags, self.tba,
                                      "2026", 5, clock=lambda: self.now)

    @staticmethod
    def row(team, opr, played=10, auto=None, teleop=None):
        return {"Team": team, "totalOPR": opr, "autoOPR": auto,
                "teleopOPR": teleop, "MatchesPlayed": played}

    def test_latest_event_replaces_old_opr_without_averaging_or_using_cache_write_order(self):
        self.documents[0]["updated_at"] = "2026-10-14"
        self.documents += [
            {"event_key": "2026new", "updated_at": "2026-04-03", "data": [self.row(1, 12.3456789, auto=3.12567, teleop=8.23456)]},
            {"event_key": "2026future", "data": [self.row(1, 999, played=0)]},
        ]
        result = self.service.page()["data"]
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["opr"], 12.3456789)
        self.assertEqual(result[0]["auto"], 3.12567)
        self.assertEqual(result[0]["teleop"], 8.23456)
        self.assertEqual(result[0]["event_key"], "2026new")
        self.assertEqual(result[0]["name"], "Robot 1")
        self.assertEqual(self.stats.find.call_args.args[0]["cache_version"], 5)

    def test_fifty_at_a_time_without_duplicate_teams_and_stable_tie_order(self):
        self.documents[0]["data"] = [self.row(team, 100) for team in range(1, 3001)]
        first = self.service.page()
        second = self.service.page(offset=50, snapshot=first["snapshot"])
        self.assertEqual((first["total"], len(first["data"]), len(second["data"])), (3000, 50, 50))
        self.assertEqual(first["next_offset"], 50)
        self.assertEqual([row["team"] for row in first["data"]], list(range(1, 51)))
        self.assertEqual([row["team"] for row in second["data"]], list(range(51, 101)))
        self.assertNotIn("avatar", first["data"][0])
        self.stats.find.assert_called_once()

    def test_search_covers_unloaded_teams_and_preserves_global_rank(self):
        self.documents[0]["data"] = [self.row(team, 4000 - team) for team in range(1, 3001)]
        for query in ("2999", "frc2999", "rObOt 2999"):
            result = self.service.page(query=query)
            self.assertEqual(result["matched"], 1)
            self.assertEqual(result["data"][0]["team"], 2999)
            self.assertEqual(result["data"][0]["rank"], 2999)

    def test_negative_opr_is_kept_and_missing_nonfinite_or_unplayed_values_are_excluded(self):
        self.documents[0]["data"] = [self.row(1, -3.125), self.row(2, None),
                                      self.row(3, float('nan')), self.row(4, float('inf')),
                                      self.row(5, 99, played=0), self.row(6, True)]
        result = self.service.page()["data"]
        self.assertEqual([(row["team"], row["opr"]) for row in result], [(1, -3.125)])

    def test_refresh_after_five_minutes_keeps_an_existing_pagination_snapshot_stable(self):
        self.documents[0]["data"] = [self.row(team, 100 - team) for team in range(1, 101)]
        first = self.service.page()
        self.documents[0]["data"][0]["totalOPR"] = -999
        self.now += timedelta(seconds=299)
        self.assertEqual(self.service.page()["snapshot"], first["snapshot"])
        self.now += timedelta(seconds=1)
        fresh = self.service.page()
        self.assertNotEqual(fresh["snapshot"], first["snapshot"])
        self.assertEqual(fresh["data"][0]["team"], 2)
        old_second = self.service.page(offset=50, snapshot=first["snapshot"])
        self.assertEqual(old_second["data"][0]["team"], 51)
        self.now += timedelta(minutes=30)
        with self.assertRaises(RankingSnapshotExpired):
            self.service.page(offset=50, snapshot=first["snapshot"])

    def test_daily_name_cache_avoids_upstream_requests_and_works_during_outages(self):
        self.etags.find_one.return_value = {
            "date": self.now.date().isoformat(),
            "teams": [{"team_number": 1, "nickname": "Polar Robotics"}],
        }
        self.assertEqual(self.service.page()["data"][0]["name"], "Polar Robotics")
        self.tba.assert_not_called()
        self.now += timedelta(days=1)
        self.tba.side_effect = None
        self.tba.return_value = None
        self.assertEqual(self.service.page()["data"][0]["name"], "Polar Robotics")
        self.etags.update_one.assert_not_called()

    def test_last_page_and_search_with_no_results(self):
        self.documents[0]["data"] = [self.row(team, team) for team in range(1, 53)]
        first = self.service.page()
        last = self.service.page(offset=50, snapshot=first["snapshot"])
        self.assertEqual(len(last["data"]), 2)
        self.assertIsNone(last["next_offset"])
        self.assertEqual(self.service.page(query="no such robot")["data"], [])

    def test_transient_name_request_failure_is_retried(self):
        self.tba.side_effect = [None, [{"team_number": 1, "nickname": "Polar Robotics"}]]
        self.assertEqual(self.service.page()["data"][0]["name"], "Polar Robotics")
        self.assertEqual(self.tba.call_count, 2)

    def test_heatmap_ranges_cover_all_teams_and_stay_fixed_across_search_and_pages(self):
        self.documents[0]["data"] = [
            self.row(team, team, auto=team * 2, teleop=team * 3)
            for team in range(1, 61)
        ]
        first = self.service.page()
        expected = {"rank": {"min": 1, "max": 60}, "opr": {"min": 1, "max": 60},
                    "auto": {"min": 2, "max": 120}, "teleop": {"min": 3, "max": 180}}
        self.assertEqual(first["ranges"], expected)
        self.assertEqual(self.service.page(query="Robot 1")["ranges"], expected)
        second = self.service.page(offset=50, snapshot=first["snapshot"])
        self.assertEqual(second["ranges"], expected)

    def test_missing_invalid_phases_are_not_zero_and_scouting_fields_are_not_used(self):
        valid = self.row(1, 100, auto=10.125, teleop=80.125)
        valid.update(AverageAutoFuel=9999, AverageTeleopFuel=9999)
        self.documents[0]["data"] = [valid, self.row(2, 50, auto=float('nan'), teleop=True)]
        result = self.service.page()
        self.assertEqual(result["data"][0]["auto"], 10.125)
        self.assertEqual(result["data"][0]["teleop"], 80.125)
        self.assertIsNone(result["data"][1]["auto"])
        self.assertIsNone(result["data"][1]["teleop"])
        self.assertEqual(result["ranges"]["auto"], {"min": 10.125, "max": 10.125})


class GlobalRankingRouteTests(TestCase):
    def test_pagination_is_validated_and_expired_snapshots_can_be_restarted(self):
        import api
        client = TestClient(api.app)
        self.addCleanup(client.close)
        with patch("api.global_rankings") as rankings:
            rankings.page.return_value = {"data": [], "total": 0}
            response = client.get('/rankings/global?q=4499&offset=50&snapshot=abc')
            self.assertEqual(response.status_code, 200)
            rankings.page.assert_called_once_with(50, 50, '4499', 'abc')
            self.assertEqual(response.headers['cache-control'], 'no-store')
            for query in ('limit=51', 'limit=0', 'offset=-1', 'q=' + 'a' * 101):
                self.assertEqual(client.get('/rankings/global?' + query).status_code, 422)
            rankings.page.side_effect = RankingSnapshotExpired()
            self.assertEqual(client.get('/rankings/global?snapshot=old').status_code, 410)
