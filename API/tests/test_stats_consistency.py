import unittest
from dataclasses import fields
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient

from api import app, GROUP_STATS_CACHE_VERSION, STATS_CACHE_VERSION
from fastapi import FastAPI
from routers.data import DataDependencies, create_data_router


class StatsConsistencyTests(unittest.TestCase):
    def setUp(self):
        self.public = [{"Team": 1741, "totalOPR": 40.0}]
        self.group = [{"Team": 1741, "totalOPR": 45.0, "AverageAutoFuel": 8.0}]
        self.collections = {}
        for name in (
            "StatsCollection", "GroupStatsCollection",
            "GroupMembersCollection", "GroupsCollection",
        ):
            collection = Mock()
            self.collections[name] = collection
            patcher = patch(f"api.{name}", collection)
            patcher.start()
            self.addCleanup(patcher.stop)

        self.collections["StatsCollection"].find_one.return_value = {
            "data": self.public,
            "cache_version": STATS_CACHE_VERSION,
        }
        self.collections["GroupStatsCollection"].find_one.return_value = {
            "data": self.group,
            "cache_version": GROUP_STATS_CACHE_VERSION,
        }
        self.collections["GroupMembersCollection"].find_one.return_value = {
            "group_id": "group-1",
        }
        self.collections["GroupsCollection"].find_one.return_value = {"_id": 1}
        # No lifespan context: these tests must not start the TBA updater.
        self.client = TestClient(app)
        self.addCleanup(self.client.close)

    def assert_same_stats(self, expected, username=None):
        params = {"username": username} if username is not None else {}
        event = self.client.get("/2026test/stats", params=params)
        team = self.client.get("/2026test/event/frc1741/team", params=params)
        self.assertEqual(event.status_code, 200)
        self.assertEqual(team.status_code, 200)
        self.assertEqual(event.json(), expected)
        self.assertEqual(team.json()["stats"], expected[0])
        self.assertEqual(team.json()["team"], 1741)
        for response in (event, team):
            self.assertEqual(response.headers["cache-control"], "no-store")

    def test_logged_out_devices_use_public_stats_on_both_pages(self):
        self.assert_same_stats(self.public)
        self.collections["GroupMembersCollection"].find_one.assert_not_called()

    def test_logged_in_devices_use_group_stats_on_both_pages(self):
        self.assert_same_stats(self.group, " scout ")
        self.assertEqual(
            self.collections["GroupMembersCollection"].find_one.call_args.args[0],
            {"username": "scout"},
        )

    def test_both_pages_fall_back_when_user_has_no_group(self):
        self.collections["GroupMembersCollection"].find_one.return_value = None
        self.assert_same_stats(self.public, "scout")

    def test_both_pages_fall_back_when_group_does_not_have_event(self):
        self.collections["GroupsCollection"].find_one.return_value = None
        self.assert_same_stats(self.public, "scout")

    def test_both_pages_fall_back_when_group_stats_are_empty(self):
        self.collections["GroupStatsCollection"].find_one.return_value = {
            "data": [],
            "cache_version": GROUP_STATS_CACHE_VERSION,
        }
        self.assert_same_stats(self.public, "scout")

    def test_both_pages_build_missing_group_analysis_before_responding(self):
        self.collections["GroupStatsCollection"].find_one.return_value = None
        with patch("api.rebuild_group_stats", return_value=self.group) as rebuild:
            self.assert_same_stats(self.group, "scout")
        self.assertEqual(rebuild.call_count, 2)
        rebuild.assert_called_with("group-1", "2026test")

    def test_both_pages_rebuild_old_group_calculations(self):
        self.collections["GroupStatsCollection"].find_one.return_value = {
            "data": [{"Team": 1741, "OPR": 99.0}],
            "cache_version": GROUP_STATS_CACHE_VERSION - 1,
        }
        with patch("api.rebuild_group_stats", return_value=self.group):
            self.assert_same_stats(self.group, "scout")

    def test_saved_report_invalidates_old_stats_when_immediate_rebuild_fails(self):
        group_cache = self.collections["GroupStatsCollection"]
        cached = group_cache.find_one.return_value

        def invalidate(query, update):
            for key in update.get("$unset", {}):
                cached.pop(key, None)

        group_cache.update_one.side_effect = invalidate
        report = {
            "event": "2026test", "match": "2", "team": 1741, "groupId": "group-1",
            "scoutInfo": {"userId": "scout", "username": "scout", "firstName": "Scout", "team": "1741"},
            "data": {
                "autoPath": {"path": []},
                "autoScouting": {"fuel_scored": 12},
                "teleopScouting": {"fuel_scored": 60},
                "misc": {"died": False, "defense": False, "comments": ""},
            },
        }
        with (
            patch("api.scout_info_is_current_group_member", return_value=True),
            patch("api.MatchScoutingCollection"),
            patch("api.rebuild_group_stats", side_effect=RuntimeError("temporary rebuild failure")),
            patch("builtins.print"),
        ):
            response = self.client.post("/matchscouting", json=report)
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()["group_stats_refreshed"])
        self.assertNotIn("cache_version", cached)
        group_cache.update_one.assert_called_once_with(
            {"group_id": "group-1", "event_key": "2026test"},
            {"$unset": {"cache_version": ""}},
        )
        with patch("api.rebuild_group_stats", return_value=self.group) as retry:
            self.assert_same_stats(self.group, "scout")
        retry.assert_called_with("group-1", "2026test")

    def test_logging_out_immediately_returns_public_tba_on_both_pages(self):
        self.assert_same_stats(self.group, "scout")
        self.assert_same_stats(self.public)

    def test_logged_out_pages_rebuild_old_public_calculations(self):
        self.collections["StatsCollection"].find_one.return_value = {
            "data": [{"Team": 1741, "OPR": 99.0}],
            "cache_version": STATS_CACHE_VERSION - 1,
        }
        with patch("api.save_stats", return_value=self.public) as rebuild:
            self.assert_same_stats(self.public)
        self.assertEqual(rebuild.call_count, 2)
        self.collections["GroupMembersCollection"].find_one.assert_not_called()

    def test_existing_clients_read_updated_stats_on_next_request(self):
        self.assert_same_stats(self.group, "scout")
        self.group[0]["totalOPR"] = 72.0
        self.assert_same_stats(self.group, "scout")

    def test_stats_errors_cannot_be_cached(self):
        for path, expected_code in (
            ("/2026test/event/unknown/team", 400),
            ("/2026test/event/9999/team", 404),
        ):
            response = self.client.get(path)
            self.assertEqual(response.status_code, expected_code)
            self.assertEqual(response.headers["cache-control"], "no-store")

    def test_missing_event_is_consistent(self):
        self.collections["StatsCollection"].find_one.return_value = None
        for path in ("/2026test/stats", "/2026test/event/1741/team"):
            response = self.client.get(path)
            self.assertEqual(response.status_code, 404)
            self.assertEqual(response.headers["cache-control"], "no-store")


