import unittest
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient

from api import app, now_utc


class TeamIdentityTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.addCleanup(self.client.close)
        self.collection = Mock()
        self.collection.find_one.return_value = None
        patcher = patch('api.ETagsCollection', self.collection)
        patcher.start()
        self.addCleanup(patcher.stop)

    @patch('api.get_tba_json')
    def test_name_and_avatar_are_cached(self, tba):
        tba.side_effect = [
            {'nickname': 'Polar Robotics'},
            [{'type': 'avatar', 'details': {'base64Image': 'cG5n'}}],
        ]
        response = self.client.get('/teams/123/identity?year=2026')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {
            'team': 123, 'name': 'Polar Robotics', 'avatar': 'cG5n',
        })
        self.collection.update_one.assert_called_once()

    @patch('api.get_tba_json')
    def test_fresh_cache_avoids_tba_requests(self, tba):
        identity = {'team': 123, 'name': 'Polar Robotics', 'avatar': None}
        self.collection.find_one.return_value = {
            'identity': identity, 'identity_date': now_utc().date().isoformat(),
        }
        self.assertEqual(self.client.get('/teams/123/identity').json(), identity)
        tba.assert_not_called()

    @patch('api.get_tba_json')
    def test_missing_avatar_preserves_name(self, tba):
        tba.side_effect = [{'nickname': 'Polar Robotics'}, []]
        result = self.client.get('/teams/123/identity').json()
        self.assertEqual(result['name'], 'Polar Robotics')
        self.assertIsNone(result['avatar'])

    @patch('api.get_tba_json', return_value={})
    def test_upstream_failure_uses_stale_identity(self, tba):
        identity = {'team': 123, 'name': 'Polar Robotics', 'avatar': None}
        self.collection.find_one.return_value = {
            'identity': identity, 'identity_date': '2020-01-01',
        }
        self.assertEqual(self.client.get('/teams/123/identity').json(), identity)
        self.collection.update_one.assert_not_called()

    def test_invalid_team_is_rejected(self):
        self.assertEqual(self.client.get('/teams/0/identity').status_code, 400)


if __name__ == '__main__':
    unittest.main()
