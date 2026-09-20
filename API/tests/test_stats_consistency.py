import unittest
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient

from api import app


class StatsConsistencyTests(unittest.TestCase):
    def setUp(self):
        self.public = [{"Team": 1741, "OPR": 40.0}]
        self.group = [{"Team": 1741, "OPR": 55.0}]
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
        }
        self.collections["GroupStatsCollection"].find_one.return_value = {
            "data": self.group,
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
        }
        self.assert_same_stats(self.public, "scout")

    def test_existing_clients_read_updated_stats_on_next_request(self):
        self.assert_same_stats(self.group, "scout")
        self.group[0]["OPR"] = 72.0
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


if __name__ == "__main__":
    unittest.main()
