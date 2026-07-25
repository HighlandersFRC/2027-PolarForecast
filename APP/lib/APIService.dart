import 'dart:convert';

import 'package:app/models/2026Matchscouting.dart';
import 'package:app/models/2026Pitscouting.dart';
import 'package:app/models/follow_up.dart';
import 'package:app/models/group_events.dart';
import 'package:app/models/match_prediction.dart';
import 'package:app/models/team_stat.dart';
import 'package:app/models/team_stats.dart';
import 'package:app/models/user_group_details.dart';
import 'package:http/http.dart' as http;

import 'models/2026StatsModel.dart';

class EventSearchKey {
  final String key;
  final String display;
  final String page;
  final String? start;
  final String? end;

  const EventSearchKey({
    required this.key,
    required this.display,
    required this.page,
    this.start,
    this.end,
  });

  factory EventSearchKey.fromJson(Map<String, dynamic> json) {
    return EventSearchKey(
      key: json['key'] as String,
      display: json['display'] as String,
      page: json['page'] as String,
      start: json['start'] as String?,
      end: json['end'] as String?,
    );
  }

  String get eventCode => key.replaceFirst(RegExp(r'^\d{4}'), '');
}

class APIService {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  final String baseUrl;
  final http.Client _client;

  APIService({
    this.baseUrl = defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<Stats2026>> fetchStatsByEvent(
    String eventKey, {
    String? username,
  }) async {
    final normalizedUsername = username?.trim();

    final uri = Uri.parse('$baseUrl/$eventKey/stats').replace(
      queryParameters: {
        if (normalizedUsername != null && normalizedUsername.isNotEmpty)
          'username': normalizedUsername,
      },
    );

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load event stats: '
        '${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body);

    if (body is! List) {
      throw Exception(
        'Unexpected response format: expected a JSON list.',
      );
    }

    return body
        .map<Stats2026>(
          (item) => Stats2026.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<EventSearchKey>> fetchEventKeys() async {
    final uri = Uri.parse('$baseUrl/searchkeys');
    final response =
        await _client.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('Failed to load event keys: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    if (body is! Map || body['data'] is! List) {
      throw Exception(
          'Unexpected response format: expected a JSON object with a data list.');
    }

    return (body['data'] as List)
        .map<EventSearchKey>((item) =>
            EventSearchKey.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> fetchCacheStatus({
    String year = '2026',
  }) async {
    final uri = Uri.parse('$baseUrl/cache/status').replace(
      queryParameters: {
        'year': year,
      },
    );

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch cache status: '
        '${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body);

    if (body is! Map) {
      throw Exception(
        'Unexpected response format: expected a JSON object.',
      );
    }

    return Map<String, dynamic>.from(body);
  }

  Future<String> fetchEventDisplayNameByKey(String key) async {
    final uri = Uri.parse('$baseUrl/searchkeys');
    final response =
        await _client.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('Failed to load event keys: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);

    if (body is! Map || body['data'] is! List) {
      throw Exception(
        'Unexpected response format: expected a JSON object with a data list.',
      );
    }

    final list = (body['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final match = list.firstWhere(
      (item) => item['key'] == key,
      orElse: () => {},
    );

    return match['display'];
  }

  Future<List<TeamStat>> fetchRawStatsByEvent(
    String eventKey, {
    String? username,
  }) async {
    final normalizedUsername = username?.trim();

    final uri = Uri.parse('$baseUrl/$eventKey/stats').replace(
      queryParameters: {
        if (normalizedUsername != null && normalizedUsername.isNotEmpty)
          'username': normalizedUsername,
      },
    );

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load event stats: '
        '${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body);

    if (body is! List) {
      throw Exception(
        'Unexpected response format: expected a JSON list.',
      );
    }

    return body
        .map<TeamStat>(
          (item) => TeamStat.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<MatchPrediction>> fetchPredictionsByEvent(String eventKey) async {
    final uri = Uri.parse('$baseUrl/$eventKey/predictions');

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load event predictions: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body);

    if (body is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected response format: expected JSON object.',
      );
    }

    final predictions = body['predictions'];

    if (predictions is! List) {
      throw Exception(
        'Unexpected response format: predictions is not a list.',
      );
    }

    return predictions
        .map<MatchPrediction>(
          (item) => MatchPrediction.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<Stats2026>> fetchStatsList() async {
    final uri = Uri.parse('$baseUrl/stats');
    final response =
        await _client.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('Failed to load stats: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    if (body is! List) {
      throw Exception('Unexpected response format: expected a JSON list.');
    }

    return body
        .map<Stats2026>((item) =>
            Stats2026.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<String> getJoinCodeFromGroupID(String groupId) async {
    final url = Uri.parse("$baseUrl/joincode/$groupId");

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch join code");
    }
    return response.body;
  }

  Future<Map<String, dynamic>> getGroupPitStatus({
    required String groupId,
    required String event,
    required String username,
  }) async {
    final url = Uri.parse(
      "$baseUrl/groups/$groupId/events/$event/pit-status",
    ).replace(
      queryParameters: {
        "username": username,
      },
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to fetch group pit status: "
        "${response.statusCode} ${response.body}",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid group pit status response");
    }

    return decoded;
  }

  Future<List<dynamic>> getMatchScoutingByGroupTeamEvent({
    required String groupId,
    required String username,
    required int team,
    required String event,
  }) async {
    final url = Uri.parse(
      "$baseUrl/matchscouting/$groupId/group/$username/team/$team/event/$event",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // backend returns:
      // { group_id, event, team, count, data: [...] }
      return data["data"] ?? [];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["detail"] ?? "Failed to fetch match scouting");
    }
  }

  Future<List<Map<String, dynamic>>> getGroupMatchScoutingByEvent({
    required String groupId,
    required String username,
    required String event,
  }) async {
    final url = Uri.parse(
      "$baseUrl/groups/$groupId/events/$event/matchscouting",
    ).replace(
      queryParameters: {
        "username": username,
      },
    );

    final response = await _client.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to fetch event match scouting: "
        "${response.statusCode} ${response.body}",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map || decoded['data'] is! List) {
      throw Exception("Invalid event match scouting response");
    }

    return (decoded['data'] as List)
        .map(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  Future<List<dynamic>> getPitScoutingByGroupTeamEvent({
    required String groupId,
    required String username,
    required int team,
    required String event,
  }) async {
    final url = Uri.parse(
      "$baseUrl/pitscouting/$groupId/group/$username/team/$team/event/$event",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["data"] ?? [];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["detail"] ?? "Failed to fetch match scouting");
    }
  }

  Future<GroupEvents> getGroupEvents(String groupId) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId/events');

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load group events');
    }

    return GroupEvents.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<TeamStats> getTeamStats(String event, int team) async {
    final uri = Uri.parse('$baseUrl/$event/event/$team/team');

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load team stats');
    }

    return TeamStats.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> submitMatchScouting(
    MatchScouting2026 scouting,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/matchscouting"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(scouting),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

Future<List<FollowUpIncident>> fetchFollowUpIncidents({
  required String groupId,
  required String username,
  required int team,
  required String event,
}) async {
  final uri = Uri.parse(
    '$baseUrl/followup/$groupId/group/$username/team/$team/event/$event',
  );

  final response = await http.get(uri);

  if (response.statusCode != 200) {
    throw Exception(response.body);
  }

  final decoded = jsonDecode(response.body);

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid follow-up response.');
  }

  final rawData = decoded['data'];

  if (rawData is! List) {
    return const <FollowUpIncident>[];
  }

  return rawData
      .whereType<Map>()
      .map(
        (item) => FollowUpIncident.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

Future<void> submitFollowUps(FollowUp followUp) async {
  final response = await http.post(
    Uri.parse('$baseUrl/followup'),
    headers: const {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(followUp.toJson()),
  );

  if (response.statusCode != 200) {
    throw Exception(response.body);
  }
}

  Future<void> submitPitScouting(
    PitScouting2026 pitData,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/pitscouting"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(pitData),
    );
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  Future<void> removeGroupEvent({
    required String groupId,
    required String eventCode,
  }) async {
    final uri = Uri.parse('$baseUrl/groups/remove-event');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "group_id": groupId,
        "event_code": eventCode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove event: ${response.body}');
    }
  }

  Future<void> addGroupEvent({
    required String groupId,
    required String eventCode,
  }) async {
    final uri = Uri.parse('$baseUrl/groups/add-event');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "group_id": groupId,
        "event_code": eventCode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add event');
    }
  }

  Future<Map<String, dynamic>> joinGroup({
    required String username,
    required String joinCode,
  }) async {
    final uri = Uri.parse('$baseUrl/groups/join');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'join_code': joinCode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to join group: ${response.statusCode} ${response.body}',
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body) as Map,
    );
  }

  Future<Map<String, List<dynamic>>> fetchGroupMembers(String groupId) async {
    final uri = Uri.parse('$baseUrl/groups/$groupId/members');

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load group members: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body);

    return {
      "owner": List<dynamic>.from(body["owner"] ?? []),
      "admin": List<dynamic>.from(body["admin"] ?? []),
      "member": List<dynamic>.from(body["member"] ?? []),
    };
  }

  Future<List<dynamic>> fetchTeamsPerAllianceBlue(
      String event, int match) async {
    final uri = Uri.parse('$baseUrl/${event}/${match}/teams');

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch teams');
    }

    final body = json.decode(response.body);
    return body["blue_teams"];
  }

  Future<List<dynamic>> fetchTeamsPerAllianceRed(
      String event, int match) async {
    final uri = Uri.parse('$baseUrl/${event}/${match}/teams');

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch teams');
    }

    final body = json.decode(response.body);
    return body["red_teams"];
  }

  Future<List<dynamic>> fetchTeamsPerEvent(String event) async {
    final uri = Uri.parse('$baseUrl/$event/teams');

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Error fetching teams: " + response.body);
    }

    final body = json.decode(response.body);
    return body;
  }

  Future<UserGroupInfo> getUserGroup(String username) async {
    final uri = Uri.parse('$baseUrl/user/group?username=$username');

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user group');
    }

    return UserGroupInfo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Stats2026> createStats(Stats2026 stats) async {
    final uri = Uri.parse('$baseUrl/stats');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(stats.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create stats: ${response.statusCode}');
    }

    return Stats2026.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map));
  }

// Add this method inside your APIService class.
  Future<void> setGroupMemberRole({
    required String groupId,
    required String username,
    required String newRole,
    required String requesterUsername,
  }) async {
    final uri = Uri.parse('$baseUrl/groups/set-role').replace(
      queryParameters: {
        'group_id': groupId,
        'username': username,
        'new_role': newRole,
        'requester_username': requesterUsername,
      },
    );

    final response = await _client.post(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Failed to update member role';

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {
        if (response.body.trim().isNotEmpty) {
          message = response.body;
        }
      }

      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> createGroup(String name,
      {String? username}) async {
    final uri = Uri.parse('$baseUrl/groups');
    final payload = <String, dynamic>{'name': name};
    if (username != null) {
      payload['username'] = username;
    }

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to create group: ${response.statusCode} ${response.body}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  void dispose() => _client.close();
}
