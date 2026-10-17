from datetime import datetime, timezone
from unittest import TestCase
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient

from api import app


class TeamEventsTests(TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.addCleanup(self.client.close)
        self.collection = Mock()
        self.collection.find_one.return_value = None
        for name, value in (
            ('api.ETagsCollection', self.collection),
            ('api.now_utc', Mock(return_value=datetime(2026, 10, 15, tzinfo=timezone.utc))),
        ):
            patcher = patch(name, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    @staticmethod
    def event(key, start):
        return {'key': key, 'name': key, 'start_date': start, 'end_date': start}

    @patch('api.get_tba_json')
    def test_rebuilt_season_newest_first_without_other_seasons_future_or_duplicates(self, tba):
        tba.return_value = [
            self.event('2026new', '2026-04-01'),
            self.event('2026future', '2026-11-01'),
            self.event('2025old', '2025-03-01'),
            self.event('2026early', '2026-03-01'),
            self.event('2026new', '2026-04-01'),
            self.event('2026live', '2026-10-15'),
            None,
            {'key': '../invalid'},
        ]
        response = self.client.get('/teams/123/events')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['team'], 123)
        self.assertEqual([event['key'] for event in response.json()['data']],
                         ['2026live', '2026new', '2026early'])
        tba.assert_called_once_with('team/frc123/events/2026/simple',
                                    default=None, expected_type=list, timeout=15)
        self.collection.find_one.assert_called_once_with(
            {'key': 'team-events:2026:123'}, {'_id': 0})
        self.collection.update_one.assert_called_once()

    @patch('api.get_tba_json')
    def test_daily_cache_still_filters_other_seasons_and_future_events(self, tba):
        self.collection.find_one.return_value = {
            'events_date': '2026-10-15',
            'events': [self.event('2026future', '2026-11-01'),
                       self.event('2026early', '2026-03-01'),
                       self.event('2026new', '2026-04-01'),
                       self.event('2025old', '2025-03-01')],
        }
        result = self.client.get('/teams/123/events').json()
        self.assertEqual([event['key'] for event in result['data']], ['2026new', '2026early'])
        tba.assert_not_called()

    @patch('api.get_tba_json', return_value=[])
    def test_empty_history_is_cached(self, tba):
        self.assertEqual(self.client.get('/teams/123/events').json(), {'team': 123, 'data': []})
        self.collection.update_one.assert_called_once()

    @patch('api.get_tba_json', return_value=None)
    def test_upstream_failure_allows_retry_and_does_not_cache_empty_history(self, tba):
        self.assertEqual(self.client.get('/teams/123/events').status_code, 502)
        self.collection.update_one.assert_not_called()

    @patch('api.get_tba_json', return_value=None)
    def test_upstream_failure_preserves_stale_history(self, tba):
        self.collection.find_one.return_value = {
            'events_date': '2026-10-14',
            'events': [self.event('2026early', '2026-03-01')],
        }
        self.assertEqual(len(self.client.get('/teams/123/events').json()['data']), 1)
        self.collection.update_one.assert_not_called()

    @patch('api.get_tba_json')
    def test_invalid_team_does_not_request_upstream(self, tba):
        for team in [0, -1]:
            self.assertEqual(self.client.get(f'/teams/{team}/events').status_code, 400)
        tba.assert_not_called()

    @patch('api.get_tba_json')
    def test_worlds_attendance_does_not_imply_einstein_qualification(self, tba):
        division = {**self.event('2026mil', '2026-04-29'), 'event_type': 3}
        einstein = {**self.event('2026cmptx', '2026-04-29'), 'event_type': 4}
        tba.side_effect = [[division, einstein], [{'picks': ['frc254', 'frc6800']}]]
        response = self.client.get('/teams/123/events')
        self.assertEqual(response.status_code, 200)
        self.assertEqual([event['key'] for event in response.json()['data']], ['2026mil'])
        self.assertEqual(tba.call_args.args, ('event/2026cmptx/alliances',))

    @patch('api.get_tba_json')
    def test_advancing_alliance_members_and_backups_keep_einstein(self, tba):
        for roster in [
            {'picks': ['frc1', 'frc2', 'frc3', 'frc123']},
            {'picks': ['frc1', 'frc2', 'frc3'], 'backup': {'in': 'frc123', 'out': 'frc3'}},
        ]:
            with self.subTest(roster=roster):
                tba.side_effect = [[{
                    **self.event('2026cmptx', '2026-04-29'), 'event_type': 4,
                }], [roster]]
                response = self.client.get('/teams/123/events')
                self.assertEqual(response.status_code, 200)
                self.assertEqual([event['key'] for event in response.json()['data']], ['2026cmptx'])

    @patch('api.get_tba_json')
    def test_existing_event_cache_is_checked_against_shared_participant_cache(self, tba):
        history = {
            'events_date': '2026-10-15',
            # Old cached events did not retain event_type.
            'events': [self.event('2026mil', '2026-04-29'),
                       self.event('2026cmptx', '2026-04-29')],
        }
        roster = {
            'participant_keys': ['frc254'],
            'participants_checked_at': datetime(2026, 10, 15, tzinfo=timezone.utc).timestamp(),
        }
        self.collection.find_one.side_effect = lambda query, *_: (
            roster if query['key'] == 'championship-participants:2026cmptx' else history)
        response = self.client.get('/teams/123/events')
        self.assertEqual([event['key'] for event in response.json()['data']], ['2026mil'])
        tba.assert_not_called()

    @patch('api.get_tba_json', return_value=None)
    def test_einstein_is_not_assumed_when_verification_fails(self, tba):
        self.collection.find_one.side_effect = [
            {'events_date': '2026-10-15',
             'events': [self.event('2026cmptx', '2026-04-29')]},
            None,
        ]
        self.assertEqual(self.client.get('/teams/123/events').status_code, 502)
        self.collection.update_one.assert_not_called()

    @patch('api.get_tba_json', return_value=None)
    def test_stale_verified_roster_is_used_during_upstream_failure(self, tba):
        self.collection.find_one.side_effect = [
            {'events_date': '2026-10-15',
             'events': [self.event('2026cmptx', '2026-04-29')]},
            {'participant_keys': ['frc123'], 'participants_checked_at': 0},
        ]
        response = self.client.get('/teams/123/events')
        self.assertEqual(response.status_code, 200)
        self.assertEqual([event['key'] for event in response.json()['data']], ['2026cmptx'])
        self.collection.update_one.assert_not_called()
