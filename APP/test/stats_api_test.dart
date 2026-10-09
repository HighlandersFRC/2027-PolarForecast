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
            'AutoFuelOPR': 6.5,
            'TeleopFuelOPR': 18.25,
            'AverageAutoFuel': 22.0,
            'AverageTeleopFuel': 74.5,
            'AverageTotalFuel': 96.5,
            'CombinedFuelOPR': 24.75,
            'DeathRate': 0.1,
            'DefenseRate': 0.25,
            'DefenseCount': 3,
            'MatchesPlayed': 8,
            'ScoutEntries': 12,
            'ScoutedMatches': 7,
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
      expect(event.single.AutoFuelOPR, 6.5);
      expect(event.single.TeleopFuelOPR, 18.25);
      expect(event.single.AverageAutoFuel, 22.0);
      expect(event.single.AverageTeleopFuel, 74.5);
      expect(event.single.AverageTotalFuel, 96.5);
      expect(event.single.CombinedFuelOPR, 24.75);
      expect(event.single.DeathRate, 0.1);
      expect(event.single.DefenseRate, 0.25);
      expect(event.single.DefenseCount, 3);
      expect(event.single.MatchesPlayed, 8);
      expect(event.single.ScoutEntries, 12);
      expect(event.single.ScoutedMatches, 7);
      expect(requests[0].url.queryParameters, requests[1].url.queryParameters);
      expect(
          requests[1].url.queryParameters,
          username?.trim().isNotEmpty == true
              ? {'username': 'scout'}
              : isEmpty);
    });
  }
}
