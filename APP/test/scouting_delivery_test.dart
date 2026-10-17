import 'dart:async';
import 'dart:convert';
import 'package:app/models/2026Matchscouting.dart';
import 'package:app/models/scout_info.dart';
import 'package:app/services/scouting_delivery.dart';
import 'package:app/services/scouting_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _BrokenStatusStore extends ScoutingLocalStore {
  @override
  Future<void> status(
          String scope, String id, LocalReportStatus status) async =>
      throw StateError('Device status write failed');
}

void main() {
  late ScoutingLocalStore store;
  late LocalScoutReport entry;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = ScoutingLocalStore();
    entry = LocalScoutReport(
        id: 'one',
        savedAt: DateTime.utc(2026),
        status: LocalReportStatus.saved,
        report: const MatchScouting2026(
                event: '2026test',
                match: '4',
                team: 123,
                groupId: 'group',
                data: Data(
                    autoPath: AutoPath(path: ['Preload Left', 'Shot at Hub']),
                    autoScouting: AutoScouting(fuel_scored: 9),
                    teleopScouting: TeleopScouting(fuel_scored: 45),
                    misc: Misc(
                        died: false,
                        defense: true,
                        comments: 'Strong defense')),
                scoutInfo: ScoutInfo(
                    userId: 'scout',
                    firstName: 'Scout',
                    username: 'scout',
                    team: '123'))
            .toJson(),
        recording: {
          'version': 1,
          'actions': [
            {'kind': 'shooting', 'elapsedMs': 3000, 'quantity': 9}
          ]
        });
  });

  test(
      'successful cloud upload sends the existing payload once and does not export JSON',
      () async {
    var uploads = 0;
    var downloads = 0;
    final result = await ScoutingDelivery(
        store: store,
        upload: (payload) async {
          uploads++;
          final report = MatchScouting2026.fromJson(payload);
          expect(report.team, 123);
          expect(report.data.teleopScouting.fuel_scored, 45);
          expect(payload.containsKey('recording'), isFalse);
        },
        downloadJson: (_) async {
          downloads++;
        }).submit('scope', entry);
    expect(uploads, 1);
    expect(downloads, 0);
    expect(result.uploaded, isTrue);
    expect(result.completed, isTrue);
    expect((await store.history('scope')).single.status,
        LocalReportStatus.uploaded);
  });

  test('a failed cloud upload exports the exact report and timeline as JSON',
      () async {
    var uploads = 0;
    LocalScoutReport? downloaded;
    final result = await ScoutingDelivery(
        store: store,
        upload: (_) async {
          uploads++;
          throw StateError('Offline');
        },
        downloadJson: (report) async {
          downloaded = report;
        }).submit('scope', entry);
    expect(uploads, 1);
    expect(result.uploaded, isFalse);
    expect(result.jsonDownloaded, isTrue);
    expect(result.completed, isTrue);
    final backup =
        jsonDecode(jsonEncode(downloaded!.toJson())) as Map<String, dynamic>;
    expect(
        MatchScouting2026.fromJson(backup['report'] as Map<String, dynamic>)
            .data
            .autoScouting
            .fuel_scored,
        9);
    expect(backup['recording'], entry.recording);
    expect(backup['status'], 'unconfirmed');
    expect((await store.history('scope')).single.status,
        LocalReportStatus.unconfirmed);
  });

  test('device storage failure never prevents the cloud attempt', () async {
    final brokenStore = ScoutingLocalStore(
        preferences: () async => throw StateError('No storage'));
    var uploads = 0;
    final result = await ScoutingDelivery(
            store: brokenStore,
            upload: (_) async {
              uploads++;
            },
            downloadJson: (_) async => fail(
                'Successful cloud upload must not export a failure backup'))
        .submit('scope', entry);
    expect(uploads, 1);
    expect(result.uploaded, isTrue);
    expect(result.deviceSaved, isFalse);
  });

  test('JSON fallback still runs when both the cloud and device storage fail',
      () async {
    final brokenStore = ScoutingLocalStore(
        preferences: () async => throw StateError('No storage'));
    var downloads = 0;
    final result = await ScoutingDelivery(
        store: brokenStore,
        upload: (_) async => throw StateError('Offline'),
        downloadJson: (_) async {
          downloads++;
        }).submit('scope', entry);
    expect(downloads, 1);
    expect(result.jsonDownloaded, isTrue);
    expect(result.deviceSaved, isFalse);
    expect(result.completed, isTrue);
  });

  test(
      'failed JSON export does not report completion and retains the device report',
      () async {
    final result = await ScoutingDelivery(
            store: store,
            upload: (_) async => throw StateError('Offline'),
            downloadJson: (_) async => throw StateError('Download blocked'))
        .submit('scope', entry);
    expect(result.completed, isFalse);
    expect(result.jsonError, isA<StateError>());
    expect(result.deviceSaved, isTrue);
    expect((await store.history('scope')).single.report['team'], 123);
  });

  test(
      'device status errors after HTTP success do not trigger a fallback or another upload',
      () async {
    var uploads = 0;
    var downloads = 0;
    final result = await ScoutingDelivery(
        store: _BrokenStatusStore(),
        upload: (_) async {
          uploads++;
        },
        downloadJson: (_) async {
          downloads++;
        }).submit('scope', entry);
    expect(uploads, 1);
    expect(downloads, 0);
    expect(result.uploaded, isTrue);
  });

  test('a network timeout downloads JSON without silently retrying', () async {
    var uploads = 0;
    var downloads = 0;
    final pending = Completer<void>();
    final result = await ScoutingDelivery(
        store: store,
        uploadTimeout: Duration.zero,
        upload: (_) {
          uploads++;
          return pending.future;
        },
        downloadJson: (_) async {
          downloads++;
        }).submit('scope', entry);
    expect(result.uploadError, isA<TimeoutException>());
    expect(downloads, 1);
    expect(uploads, 1);
    pending.complete();
  });

  test('a previously confirmed report is not uploaded again', () async {
    final confirmed = LocalScoutReport(
        id: entry.id,
        report: entry.report,
        recording: entry.recording,
        status: LocalReportStatus.uploaded,
        savedAt: entry.savedAt);
    final result = await ScoutingDelivery(
            store: store,
            upload: (_) async => fail('Already uploaded'),
            downloadJson: (_) async => fail('Already uploaded'))
        .submit('scope', confirmed);
    expect(result.uploaded, isTrue);
  });
}
