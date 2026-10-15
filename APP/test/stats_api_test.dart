import 'dart:convert';

import 'package:app/APIService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('scout stats reads GroupStats.data with the current group identity',
      () async {
    final api = APIService(
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          expect(request.url.path, '/groups/group-1/events/2026test/stats');
          expect(request.url.queryParameters, {'username': 'scout'});
          return http.Response(
              jsonEncode({
                'data': {
                  'Teams': [],
                  'ScoutStats': [
                    {
                      'ScoutId': '1',
                      'Name': 'Alex',
                      'Username': 'scout',
                      'TrustRating': null,
                      'Contribution': 0,
                      'Entries': 0,
                      'CheckedEntries': 0,
                      'TrendEntries': 0,
                      'TBAEntries': 0,
                      'Provisional': true,
                    }
                  ],
                }
              }),
              200);
        }));
    addTearDown(api.dispose);
    final stats = await api.fetchScoutStats(
        eventKey: '2026test', groupId: 'group-1', username: ' scout ');
    expect(stats.single.name, 'Alex');
    expect(stats.single.trustRating, isNull);
    expect(stats.single.entries, 0);
  });

  test('old API responses report unavailable scout stats instead of empty data',
      () async {
    final api = APIService(
        client: MockClient(
            (_) async => http.Response(jsonEncode({'data': []}), 200)));
    addTearDown(api.dispose);
    await expectLater(
        api.fetchScoutStats(
            eventKey: '2026test', groupId: 'group-1', username: 'scout'),
        throwsException);
  });

  for (final username in <String?>[null, '', '   ', ' scout ']) {
    test('event and team requests use the same identity: "$username"',
        () async {
      final requests = <http.Request>[];
      final api = APIService(
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          requests.add(request);
          final hasScouting =
              request.url.queryParameters['username'] == 'scout';
          final stats = {
            'Team': 1741,
            'Rank': 1,
            'RP': 23,
            'totalOPR': hasScouting ? 44.623456789 : 40.123456789,
            'autoOPR': hasScouting ? 11.75 : 10.25,
            'teleopOPR': hasScouting ? 23.5 : 20.5,
            'towerOPR': 9.373456789,
            'AverageAutoFuel': hasScouting ? 22.0 : null,
            'AverageTeleopFuel': hasScouting ? 74.5 : null,
            'AverageTotalFuel': hasScouting ? 96.5 : null,
            'DeathRate': hasScouting ? 0.1 : 0.0,
            'DefenseRate': hasScouting ? 0.25 : 0.0,
            'DefenseCount': hasScouting ? 3 : 0,
            'MatchesPlayed': 8,
            'ScoutEntries': hasScouting ? 12 : 0,
            'ScoutedMatches': hasScouting ? 7 : 0,
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
      final hasScouting = username?.trim().isNotEmpty == true;
      expect(team.stats.OPR, event.single.OPR);
      expect(event.single.RP, 23);
      expect(team.stats.RP, event.single.RP);
      expect(event.single.OPR, hasScouting ? 44.623456789 : 40.123456789);
      expect(event.single.Auto, hasScouting ? 11.75 : 10.25);
      expect(event.single.Teleop, hasScouting ? 23.5 : 20.5);
      expect(event.single.Tower, 9.373456789);
      expect(team.stats.Tower, event.single.Tower);
      expect(team.stats.AverageAutoFuel, event.single.AverageAutoFuel);
      expect(event.single.AverageAutoFuel, hasScouting ? 22.0 : null);
      expect(event.single.AverageTeleopFuel, hasScouting ? 74.5 : null);
      expect(event.single.AverageTotalFuel, hasScouting ? 96.5 : null);
      expect(event.single.DeathRate, hasScouting ? 0.1 : 0.0);
      expect(event.single.DefenseRate, hasScouting ? 0.25 : 0.0);
      expect(event.single.DefenseCount, hasScouting ? 3 : 0);
      expect(event.single.MatchesPlayed, 8);
      expect(event.single.ScoutEntries, hasScouting ? 12 : 0);
      expect(event.single.ScoutedMatches, hasScouting ? 7 : 0);
      expect(requests[0].url.queryParameters, requests[1].url.queryParameters);
      expect(
          requests[1].url.queryParameters,
          username?.trim().isNotEmpty == true
              ? {'username': 'scout'}
              : isEmpty);
    });
  }
}
