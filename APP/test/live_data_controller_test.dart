import 'dart:async';

import 'package:app/services/live_data_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('devices opened at different times converge on the latest stats',
      (tester) async {
    var serverOpr = 40;
    final first = LiveDataController(load: () async => serverOpr);
    await tester.pump();
    expect(first.value.data, 40);

    serverOpr = 55;
    final second = LiveDataController(load: () async => serverOpr);
    await tester.pump();
    expect(second.value.data, 55);
    await tester.pump(const Duration(seconds: 30));
    expect(first.value.data, second.value.data);
    expect(first.value.data, 55);
    first.dispose();
    second.dispose();
  });

  testWidgets('returning to the app immediately refreshes stats',
      (tester) async {
    var serverOpr = 40;
    final data = LiveDataController(load: () async => serverOpr);
    await tester.pump();
    data.didChangeAppLifecycleState(AppLifecycleState.paused);
    serverOpr = 55;
    data.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(data.value.data, 55);
    data.dispose();
  });

  testWidgets('account changes discard data and ignore older responses',
      (tester) async {
    final requests = <Completer<int>>[];
    final data = LiveDataController(load: () {
      final request = Completer<int>();
      requests.add(request);
      return request.future;
    });
    requests[0].complete(40);
    await tester.pump();
    expect(data.value.data, 40);

    data.refresh();
    expect(data.value.data, 40); // No flicker on background refresh.
    data.refresh(replace: true); // Switch account during the old request.
    expect(data.value.hasData, isFalse);
    requests[2].complete(55);
    await tester.pump();
    requests[1].complete(41);
    await tester.pump();
    expect(data.value.data, 55);
    data.dispose();
  });

  testWidgets('refreshes share pending work and recover after a timeout',
      (tester) async {
    var calls = 0;
    final stalled = Completer<int>();
    final data = LiveDataController(load: () {
      calls++;
      return calls == 1 ? stalled.future : Future.value(55);
    });
    data.refresh();
    data.refresh();
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 20));
    expect(data.value.error, isA<TimeoutException>());
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 2);
    expect(data.value.data, 55);
    stalled.complete(40);
    await tester.pump();
    expect(data.value.data, 55);
    data.dispose();
  });

  testWidgets('failed refresh is visible and the next poll recovers',
      (tester) async {
    var offline = false;
    final data = LiveDataController(load: () async {
      if (offline) throw StateError('Offline');
      return 55;
    });
    await tester.pump();
    offline = true;
    await tester.pump(const Duration(seconds: 30));
    expect(data.value.hasError, isTrue);
    expect(data.value.hasData, isFalse);
    offline = false;
    await tester.pump(const Duration(seconds: 30));
    expect(data.value.data, 55);
    data.dispose();
  });

  testWidgets('disposing stops polling and ignores in-flight responses',
      (tester) async {
    final request = Completer<int>();
    var calls = 0;
    final data = LiveDataController(load: () {
      calls++;
      return request.future;
    });
    var notifications = 0;
    data.addListener(() => notifications++);
    data.dispose();
    request.complete(55);
    await tester.pump(const Duration(seconds: 60));
    expect(calls, 1);
    expect(notifications, 0);
  });
}
