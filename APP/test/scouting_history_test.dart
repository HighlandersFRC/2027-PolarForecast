import 'dart:async';
import 'package:app/services/scouting_local_store.dart';
import 'package:app/widgets/scouting_history_sheet.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ScoutingLocalStore store;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = ScoutingLocalStore();
  });
  Future<void> save(LocalReportStatus status) => store.saveReport(
      'scope',
      LocalScoutReport(
          id: 'one',
          report: {
            'team': 123,
            'match': '1',
            'data': {
              'autoScouting': {'fuel_scored': 5},
              'teleopScouting': {'fuel_scored': 10}
            }
          },
          recording: {'version': 1, 'actions': []},
          status: status,
          savedAt: DateTime.utc(2026)));
  Future<void> open(
      WidgetTester tester, Future<void> Function(LocalScoutReport) upload,
      {Future<void> Function(LocalScoutReport)? download}) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildMatteTheme(),
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showScoutingHistory(context,
                        store: store,
                        scope: 'scope',
                        onUpload: upload,
                        onDownloadJson: download ?? (_) async {}),
                    child: const Text('History'))))));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'an upload is explicit, cannot run twice, and retains the confirmed device copy',
      (tester) async {
    await save(LocalReportStatus.saved);
    final completion = Completer<void>();
    var uploads = 0;
    await open(tester, (_) {
      uploads++;
      return completion.future;
    });
    expect(uploads, 0);
    await tester.tap(find.text('Upload'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(uploads, 1);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Close history'))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Upload'))
            .onPressed,
        isNull);
    completion.complete();
    await tester.pumpAndSettle();
    expect(find.text('Upload confirmed'), findsOneWidget);
    expect(find.text('Upload'), findsNothing);
    expect((await store.history('scope')).single.status,
        LocalReportStatus.uploaded);
    await tester.tap(find.byTooltip('Close history'));
    await tester.pumpAndSettle();
    expect(uploads, 1);
  });

  testWidgets(
      'a failed upload stays on device and retry requires checking server reports',
      (tester) async {
    await save(LocalReportStatus.saved);
    var uploads = 0;
    var downloads = 0;
    await open(tester, (_) async {
      uploads++;
      throw StateError('Offline');
    }, download: (_) async {
      downloads++;
    });
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    expect((await store.history('scope')).single.status,
        LocalReportStatus.unconfirmed);
    expect(uploads, 1);
    expect(downloads, 1);
    await tester.tap(find.text('Check & retry'));
    await tester.pumpAndSettle();
    expect(find.text('Check before retrying'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(uploads, 1);
    await tester.tap(find.text('Check & retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report is missing · retry'));
    await tester.pumpAndSettle();
    expect(uploads, 2);
    expect(downloads, 2);
    expect((await store.history('scope')).length, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Download JSON exports the saved report without another cloud upload',
      (tester) async {
    await save(LocalReportStatus.saved);
    var downloads = 0;
    await open(tester, (_) async => fail('A backup download must not upload'),
        download: (entry) async {
      downloads++;
      expect(entry.report['team'], 123);
      expect(entry.recording['version'], 1);
    });
    await tester.tap(find.text('Download JSON'));
    await tester.pumpAndSettle();
    expect(downloads, 1);
    expect(
        (await store.history('scope')).single.status, LocalReportStatus.saved);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
