import 'package:app/services/scouting_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ScoutingLocalStore store;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = ScoutingLocalStore();
  });
  LocalScoutReport report(String id,
          {LocalReportStatus status = LocalReportStatus.saved}) =>
      LocalScoutReport(
          id: id,
          report: {'team': 123, 'match': '1', 'data': <String, dynamic>{}},
          recording: {'version': 1, 'actions': []},
          status: status,
          savedAt: DateTime.utc(2026));

  test('draft writes are ordered, snapshotted, and isolated by account/event',
      () async {
    final draft = <String, dynamic>{'match': '1'};
    final first = store.saveDraft('event:scoutA', draft);
    draft['match'] = '2';
    final second = store.saveDraft('event:scoutA', draft);
    await Future.wait([first, second]);
    expect(await store.readDraft('event:scoutA'), {'match': '2'});
    expect(await store.readDraft('event:scoutB'), isNull);
    expect(await store.readDraft('other:scoutA'), isNull);
    await store.clearDraft('event:scoutA');
    expect(await store.readDraft('event:scoutA'), isNull);
  });

  test('report history survives new drafts and does not downgrade upload state',
      () async {
    await store.saveReport('scope', report('one'));
    await store.status('scope', 'one', LocalReportStatus.unconfirmed);
    await store.saveReport('scope', report('one'));
    expect((await store.history('scope')).single.status,
        LocalReportStatus.unconfirmed);
    await store.status('scope', 'one', LocalReportStatus.uploaded);
    await store.saveReport('scope', report('one'));
    await store.saveReport('scope', report('two'));
    await store.saveDraft('scope', {'match': '3'});
    await store.clearDraft('scope');
    final history = await store.history('scope');
    expect(history.map((e) => e.id), ['two', 'one']);
    expect(history.last.status, LocalReportStatus.uploaded);
    expect(await store.history('another-account'), isEmpty);
  });

  test(
      'failed device storage is reported and does not poison subsequent writes',
      () async {
    final unavailable = ScoutingLocalStore(
        preferences: () async => throw StateError('No storage'));
    await expectLater(unavailable.saveDraft('scope', {}), throwsStateError);
    await store.saveDraft('scope', {'match': '4'});
    expect(await store.readDraft('scope'), {'match': '4'});
  });
}
