import unittest
from unittest.mock import AsyncMock, Mock, patch

from fastapi import HTTPException
from fastapi.testclient import TestClient

from api import _normalize_picklist_teams, _picklist_team_order, app


class PicklistOrderingTests(unittest.TestCase):
    def setUp(self):
        self.roster_patch = patch(
            "api.get_event_team_numbers",
            return_value=[101, 202, 303],
        )
        self.stats_patch = patch(
            "api.get_stats_from_db",
            return_value=[
                {
                    "Team": 101,
                    "Rank": 2,
                    "OPR": 50.0,
                    "DefenseRate": 0.1,
                    "DefenseCount": 1,
                },
                {
                    "Team": 202,
                    "Rank": 1,
                    "OPR": 30.0,
                    "DefenseRate": 0.2,
                    "DefenseCount": 2,
                },
                {
                    "Team": 303,
                    "Rank": 0,
                    "OPR": 40.0,
                    "DefenseRate": 0.8,
                    "DefenseCount": 5,
                },
            ],
        )
        self.roster_patch.start()
        self.stats_patch.start()
        self.addCleanup(self.roster_patch.stop)
        self.addCleanup(self.stats_patch.stop)

    def test_initial_order_uses_selected_metric(self):
        self.assertEqual(
            _picklist_team_order("2026test", "scout", "rank"),
            [202, 101, 303],
        )
        self.assertEqual(
            _picklist_team_order("2026test", "scout", "opr"),
            [101, 303, 202],
        )
        self.assertEqual(
            _picklist_team_order("2026test", "scout", "defense"),
            [303, 202, 101],
        )

    def test_non_event_teams_are_removed_from_legacy_lists(self):
        teams = _normalize_picklist_teams(
            [
                {"team": 999, "tier": "A", "note": "not attending"},
                {"team": 202, "tier": "B", "note": "keep"},
            ],
            "2026test",
            "scout",
            "manual",
            reject_non_event=False,
        )
        self.assertEqual([item["team"] for item in teams], [202, 101, 303])
        self.assertEqual(teams[0]["note"], "keep")

    def test_non_event_teams_are_rejected_on_update(self):
        with self.assertRaises(HTTPException) as context:
            _normalize_picklist_teams(
                [{"team": 999, "tier": "", "note": ""}],
                "2026test",
                "scout",
                "manual",
                reject_non_event=True,
            )
        self.assertEqual(context.exception.status_code, 400)


class PicklistRouteTests(unittest.TestCase):
    def setUp(self):
        self.collection = Mock()
        self.collection.find.return_value = []
        self.collection.find_one.return_value = {"_id": "mongo-id"}
        self.collection.delete_one.return_value = Mock(deleted_count=1)

        patchers = [
            patch("api.PicklistCollection", self.collection),
            patch("api.username_is_current_group_member", return_value=True),
            patch("api.get_event_team_numbers", return_value=[101, 202]),
            patch("api._picklist_team_order", return_value=[202, 101]),
            patch("api._broadcast_picklists", new_callable=AsyncMock),
        ]
        for patcher in patchers:
            patcher.start()
            self.addCleanup(patcher.stop)
        self.client = TestClient(app)
        self.addCleanup(self.client.close)

    def test_creates_multiple_named_picklists_with_distinct_ids(self):
        first = self.client.post(
            "/groups/group-1/events/2026test/picklists",
            json={"username": "scout", "name": "Primary", "sort_by": "rank"},
        )
        second = self.client.post(
            "/groups/group-1/events/2026test/picklists",
            json={"username": "scout", "name": "Defense", "sort_by": "defense"},
        )
        self.assertEqual(first.status_code, 201)
        self.assertEqual(second.status_code, 201)
        self.assertNotEqual(
            first.json()["picklist_id"],
            second.json()["picklist_id"],
        )
        self.assertEqual(
            [item["team"] for item in first.json()["teams"]],
            [202, 101],
        )
        self.assertEqual(self.collection.insert_one.call_count, 2)

    def test_delete_targets_only_the_selected_picklist(self):
        response = self.client.delete(
            "/groups/group-1/events/2026test/picklists/list-2",
            params={"username": "scout"},
        )
        self.assertEqual(response.status_code, 200)
        query = self.collection.delete_one.call_args.args[0]
        self.assertEqual(query["picklist_id"], "list-2")

    def test_websocket_sends_an_initial_live_snapshot(self):
        with self.client.websocket_connect(
            "/ws/groups/group-1/events/2026test/picklists?username=scout"
        ) as websocket:
            message = websocket.receive_json()
        self.assertEqual(message["type"], "picklists_snapshot")
        self.assertEqual(message["picklists"], [])


if __name__ == "__main__":
    unittest.main()
