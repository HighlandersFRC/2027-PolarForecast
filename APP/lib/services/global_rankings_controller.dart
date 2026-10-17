import 'dart:async';
import 'dart:math' as math;

import 'package:app/models/global_ranking.dart';
import 'package:flutter/widgets.dart';

typedef RankingsLoader = Future<GlobalRankingPage> Function({
  required int offset,
  required String query,
  String? snapshot,
});

class GlobalRankingsController extends ChangeNotifier
    with WidgetsBindingObserver {
  final RankingsLoader _load;
  final Future<Map<String, dynamic>> Function(int) _identity;
  final Duration searchDelay;
  final Duration refreshInterval;
  final Map<int, Future<Map<String, dynamic>>> _identities = {};
  Timer? _timer;
  Timer? _searchTimer;
  int _generation = 0;
  bool _disposed = false;

  List<GlobalRanking> teams = [];
  Map<String, RankingMetricRange> ranges = {};
  String query = '';
  int year = 2026;
  int total = 0;
  int matched = 0;
  int? nextOffset;
  String? snapshot;
  DateTime? updatedAt;
  bool loading = true;
  bool refreshing = false;
  bool loadingMore = false;
  Object? error;

  GlobalRankingsController({
    required RankingsLoader load,
    required Future<Map<String, dynamic>> Function(int) identity,
    this.refreshInterval = const Duration(minutes: 5),
    this.searchDelay = const Duration(milliseconds: 350),
  })  : _load = load,
        _identity = identity {
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  Future<Map<String, dynamic>> identity(int team) => _identities.putIfAbsent(
      team,
      () => _identity(team).catchError((Object _) => <String, dynamic>{}));

  void search(String value) {
    final text = value.trim();
    if (text == query || _disposed) return;
    _searchTimer?.cancel();
    _timer?.cancel();
    ++_generation;
    query = text;
    teams = [];
    nextOffset = null;
    snapshot = null;
    loading = true;
    loadingMore = false;
    refreshing = false;
    error = null;
    notifyListeners();
    _searchTimer = Timer(searchDelay, refresh);
  }

  Future<void> refresh() => _refresh(math.max(50, teams.length));

  Future<void> _refresh(int count) async {
    if (_disposed) return;
    _timer?.cancel();
    _searchTimer?.cancel();
    final generation = ++_generation;
    final requestedQuery = query;
    loading = teams.isEmpty;
    refreshing = !loading;
    loadingMore = false;
    error = null;
    notifyListeners();
    try {
      final refreshed = <GlobalRanking>[];
      GlobalRankingPage page;
      int offset = 0;
      String? version;
      do {
        page = await _load(
            offset: offset, query: requestedQuery, snapshot: version);
        if (_disposed || generation != _generation) return;
        refreshed.addAll(page.teams);
        version = page.snapshot;
        offset = page.nextOffset ?? 0;
      } while (page.nextOffset != null && refreshed.length < count);
      teams = refreshed;
      _metadata(page);
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      error = failure;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        refreshing = false;
        // Start after completion so the next poll can outlive the server's
        // five-minute cache, even when the initial request takes a few seconds.
        _timer = Timer(refreshInterval, refresh);
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_disposed || loading || refreshing || loadingMore || nextOffset == null)
      return;
    final generation = _generation;
    loadingMore = true;
    error = null;
    notifyListeners();
    try {
      final page =
          await _load(offset: nextOffset!, query: query, snapshot: snapshot);
      if (_disposed || generation != _generation) return;
      teams = [...teams, ...page.teams];
      _metadata(page);
    } on RankingSnapshotExpired {
      if (!_disposed && generation == _generation)
        await _refresh(teams.length + 50);
    } catch (failure) {
      if (!_disposed && generation == _generation) error = failure;
    } finally {
      if (!_disposed && generation == _generation) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  void _metadata(GlobalRankingPage page) {
    ranges = page.ranges;
    year = page.year;
    total = page.total;
    matched = page.matched;
    nextOffset = page.nextOffset;
    snapshot = page.snapshot;
    updatedAt = page.updatedAt;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _timer?.cancel();
    _searchTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
