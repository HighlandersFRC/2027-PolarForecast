import copy
import unittest
from unittest.mock import Mock

from fastapi import FastAPI, Header, HTTPException
from fastapi.testclient import TestClient
from pymongo.errors import DuplicateKeyError

from routers.schedules import create_schedule_router


class EventScheduleTests(unittest.TestCase):
    def setUp(self):
        self.collection = Mock()
        documents = {}

        def find(query):
            document = documents.get(query["_id"])
            if document and all(document.get(key) == value for key, value in query.items()):
                return copy.deepcopy(document)
            return None

        def insert(document):
            if document["_id"] in documents:
                raise DuplicateKeyError("exists")
            documents[document["_id"]] = copy.deepcopy(document)

        def replace(query, document):
            if find(query) is None:
                return Mock(matched_count=0)
            documents[document["_id"]] = copy.deepcopy(document)
            return Mock(matched_count=1)

        self.collection.find_one.side_effect = find
        self.collection.insert_one.side_effect = insert
        self.collection.replace_one.side_effect = replace
        roles = {
            ('roster-a', 'alice'): 'owner',
            ('roster-a', 'bob'): 'member',
            ('roster-a', 'dana'): 'admin',
            ('roster-b', 'carol'): 'admin',
        }

        def authenticated_user(authorization: str = Header(default='')):
            if not authorization.startswith('Bearer '):
                raise HTTPException(401)
            return authorization.removeprefix('Bearer ')

        app = FastAPI()
        app.include_router(create_schedule_router(
            self.collection,
            lambda group, user: (group, user) in roles,
            lambda group, user: roles.get((group, user)),
            authenticated_user,
        ))
        self.client = TestClient(app)
        self.addCleanup(self.client.close)
        self.body = {
            'roster_group_id': 'roster-a', 'revision': 0,
            'groups': [{'id': 'poofs', 'name': 'Chezy Poofs',
                        'roster_group_id': 'roster-a',
                        'members': ['alice', 'bob'], 'lead': 'alice'}],
            'rows': [
                {'id': 'lunch', 'date': '2026-10-23', 'time': '12:30',
                 'activities': {'poofs': 'Lunch'}},
                {'id': 'pit', 'date': '2026-10-23', 'time': '09:30',
                 'activities': {'poofs': 'Pit scouting'}},
            ],
        }

    def put(self, body=None, event='2026test', actor='alice'):
        return self.client.put(f'/events/{event}/schedule', json=body or self.body,
                               headers={'Authorization': f'Bearer {actor}'})

    def get(self, actor, roster='roster-a'):
        return self.client.get('/events/2026test/schedule',
                               params={'roster_group_id': roster},
                               headers={'Authorization': f'Bearer {actor}'})

    def mark(self, status, actor='alice', roster='roster-a', revision=1, student='bob'):
        return self.client.patch('/events/2026test/schedule/attendance', json={
            'roster_group_id': roster, 'revision': revision, 'row_id': 'pit',
            'group_id': 'poofs', 'student': student, 'status': status,
        }, headers={'Authorization': f'Bearer {actor}'})

    def test_schedule_is_shared_across_rosters_and_scoped_to_event(self):
        saved = self.put()
        self.assertEqual(saved.status_code, 200)
        document = self.collection.insert_one.call_args.args[0]
        self.assertEqual(document['_id'], '2026test')
        self.assertNotIn('roster_group_id', document)
        response = self.get('carol', 'roster-b')
        self.assertEqual(response.json(), saved.json())
        self.assertEqual(self.collection.find_one.call_args.args[0], {'_id': '2026test'})
        self.put(event='2026other')
        self.assertEqual(self.collection.insert_one.call_args.args[0]['_id'], '2026other')

    def test_sorts_rows_and_increments_revision(self):
        result = self.put().json()
        self.assertEqual(result['revision'], 1)
        self.assertEqual([row['id'] for row in result['rows']], ['pit', 'lunch'])
        self.body['revision'] = 1
        self.assertEqual(self.put().json()['revision'], 2)
        self.assertEqual(self.collection.replace_one.call_args.args[0],
                         {'_id': '2026test', 'revision': 1})

    def test_rejects_non_member_requester_and_assignment(self):
        self.assertEqual(self.put(actor='outsider').status_code, 403)
        self.body['groups'][0]['members'].append('outsider')
        self.assertEqual(self.put().status_code, 400)
        self.collection.insert_one.assert_not_called()

    def test_requires_one_lead_in_group(self):
        for lead in ['', 'outsider', ['alice', 'bob']]:
            with self.subTest(lead=lead):
                body = copy.deepcopy(self.body)
                body['groups'][0]['lead'] = lead
                self.assertEqual(self.put(body).status_code, 422)

    def test_rejects_duplicate_names_members_times_and_unknown_columns(self):
        cases = []
        body = copy.deepcopy(self.body)
        body['groups'].append({**body['groups'][0], 'id': 'duplicate'})
        cases.append(body)
        body = copy.deepcopy(self.body)
        body['groups'].append({**body['groups'][0], 'id': 'two', 'name': 'Citrus'})
        cases.append(body)
        body = copy.deepcopy(self.body)
        body['rows'][1]['time'] = '12:30'
        cases.append(body)
        body = copy.deepcopy(self.body)
        body['rows'][0]['activities']['missing'] = 'Lunch'
        cases.append(body)
        body = copy.deepcopy(self.body)
        body['rows'][0]['time'] = '25:00'
        cases.append(body)
        for body in cases:
            with self.subTest(body=body):
                self.assertEqual(self.put(body).status_code, 422)

    def test_concurrent_changes_cannot_overwrite(self):
        self.assertEqual(self.put().status_code, 200)
        self.assertEqual(self.put().status_code, 409)
        self.body['revision'] = 1
        self.assertEqual(self.mark('absent').status_code, 200)
        self.assertEqual(self.put().status_code, 409)

    def test_members_are_read_only_and_cannot_impersonate_owner(self):
        self.assertEqual(self.put({**self.body, 'username': 'alice'}, actor='bob').status_code, 403)
        self.assertEqual(self.client.put('/events/2026test/schedule', json=self.body).status_code, 401)
        self.assertEqual(self.put().status_code, 200)
        self.assertEqual(self.get('outsider').status_code, 403)
        self.assertEqual(self.mark('absent', actor='bob').status_code, 403)
        self.assertEqual(self.mark('tardy').status_code, 200)
        member = self.get('bob').json()
        self.assertFalse(member['can_edit'])
        self.assertNotIn('attendance', member)
        self.assertEqual(len(member['rows']), 2)

    def test_attendance_is_scoped_to_roster_and_survives_schedule_edits(self):
        self.assertEqual(self.put().status_code, 200)
        self.assertEqual(self.mark('tardy', actor='dana').status_code, 200)
        self.assertEqual(self.mark('extreme_tardy', revision=2).status_code, 200)
        self.assertEqual(self.get('dana').json()['attendance'], [
            {'row_id': 'pit', 'group_id': 'poofs', 'student': 'bob', 'status': 'extreme_tardy'},
        ])
        self.assertEqual(self.get('carol', 'roster-b').json()['attendance'], [])
        self.assertEqual(self.mark('absent', 'carol', 'roster-b', revision=3).status_code, 403)
        self.assertEqual(self.mark('absent', revision=3, student='outsider').status_code, 400)
        self.assertEqual(self.mark('present', revision=3).status_code, 422)
        self.body['revision'] = 3
        self.body['rows'][0]['activities']['poofs'] = 'Break'
        saved = self.put().json()
        self.assertEqual(saved['attendance'][0]['status'], 'extreme_tardy')
        self.assertEqual(self.mark(None, revision=4).json()['attendance'], [])


if __name__ == '__main__':
    unittest.main()
