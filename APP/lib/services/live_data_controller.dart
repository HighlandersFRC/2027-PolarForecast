import 'dart:async';

import 'package:flutter/widgets.dart';

/// Keeps each open stats view current, independently of the global cache job.
class LiveDataController<T> extends ValueNotifier<AsyncSnapshot<T>>
    with WidgetsBindingObserver {
  final Future<T> Function() load;
  final Duration requestTimeout;
  late final Timer _timer;
  Future<void>? _pending;
  int _generation = 0;
  bool _disposed = false;

  LiveDataController({
    required this.load,
    Duration interval = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 20),
  }) : super(AsyncSnapshot<T>.nothing()) {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(interval, (_) => refresh());
    refresh();
  }

  /// Replace when the event/account changes so old data is cleared immediately.
  /// Background refreshes retain the view until new data arrives; failures are
  /// shown as errors instead of silently presenting an old snapshot as current.
  Future<void> refresh({bool replace = false}) {
    if (_disposed) return Future<void>.value();
    if (!replace && _pending != null) return _pending!;

    final generation = ++_generation;
    if (replace || !value.hasData) {
      value = AsyncSnapshot<T>.waiting();
    }

    final pending = _fetch(generation);
    _pending = pending;
    return pending;
  }

  Future<void> _fetch(int generation) async {
    try {
      final data = await Future<T>.sync(load).timeout(requestTimeout);
      if (!_disposed && generation == _generation) {
        value = AsyncSnapshot<T>.withData(ConnectionState.done, data);
      }
    } catch (error, stackTrace) {
      if (!_disposed && generation == _generation) {
        value = AsyncSnapshot<T>.withError(
          ConnectionState.done,
          error,
          stackTrace,
        );
      }
    } finally {
      if (generation == _generation) _pending = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
