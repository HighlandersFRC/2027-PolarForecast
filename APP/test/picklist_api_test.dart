import 'dart:convert';

import 'package:app/APIService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('multiple picklist API uses list-specific routes and payloads',
      () async {
    final requests = <http.Request>[];
    final api = APIService(
      baseUrl: 'https://api.example.test/api',
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode({'picklists': []}), 200);
        }
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'picklist_id': 'list-1',
              'name': 'Defense',
              'sort_by': 'defense',
              'teams': [],
            }),
            201,
          );
        }
        if (request.method == 'PUT') {
          return http.Response(
            jsonEncode({
              'picklist_id': 'list-1',
              'name': 'Defense',
              'sort_by': 'manual',
              'teams': [],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'deleted': true}), 200);
      }),
    );
    addTearDown(api.dispose);

    await api.fetchPicklists(
      groupId: 'group-1',
      event: '2026test',
      username: 'scout',
    );
    await api.createPicklist(
      groupId: 'group-1',
      event: '2026test',
      username: 'scout',
      name: 'Defense',
      sortBy: 'defense',
    );
    await api.updatePicklist(
      groupId: 'group-1',
      event: '2026test',
      picklistId: 'list-1',
      username: 'scout',
      name: 'Defense',
      sortBy: 'manual',
      teams: const [],
    );
    await api.deletePicklist(
      groupId: 'group-1',
      event: '2026test',
      picklistId: 'list-1',
      username: 'scout',
    );

    expect(
        requests[0].url.path, '/api/groups/group-1/events/2026test/picklists');
    expect(requests[0].url.queryParameters, {'username': 'scout'});
    expect(jsonDecode(requests[1].body)['sort_by'], 'defense');
    expect(requests[2].url.path, endsWith('/picklists/list-1'));
    expect(jsonDecode(requests[2].body)['sort_by'], 'manual');
    expect(requests[3].method, 'DELETE');
  });

  test('picklist websocket URL preserves API path and uses wss', () {
    final api = APIService(baseUrl: 'https://example.test/api');
    addTearDown(api.dispose);
    final uri = api.picklistWebSocketUri(
      groupId: 'group 1',
      event: '2026test',
      username: 'lead scout',
    );
    expect(uri.scheme, 'wss');
    expect(uri.path, '/api/ws/groups/group%201/events/2026test/picklists');
    expect(uri.queryParameters['username'], 'lead scout');
  });
}
