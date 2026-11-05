import 'dart:convert';

import 'package:app/APIService.dart';
import 'package:app/widgets/event_schedule_view.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('creates a named event group with exactly one lead',
      (tester) async {
    Map<String, dynamic> schedule = {
      'revision': 0,
      'groups': [],
      'rows': [],
      'can_edit': true,
    };
    Map<String, dynamic>? saved;
    final api = APIService(client: MockClient((request) async {
      if (request.url.path.endsWith('/members')) {
        return http.Response(
            jsonEncode({
              'member': [
                {'username': 'alice'},
                {'username': 'bob'},
              ]
            }),
            200);
      }
      expect(request.url.path, '/events/2026test/schedule');
      expect(request.headers['authorization'], 'Bearer test-token');
      if (request.method == 'PUT') {
        saved = jsonDecode(request.body) as Map<String, dynamic>;
        schedule = {...saved!, 'revision': 1, 'can_edit': true};
      }
      return http.Response(jsonEncode(schedule), 200);
    }));
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EventScheduleView(
                event: '2026test',
                rosterGroupId: 'roster',
                getAccessToken: () async => 'test-token',
                api: api))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Chezy Poofs');
    await tester.tap(find.text('Save group'));
    await tester.pumpAndSettle();
    expect(find.text('Select one lead'), findsOneWidget);
    expect(saved, isNull);
    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('alice').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save group'));
    await tester.pumpAndSettle();
    expect(saved!['groups'][0]['name'], 'Chezy Poofs');
    expect(saved!['groups'][0]['lead'], 'alice');
    expect(saved!['groups'][0]['members'], ['alice']);
    await tester.tap(find.text('Groups and leads'));
    await tester.pumpAndSettle();
    expect(find.text('alice · Lead'), findsOneWidget);
    expect(find.text('Add time slot'), findsOneWidget);
  });

  testWidgets('shows all TBA dates and a read-only timeline on a narrow screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = APIService(client: MockClient((request) async {
      if (request.url.path.endsWith('/members'))
        return http.Response('{}', 200);
      return http.Response(
          jsonEncode({
            'revision': 1,
            'can_edit': false,
            'groups': [
              {
                'id': 'a',
                'name': 'Citrus',
                'roster_group_id': 'roster',
                'members': ['alice'],
                'lead': 'alice'
              },
            ],
            'rows': [
              {
                'id': 'r',
                'date': '2026-10-23',
                'time': '09:30',
                'activities': {'a': 'Pit scouting'}
              },
              {
                'id': 's',
                'date': '2026-10-25',
                'time': '13:15',
                'activities': {'a': 'Match scouting'}
              },
            ],
          }),
          200);
    }));
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EventScheduleView(
                event: '2026test',
                eventStart: '2026-10-23',
                eventEnd: '2026-10-25',
                rosterGroupId: 'roster',
                getAccessToken: () async => 'test-token',
                api: api))));
    await tester.pumpAndSettle();
    expect(find.byType(Tab), findsNWidgets(3));
    expect(find.text('Citrus'), findsOneWidget);
    expect(find.text('Pit scouting'), findsOneWidget);
    expect(find.text('9:30 AM'), findsOneWidget);
    expect(find.text('Match scouting'), findsNothing);
    expect(find.text('Attendance'), findsNothing);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Add time slot'), findsNothing);
    expect(find.byTooltip('Manage time slot'), findsNothing);
    await tester.tap(find.text('Oct 24'));
    await tester.pumpAndSettle();
    expect(find.text('Pit scouting'), findsNothing);
    expect(find.text('No time slots scheduled for this day.'), findsOneWidget);
    await tester.ensureVisible(find.text('Oct 25'));
    await tester.tap(find.text('Oct 25'));
    await tester.pumpAndSettle();
    expect(find.text('Match scouting'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('schedule CSV contains only schedule columns and escapes editable text',
      () {
    final csv = buildEventScheduleCsv(
      [
        {'id': 'a', 'name': 'Citrus, Red'},
        {'id': 'b', 'name': '=2+2'},
      ],
      [
        {
          'date': '2026-10-23',
          'time': '09:30',
          'activities': {'a': 'Scout "North" pits', 'b': 'Match scouting'},
          'attendance': ['Absent', 'Tardy', 'Extreme Tardy'],
        },
        {'date': '2026-10-24', 'time': '11:00', 'activities': {}},
      ],
    );
    expect(
      const CsvToListConverter(shouldParseNumbers: false).convert(csv),
      [
        ['Date', 'Time', 'Group', 'Activity'],
        ['2026-10-23', '09:30', 'Citrus, Red', 'Scout "North" pits'],
        ['2026-10-23', '09:30', "'=2+2", 'Match scouting'],
        ['2026-10-24', '11:00', '', ''],
      ],
    );
  });

  test('event lookup requests the event year and returns its TBA dates',
      () async {
    final api = APIService(client: MockClient((request) async {
      expect(request.url.path, '/searchkeys');
      expect(request.url.queryParameters['year'], '2027');
      return http.Response(
          jsonEncode({
            'data': [
              {
                'key': '2027test',
                'display': '2027 Test Regional',
                'page': '/event/test',
                'start': '2027-03-18',
                'end': '2027-03-20',
              }
            ],
          }),
          200);
    }));
    addTearDown(api.dispose);
    final event = await api.fetchEventByKey('2027test');
    expect(event?.start, '2027-03-18');
    expect(event?.end, '2027-03-20');
    expect(await api.fetchEventByKey('2027missing'), isNull);
  });

  testWidgets('admin can record and clear attendance from a selected time slot',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final schedule = <String, dynamic>{
      'revision': 1,
      'can_edit': true,
      'groups': [
        {
          'id': 'a',
          'name': 'Citrus',
          'roster_group_id': 'roster',
          'members': ['alice'],
          'lead': 'alice',
        },
      ],
      'rows': [
        {
          'id': 'r',
          'date': '2026-10-23',
          'time': '09:30',
          'activities': {'a': 'Pit scouting'},
        },
      ],
      'attendance': [],
    };
    final writes = <Map<String, dynamic>>[];
    final api = APIService(client: MockClient((request) async {
      if (request.url.path.endsWith('/members'))
        return http.Response('{}', 200);
      if (request.method == 'PATCH') {
        expect(request.url.path, '/events/2026test/schedule/attendance');
        expect(request.headers['authorization'], 'Bearer test-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        writes.add(body);
        expect(body['revision'], schedule['revision']);
        schedule['revision'] = body['revision'] + 1;
        schedule['attendance'] = body['status'] == null ? [] : [body];
      }
      return http.Response(jsonEncode(schedule), 200);
    }));
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EventScheduleView(
          event: '2026test',
          rosterGroupId: 'roster',
          getAccessToken: () async => 'test-token',
          api: api,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attendance'));
    await tester.pumpAndSettle();
    expect(find.text('Citrus · Pit scouting'), findsOneWidget);
    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extreme Tardy'));
    await tester.pumpAndSettle();
    expect(writes.single['student'], 'alice');
    expect(writes.single['row_id'], 'r');
    expect(writes.single['status'], 'extreme_tardy');
    expect(find.text('Extreme Tardy'), findsOneWidget);
    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unmarked'));
    await tester.pumpAndSettle();
    expect(writes.last['status'], isNull);
    expect(find.text('Unmarked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