class GroupRouteCacheTests(unittest.TestCase):
    def test_explicit_group_routes_rebuild_older_non_fused_caches(self):
        for path in (
            "/groups/group-1/events/2026test/stats",
            "/groups/group-1/events/2026test/teams/1741/stats",
        ):
            with self.subTest(path=path):
                values = {field.name: Mock() for field in fields(DataDependencies)}
                values.update(year="2026", group_stats_cache_version=GROUP_STATS_CACHE_VERSION)
                dependencies = DataDependencies(**values)
                fresh = {"cache_version": GROUP_STATS_CACHE_VERSION,
                         "data": [{"Team": 1741, "totalOPR": 45.0}]}
                dependencies.group_stats_collection.find_one.side_effect = [
                    {"cache_version": GROUP_STATS_CACHE_VERSION - 1,
                     "data": [{"Team": 1741, "totalOPR": 40.0}]},
                    fresh,
                ]
                application = FastAPI()
                application.include_router(create_data_router(dependencies))
                with TestClient(application) as client:
                    response = client.get(path, params={"username": "scout"})
                self.assertEqual(response.status_code, 200)
                payload = response.json()
                row = payload["stats"] if "stats" in payload else payload["data"][0]
                self.assertEqual(row["totalOPR"], 45.0)
                dependencies.rebuild_group_stats.assert_called_once_with("group-1", "2026test")


if __name__ == "__main__":
    unittest.main()
