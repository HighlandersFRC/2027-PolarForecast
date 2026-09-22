import 'dart:convert';

import 'package:app/APIService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final username in <String?>[null, '', '   ', ' scout ']) {
    test('event and team requests use the same identity: "$username"',
        () async {
      final requests = <http.Request>[];
      final api = APIService(
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          requests.add(request);
          final stats = {
            'Team': 1741,
            'Rank': 1,
            'OPR': request.url.queryParameters['username'] == 'scout' ? 55 : 40,
            'Auto': 10,
            'Teleop': 20,
            'Endgame': 10,
            'Climb': 10,
          };
          return http.Response(
              jsonEncode(
                request.url.path.endsWith('/stats')
                    ? [stats]
                    : {'event': '2026test', 'team': 1741, 'stats': stats},
              ),
              200);
        }),
      );
      addTearDown(api.dispose);
      final event =
          await api.fetchRawStatsByEvent('2026test', username: username);
      final team = await api.getTeamStats('2026test', 1741, username: username);
      expect(team.stats.OPR, event.single.OPR);
      expect(requests[0].url.queryParameters, requests[1].url.queryParameters);
      expect(
          requests[1].url.queryParameters,
          username?.trim().isNotEmpty == true
              ? {'username': 'scout'}
              : isEmpty);
    });
  }
}
