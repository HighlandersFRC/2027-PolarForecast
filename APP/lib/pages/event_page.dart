import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:app/APIService.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/services/live_data_controller.dart';
import 'package:app/models/event_data.dart';
import 'package:app/models/match_prediction.dart';
import 'package:app/models/team_stat.dart';
import 'package:app/widgets/MatchScouting.dart';
import 'package:app/widgets/PitScouting.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/DataSourceBanner.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:app/widgets/event_stats_grid.dart';
import 'package:app/widgets/team_comparison.dart';
import 'package:app/services/recent_events.dart';
import 'package:app/widgets/scout_stats_view.dart';
import 'package:file_saver/file_saver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Color _pageBackground = Colors.transparent;
const Color _surfaceColor = AppColors.surface;
const Color _surfaceColorLight = AppColors.surfaceSoft;
const Color _borderColor = AppColors.border;
const Color _accentColor = Color(0xFF4DA3FF);

class EventPage extends StatefulWidget {
  final String eventCode;
  final APIService? apiService;
  final int initialSection;

  const EventPage({
    super.key,
    required this.eventCode,
    this.apiService,
    this.initialSection = 0,
  });

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late final APIService _apiService;

  late LiveDataController<EventData> _eventData;
  late final String _apiEventKey;

  int _selectedIndex = 0;
  bool _scoutingOpened = false;
  bool _isRefreshing = false;
  bool _authStateInitialized = false;

  String _displayEvent = '';
  String? _statsUsername;
  String? _pitGroupId;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? APIService();
    _selectedIndex = const {0, 1, 2, 3, 5, 6, 7}.contains(widget.initialSection)
        ? widget.initialSection
        : 0;
    _scoutingOpened = _selectedIndex == 5;

    _apiEventKey = _eventKeyForApi(widget.eventCode);
    RecentEvents.remember(_apiEventKey);

    _loadEventName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listening here makes this page react when AuthService finishes
    // restoring a session, logs in, changes accounts, or logs out.
    final auth = Provider.of<AuthService>(context);
    final username = _usernameForStats(auth);
    final groupId = _groupIdForPitScouting(auth);

    if (!_authStateInitialized ||
        username != _statsUsername ||
        groupId != _pitGroupId) {
      _statsUsername = username;
      _pitGroupId = groupId;

      // Logged-in users request group-aware stats. Logged-out users pass
      // null, so the backend returns the regular public event stats.
      if (_authStateInitialized) {
        _eventData.refresh(replace: true);
      } else {
        _authStateInitialized = true;
        _eventData = LiveDataController(load: _loadEvent);
      }
    }
  }

  String? _usernameForStats(AuthService auth) {
    if (!auth.isLoggedIn) {
      return null;
    }

    final username = auth.username?.trim();

    if (username == null || username.isEmpty) {
      return null;
    }

    return username;
  }

  String? _groupIdForPitScouting(AuthService auth) {
    if (!auth.isLoggedIn) {
      return null;
    }

    final groupId = auth.groupId?.trim();

    if (groupId == null || groupId.isEmpty) {
      return null;
    }

    return groupId;
  }

  @override
  void dispose() {
    _eventData.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<EventData> _loadEvent() async {
    final results = await Future.wait([
      _apiService.fetchRawStatsByEvent(
        _apiEventKey,
        username: _statsUsername,
      ),
      _apiService.fetchPredictionsByEvent(_apiEventKey),
    ]);

    final stats = List<TeamStat>.from(results[0] as List<TeamStat>)
      ..sort((a, b) => a.Rank.compareTo(b.Rank));

    final predictions =
        List<MatchPrediction>.from(results[1] as List<MatchPrediction>);

    return EventData(
      stats: stats,
      predictions: predictions,
    );
  }

  Future<void> _loadEventName() async {
    try {
      final name = await _apiService.fetchEventDisplayNameByKey(_apiEventKey);

      if (!mounted) {
        return;
      }

      setState(() {
        _displayEvent = name;
      });
    } catch (_) {
      // The event key is still shown if its display name cannot be loaded.
    }
  }

  Future<void> _refreshPage() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _eventData.refresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final isWideLayout = screenWidth >= 1050;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: PolarForecastAppBar(
        extraText: _displayEvent,
      ),
      bottomNavigationBar: isWideLayout ? null : _buildBottomNavigation(),
      body: isWideLayout
          ? Row(
              children: [
                _buildNavigationRail(),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: _borderColor,
                ),
                Expanded(
                  child: _buildPageContent(),
                ),
              ],
            )
          : _buildPageContent(),
    );
  }

  Widget _buildPageContent() {
    return Column(
      children: [
        const DataSourceBanner(),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex == 5 ? 1 : 0,
            children: [
              ValueListenableBuilder<AsyncSnapshot<EventData>>(
                valueListenable: _eventData,
                builder: (context, snapshot, _) {
                  // Event stats refresh independently of the active scouting form.
                  // Replacing it with loading/error UI would dispose its draft.
                  if (_selectedIndex == 5) {
                    return const SizedBox.shrink();
                  }

                  if (_selectedIndex == 7) {
                    if (_statsUsername == null || _pitGroupId == null) {
                      return const _EmptyState(
                        icon: Icons.groups_outlined,
                        title: 'Group required',
                        message: 'Log in and join a group to view scout stats.',
                      );
                    }
                    return ScoutStatsView(
                      key: ValueKey(
                          '$_pitGroupId-$_statsUsername-$_apiEventKey'),
                      eventKey: _apiEventKey,
                      groupId: _pitGroupId!,
                      username: _statsUsername!,
                    );
                  }

                  if (_selectedIndex == 6) {
                    final username = _statsUsername;
                    final groupId = _pitGroupId;

                    if (username == null) {
                      return const _EmptyState(
                        icon: Icons.login_rounded,
                        title: 'Login required',
                        message:
                            'Log in to view your group pit scouting progress.',
                      );
                    }

                    if (groupId == null) {
                      return const _EmptyState(
                        icon: Icons.group_off_rounded,
                        title: 'No group found',
                        message:
                            'Join a group before viewing pit scouting progress.',
                      );
                    }

                    return PitScouting(
                      event: _apiEventKey,
                      groupId: groupId,
                      username: username,
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _PageLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load ${widget.eventCode}',
                      message: snapshot.error.toString(),
                      actionLabel: 'Try again',
                      onAction: _refreshPage,
                    );
                  }

                  final data = snapshot.data;

                  if (data == null) {
                    return _EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No event data',
                      message: 'There is no cached data for this event yet.',
                      actionLabel: 'Refresh',
                      onAction: _refreshPage,
                    );
                  }

                  return _buildSelectedPage(data);
                },
              ),
              if (_scoutingOpened)
                TickerMode(
                  enabled: _selectedIndex == 5,
                  child: MatchScouting(
                    key: ValueKey('$_apiEventKey-$_statsUsername-$_pitGroupId'),
                    event: _apiEventKey,
                    onSubmitted: _onScoutingSubmitted,
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPage(EventData data) {
    switch (_selectedIndex) {
      case 0:
        return _StatsView(
          eventCode: widget.eventCode,
          stats: data.stats,
          showScoutingAnalysis: _statsUsername != null,
        );
      case 1:
        return _PredictionsView(
          eventCode: widget.eventCode,
          predictions: data.predictions,
        );
      case 2:
        return _QualsView(
          eventCode: widget.eventCode,
          apiEventKey: _apiEventKey,
          stats: data.stats,
          predictions: data.predictions,
          groupId: _pitGroupId,
          username: _statsUsername,
        );
      case 4:
        return const SizedBox.shrink();
      case 3:
        return _ChartsView(
          eventCode: widget.eventCode,
          stats: data.stats,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavigation() {
    final destination =
        switch (_selectedIndex) { 0 => 0, 2 => 1, 5 => 2, _ => 4 };
    return NavigationBar(
      height: 68,
      selectedIndex: destination,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        if (index == 4) {
          _showMoreSections();
          return;
        }
        _selectEventSection([0, 2, 5, 4][index]);
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard_rounded),
            label: 'Stats'),
        NavigationDestination(
            icon: Icon(Icons.format_list_numbered_rounded), label: 'Matches'),
        NavigationDestination(
            icon: Icon(Icons.visibility_outlined),
            selectedIcon: Icon(Icons.visibility_rounded),
            label: 'Scout'),
        NavigationDestination(
            icon: Icon(Icons.playlist_add_check_rounded), label: 'Picks'),
        NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded), label: 'More'),
      ],
    );
  }

  void _showMoreSections() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Event tools',
                      style: TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w800))),
              for (final section in [
                (
                  6,
                  'Pit scouting',
                  'Reports, robot photos, and follow-ups',
                  Icons.assignment_outlined
                ),
                (
                  2,
                  'Qualification matches',
                  'Match schedule and alliance lineups',
                  Icons.format_list_numbered_rounded
                ),
                (
                  1,
                  'Predictions',
                  'Explore projected match outcomes',
                  Icons.insights_outlined
                ),
                (
                  3,
                  'Charts',
                  'Compare event performance visually',
                  Icons.query_stats_rounded
                ),
                (
                  7,
                  'Scout activity',
                  'Review your group scouting coverage',
                  Icons.groups_outlined
                ),
              ])
                ListTile(
                  selected: _selectedIndex == section.$1,
                  leading: Icon(section.$4),
                  title: Text(section.$2),
                  subtitle:
                      Text(section.$3, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _selectEventSection(section.$1);
                  },
                ),
            ]),
      )),
    );
  }

  Widget _buildNavigationRail() {
    final extended = MediaQuery.sizeOf(context).width >= 1250;
    final railWidth = extended ? 220.0 : 82.0;

    return ClipRect(
      child: Container(
        width: railWidth,
        color: _surfaceColor,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                child: Align(
                  alignment: extended ? Alignment.centerLeft : Alignment.center,
                  child: Tooltip(
                    message: 'Refresh event data',
                    child: IconButton.filledTonal(
                      onPressed: _isRefreshing ? null : _refreshPage,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNavigationSectionLabel(
                        label: 'Analytics',
                        icon: Icons.analytics_outlined,
                        extended: extended,
                      ),
                      const SizedBox(height: 7),
                      _buildNavigationRailItem(
                        index: 0,
                        label: 'Team stats',
                        icon: Icons.leaderboard_outlined,
                        selectedIcon: Icons.leaderboard_rounded,
                        extended: extended,
                      ),
                      _buildNavigationRailItem(
                        index: 1,
                        label: 'Predictions',
                        icon: Icons.insights_outlined,
                        selectedIcon: Icons.insights_rounded,
                        extended: extended,
                      ),
                      _buildNavigationRailItem(
                        index: 2,
                        label: 'Quals',
                        icon: Icons.format_list_numbered_outlined,
                        selectedIcon: Icons.format_list_numbered_rounded,
                        extended: extended,
                      ),
                      _buildNavigationRailItem(
                        index: 3,
                        label: 'Charts',
                        icon: Icons.query_stats_outlined,
                        selectedIcon: Icons.query_stats_rounded,
                        extended: extended,
                      ),
                      _buildNavigationRailItem(
                        index: 4,
                        label: 'Picklist',
                        icon: Icons.playlist_add_check_circle_outlined,
                        selectedIcon: Icons.playlist_add_check_circle_rounded,
                        extended: extended,
                      ),
                      _buildNavigationRailItem(
                        index: 7,
                        label: 'Scouts',
                        icon: Icons.groups_outlined,
                        selectedIcon: Icons.groups_rounded,
                        extended: extended,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 14,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.white.withOpacity(0.09),
                        ),
                      ),
                      _buildNavigationSectionLabel(
                        label: 'Data Collection',
                        icon: Icons.edit_note_rounded,
                        extended: extended,
                      ),
                      const SizedBox(height: 7),
                      _buildNavigationRailItem(
                        index: 5,
                        label: 'Match Scouting',
                        icon: Icons.visibility_outlined,
                        selectedIcon: Icons.visibility_rounded,
                        extended: extended,
                      ),
                      _buildNavigationRailItem(
                        index: 6,
                        label: 'Pit Scouting',
                        icon: Icons.assignment_outlined,
                        selectedIcon: Icons.assignment_rounded,
                        extended: extended,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationSectionLabel({
    required String label,
    required IconData icon,
    required bool extended,
  }) {
    if (!extended) {
      return Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Icon(
            icon,
            color: Colors.white30,
            size: 17,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white38,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRailItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required bool extended,
  }) {
    final selected = _selectedIndex == index;

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectEventSection(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: EdgeInsets.symmetric(
            horizontal: extended ? 13 : 0,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color:
                selected ? _accentColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _accentColor.withOpacity(0.22)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? _accentColor : Colors.white54,
                size: selected ? 25 : 23,
              ),
              if (extended) ...[
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white60,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (extended) {
      return item;
    }

    return Tooltip(
      message: label,
      child: item,
    );
  }

  void _onScoutingSubmitted() {
    // A request started before the save may still contain public/older stats.
    _eventData.refresh(replace: true);
  }

  void _selectEventSection(int index) {
    if (index == 4) {
      Navigator.pushNamed(context, '/event/$_apiEventKey/picklists');
      return;
    }
    final returningToStats = index == 0 && _selectedIndex != 0;
    setState(() {
      _selectedIndex = index;
      if (index == 5) _scoutingOpened = true;
    });
    if (returningToStats) _eventData.refresh();
  }
}

class _PageLoadingState extends StatelessWidget {
  const _PageLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Loading event data...',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

String _eventKeyForApi(String eventCode) {
  if (RegExp(r'^\d{4}').hasMatch(eventCode)) {
    return eventCode;
  }

  return '2026$eventCode';
}

/* ---------------- STATS ---------------- */

class _StatsView extends StatefulWidget {
  final String eventCode;
  final List<TeamStat> stats;
  final bool showScoutingAnalysis;

  const _StatsView({
    required this.eventCode,
    required this.stats,
    required this.showScoutingAnalysis,
  });

  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  final TextEditingController _searchController = TextEditingController();

  String _sortKey = 'rank';
  bool _comparing = false;
  final Set<int> _comparison = {};
  String _searchQuery = '';

  bool _ascending = true;
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _normalizedEventCode {
    return widget.eventCode.startsWith('2026')
        ? widget.eventCode
        : '2026${widget.eventCode}';
  }

  List<TeamStat> get _visibleStats {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = widget.stats.where((team) {
      if (query.isEmpty) {
        return true;
      }

      return team.Team.toString().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aValue = _sortValue(a);
      final bValue = _sortValue(b);
      // Missing observations stay last in either sort direction.
      if (aValue == null && bValue != null) return 1;
      if (bValue == null && aValue != null) return -1;
      final comparison = aValue == null ? 0 : aValue.compareTo(bValue!);
      if (comparison != 0) return _ascending ? comparison : -comparison;
      return a.Team.compareTo(b.Team);
    });
    return filtered;
  }

  num? _sortValue(TeamStat team) => switch (_sortKey) {
        'team' => team.Team,
        'rank' => team.Rank > 0 ? team.Rank : null,
        'rp' => team.RP,
        'opr' => team.OPR,
        'auto' => team.Auto,
        'teleop' => team.Teleop,
        'tower' => team.Tower,
        'death' => team.ScoutEntries > 0 ? team.DeathRate : null,
        'defense' => team.ScoutEntries > 0 ? team.DefenseRate : null,
        'scouted' => team.ScoutedMatches,
        _ => null,
      };

  @override
  void didUpdateWidget(covariant _StatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showScoutingAnalysis &&
        const {'death', 'defense', 'scouted'}.contains(_sortKey)) {
      _sortKey = 'rank';
      _ascending = true;
    }
  }

  void _sort(String key) {
    setState(() {
      if (_sortKey == key) {
        _ascending = !_ascending;
        return;
      }

      _sortKey = key;

      // Team and rank naturally sort from lowest to highest.
      // Performance values naturally sort from highest to lowest.
      _ascending = key == 'team' || key == 'rank' || key == 'death';
    });
  }

  void _goToTeam(TeamStat team) {
    Navigator.pushNamed(
      context,
      '/event/$_normalizedEventCode/${team.Team}/team',
    );
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  String _escapeCsvValue(Object? value) {
    final text = value?.toString() ?? '';

    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }

    return text;
  }

  String _createCsv(List<TeamStat> stats) {
    final rows = <List<Object?>>[
      [
        'Team',
        'Rank',
        'RP',
        'OPR',
        'Auto',
        'Teleop',
        'Tower',
        if (widget.showScoutingAnalysis) ...[
          'DeathRate',
          'DefenseRate',
          'ScoutedMatches',
        ],
      ],
      ...stats.map(
        (team) => [
          team.Team,
          team.Rank,
          team.RP,
          team.OPR,
          team.Auto,
          team.Teleop,
          team.Tower,
          if (widget.showScoutingAnalysis) ...[
            team.ScoutEntries > 0 ? team.DeathRate : null,
            team.ScoutEntries > 0 ? team.DefenseRate : null,
            team.ScoutedMatches,
          ],
        ],
      ),
    ];

    return rows
        .map(
          (row) => row.map(_escapeCsvValue).join(','),
        )
        .join('\r\n');
  }

  Future<void> _exportCsv() async {
    final stats = _visibleStats;

    if (_isExporting || stats.isEmpty) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final csvText = _createCsv(stats);

      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(csvText),
      ]);

      final safeEventCode = _normalizedEventCode.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );

      await FileSaver.instance.saveFile(
        name: '${safeEventCode}_team_stats',
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${stats.length} team${stats.length == 1 ? '' : 's'}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export CSV: $error'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stats.isEmpty) {
      return SizedBox.expand(
        child: _EmptyState(
          icon: Icons.leaderboard_outlined,
          title: 'No current stats',
          message: '${widget.eventCode} has not begun yet.',
        ),
      );
    }

    final visibleStats = _visibleStats;
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return ColoredBox(
      color: EventStatsGrid.backgroundColor,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(isMobile ? 12 : 16, 12, isMobile ? 12 : 16, 12),
        child: Column(
          children: [
            if (isMobile)
              _buildMobileToolbar(visibleStats)
            else
              _buildToolbar(visibleStats),
            Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                      onPressed: () => setState(() {
                            _comparing = !_comparing;
                            if (!_comparing) _comparison.clear();
                          }),
                      icon: Icon(
                          _comparing
                              ? Icons.close_rounded
                              : Icons.compare_arrows_rounded,
                          size: 18),
                      label: Text(
                          _comparing ? 'Done comparing' : 'Compare teams')),
                  if (_comparing) ...[
                    for (final team in _comparison)
                      InputChip(
                          label: Text('$team'),
                          onDeleted: () =>
                              setState(() => _comparison.remove(team))),
                    FilledButton.tonal(
                        onPressed: _comparison.length < 2
                            ? null
                            : () => showTeamComparison(
                                context,
                                widget.stats
                                    .where((t) => _comparison.contains(t.Team))
                                    .toList(),
                                scouting: widget.showScoutingAnalysis),
                        child: const Text('Compare')),
                  ],
                ]),
            if (_comparing)
              const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Tap up to 3 team rows to compare.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12))),
            const SizedBox(height: 4),
            Expanded(
              child: visibleStats.isEmpty
                  ? _buildNoSearchResults()
                  : EventStatsGrid(
                      key: ValueKey(_normalizedEventCode),
                      teams: visibleStats,
                      eventTeams: widget.stats,
                      showScoutingAnalysis: widget.showScoutingAnalysis,
                      sortKey: _sortKey,
                      ascending: _ascending,
                      onSort: _sort,
                      selectedTeams: _comparison,
                      onTeamTap: (team) {
                        if (!_comparing) {
                          _goToTeam(team);
                          return;
                        }
                        setState(() {
                          if (_comparison.contains(team.Team)) {
                            _comparison.remove(team.Team);
                          } else if (_comparison.length < 3) {
                            _comparison.add(team.Team);
                          }
                        });
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileToolbar(List<TeamStat> visibleStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Team stats',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(
                    '${visibleStats.length} teams · Sorted by ${_sortLabel()}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Export CSV',
              onPressed: _isExporting ? null : _exportCsv,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSearchField()),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              tooltip: 'Sort teams',
              initialValue: _sortKey,
              icon: const Icon(Icons.sort_rounded),
              onSelected: _sort,
              itemBuilder: (_) => [
                for (final item in [
                  ('rank', 'Rank'),
                  ('rp', 'RP'),
                  ('team', 'Team'),
                  ('opr', 'OPR'),
                  ('auto', 'Auto'),
                  ('teleop', 'Teleop'),
                  ('tower', 'Tower'),
                  if (widget.showScoutingAnalysis) ...[
                    ('death', 'Death rate'),
                    ('defense', 'Defense rate'),
                    ('scouted', 'Scouted matches'),
                  ],
                ])
                  CheckedPopupMenuItem(
                    value: item.$1,
                    checked: _sortKey == item.$1,
                    child: Text(item.$2),
                  ),
              ],
            ),
            IconButton(
              tooltip: _ascending ? 'Sort descending' : 'Sort ascending',
              onPressed: () => setState(() => _ascending = !_ascending),
              icon: Icon(_ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar(List<TeamStat> visibleStats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EventStatsGrid.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = _buildTitle(visibleStats);
              final actions = _buildActions();

              if (constraints.maxWidth < 780) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 16),
                    actions,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 24),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 530),
                      child: actions,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(List<TeamStat> visibleStats) {
    final isFiltered = _searchQuery.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF344A5E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.leaderboard_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Text(
                'Team Analytics',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          isFiltered
              ? '${_normalizedEventCode.toUpperCase()} • '
                  '${visibleStats.length} of ${widget.stats.length} teams'
              : '${_normalizedEventCode.toUpperCase()} • '
                  '${widget.stats.length} teams',
          style: const TextStyle(
            color: Color(0xFF9DA8B7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Sorted by ${_sortLabel()} '
          '${_ascending ? 'ascending' : 'descending'}',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchField = _buildSearchField();
        final exportButton = _buildExportButton();

        if (constraints.maxWidth < 470) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 10),
              exportButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 10),
            exportButton,
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search team number',
        hintStyle: const TextStyle(
          color: Colors.white38,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF8290A2),
          size: 21,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _clearSearch,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
        filled: true,
        fillColor: EventStatsGrid.surfaceColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFF3196FF),
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return FilledButton.icon(
      onPressed: _isExporting ? null : _exportCsv,
      icon: _isExporting
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.download_rounded,
              size: 19,
            ),
      label: Text(
        _isExporting ? 'Exporting' : 'Export CSV',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF365369),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF26384A),
        disabledForegroundColor: Colors.white54,
        minimumSize: const Size(132, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EventStatsGrid.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF3196FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: Color(0xFF55A9FF),
                  size: 29,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No matching teams',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No team number matches “${_searchQuery.trim()}”.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 17),
              OutlinedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Clear search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF55A9FF),
                  side: BorderSide(
                    color: const Color(0xFF3196FF).withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel() {
    switch (_sortKey) {
      case 'team':
        return 'team number';

      case 'rank':
        return 'rank';

      case 'rp':
        return 'RP';

      case 'opr':
        return 'OPR';

      case 'auto':
        return 'auto';

      case 'teleop':
        return 'teleop';

      case 'tower':
        return 'tower';
      case 'death':
        return 'death rate';
      case 'defense':
        return 'defense rate';
      case 'scouted':
        return 'scouted matches';

      default:
        return _sortKey;
    }
  }
}

/* ---------------- CHARTS ---------------- */

final List<Color> _chartTeamColors = List<Color>.generate(
  100,
  (index) {
    // The golden-angle step spreads neighboring palette entries around
    // the color wheel instead of producing several nearly identical colors.
    final hue = (index * 137.508) % 360.0;

    // Slight saturation and brightness variation makes teams with nearby
    // hues easier to distinguish while keeping every color readable on the
    // dark chart background.
    final saturation = 0.68 + ((index % 4) * 0.06);
    final value = 0.82 + ((index % 3) * 0.06);

    return HSVColor.fromAHSV(
      1,
      hue,
      saturation.clamp(0.0, 1.0).toDouble(),
      value.clamp(0.0, 1.0).toDouble(),
    ).toColor();
  },
  growable: false,
);

class _ChartsView extends StatelessWidget {
  final String eventCode;
  final List<TeamStat> stats;

  const _ChartsView({
    required this.eventCode,
    required this.stats,
  });

  Color _teamColor(int teamNumber) {
    final orderedTeams = stats.map((team) => team.Team).toList()..sort();
    final index = orderedTeams.indexOf(teamNumber);
    final safeIndex = index < 0 ? teamNumber.abs() : index;

    return _chartTeamColors[safeIndex % _chartTeamColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return _EmptyState(
        icon: Icons.query_stats_rounded,
        title: 'No chart data',
        message: 'Stats for ${eventCode} have not been cached yet.',
      );
    }

    final topTeams = [...stats]..sort((a, b) => b.OPR.compareTo(a.OPR));
    final topTeam = topTeams.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildChartsHeader(topTeam),
        const SizedBox(height: 14),
        _buildOprBarChartCard(),
      ],
    );
  }

  Widget _buildChartsHeader(TeamStat topTeam) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.query_stats_rounded,
                    color: _accentColor,
                    size: 25,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Event Charts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_eventKeyForApi(eventCode).toUpperCase()} • '
                'Compare current event OPRs.',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          );

          final summaries = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ChartSummaryPill(
                label: 'Top OPR',
                value: '${topTeam.Team} • ${topTeam.OPR.toStringAsFixed(1)}',
              ),
              _ChartSummaryPill(
                label: 'Teams',
                value: stats.length.toString(),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 16),
                summaries,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 20),
              summaries,
            ],
          );
        },
      ),
    );
  }

  Widget _buildOprBarChartCard() {
    final teams = [...stats]..sort((a, b) => b.OPR.compareTo(a.OPR));

    return _ChartCard(
      title: 'All team OPRs',
      subtitle: 'Every team ranked from highest to lowest current OPR.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartWidth = math
              .max(
                constraints.maxWidth,
                math.max(700.0, teams.length * 54.0),
              )
              .toDouble();

          final rawMinY = teams.map((team) => team.OPR).fold<double>(
                0,
                (current, value) => math.min(current, value).toDouble(),
              );
          final rawMaxY = teams.map((team) => team.OPR).fold<double>(
                0,
                (current, value) => math.max(current, value).toDouble(),
              );
          final range = math.max(1.0, rawMaxY - rawMinY).toDouble();
          final minY = math.min(0.0, rawMinY - range * 0.08).toDouble();
          final maxY = math.max(1.0, rawMaxY + range * 0.10).toDouble();
          final interval = math.max(1.0, (maxY - minY) / 5).toDouble();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: 360,
              child: BarChart(
                BarChartData(
                  minY: minY,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withOpacity(0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'OPR',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 58,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= teams.length) {
                            return const SizedBox.shrink();
                          }

                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Transform.rotate(
                              angle: -0.65,
                              child: Text(
                                teams[index].Team.toString(),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF11151C),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final team = teams[group.x.toInt()];

                        return BarTooltipItem(
                          'Team ${team.Team}\nOPR ${team.OPR.toStringAsFixed(1)}',
                          TextStyle(
                            color: _teamColor(team.Team),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: List.generate(teams.length, (index) {
                    final team = teams[index];
                    final color = _teamColor(team.Team);

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: team.OPR,
                          width: 24,
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                            bottom: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 320),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MattePanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ChartSummaryPill extends StatelessWidget {
  final String label;
  final String value;

  const _ChartSummaryPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: _surfaceColorLight,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QualsView extends StatefulWidget {
  final String eventCode;
  final String apiEventKey;
  final List<TeamStat> stats;
  final List<MatchPrediction> predictions;
  final String? groupId;
  final String? username;

  const _QualsView({
    required this.eventCode,
    required this.apiEventKey,
    required this.stats,
    required this.predictions,
    required this.groupId,
    required this.username,
  });

  @override
  State<_QualsView> createState() => _QualsViewState();
}

class _QualsViewState extends State<_QualsView> {
  final APIService _apiService = APIService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _scoutingRecords;
  int? _searchedTeam;
  String? _expandedMatchKey;

  bool get _canLoadAutos {
    return widget.groupId?.trim().isNotEmpty == true &&
        widget.username?.trim().isNotEmpty == true;
  }

  @override
  void initState() {
    super.initState();
    _scoutingRecords = _loadScoutingRecords();
  }

  @override
  void didUpdateWidget(covariant _QualsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.apiEventKey != widget.apiEventKey ||
        oldWidget.groupId != widget.groupId ||
        oldWidget.username != widget.username) {
      _scoutingRecords = _loadScoutingRecords();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadScoutingRecords() {
    if (!_canLoadAutos) {
      return Future.value(const <Map<String, dynamic>>[]);
    }

    return _apiService.getGroupMatchScoutingByEvent(
      groupId: widget.groupId!.trim(),
      username: widget.username!.trim(),
      event: widget.apiEventKey,
    );
  }

  List<MatchPrediction> get _qualificationMatches {
    final matches = widget.predictions.where((prediction) {
      final parsed = _ParsedMatchKey.fromKey(prediction.key);
      final matchesSearch = _searchedTeam == null ||
          prediction.red_teams.contains(_searchedTeam) ||
          prediction.blue_teams.contains(_searchedTeam);

      return parsed.compLevel == 'qm' && matchesSearch;
    }).toList();

    matches.sort((a, b) {
      return _ParsedMatchKey.fromKey(a.key)
          .compareTo(_ParsedMatchKey.fromKey(b.key));
    });

    return matches;
  }

  void _updateSearch(String value) {
    setState(() {
      _searchedTeam = int.tryParse(value.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchedTeam = null);
  }

  void _toggleMatch(String matchKey) {
    setState(() {
      _expandedMatchKey = _expandedMatchKey == matchKey ? null : matchKey;
    });
  }

  void _refreshAutos() {
    setState(() {
      _scoutingRecords = _loadScoutingRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allQuals = widget.predictions.where((prediction) {
      return _ParsedMatchKey.fromKey(prediction.key).compLevel == 'qm';
    }).length;

    if (allQuals == 0) {
      return _EmptyState(
        icon: Icons.format_list_numbered_rounded,
        title: 'No qualification matches',
        message:
            'Qualification predictions for ${widget.eventCode} are not available yet.',
      );
    }

    final matches = _qualificationMatches;
    final statsByTeam = <int, TeamStat>{
      for (final team in widget.stats) team.Team: team,
    };

    return Column(
      children: [
        MattePanel(
          width: double.infinity,
          borderRadius: BorderRadius.zero,
          tint: const Color(0xFF5FA8FF),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.format_list_numbered_rounded,
                      color: Color(0xFF91C5FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qualification Matches',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Team OPR, predicted scores, and scouted autos',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _QualCountPill(label: '$allQuals quals'),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                onChanged: _updateSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Filter by team number',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white54,
                  ),
                  suffixIcon: _searchedTeam == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear team filter',
                          onPressed: _clearSearch,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white60,
                          ),
                        ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.075),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: Color(0xFF8DC8FF),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _scoutingRecords,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _PageLoadingState();
              }

              final scoutingByMatch = _groupQualScouting(
                snapshot.data ?? const <Map<String, dynamic>>[],
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!_canLoadAutos) ...[
                    const _QualNotice(
                      icon: Icons.lock_outline_rounded,
                      message:
                          'Log in and join a group to include your group\'s match-scouting autos.',
                    ),
                    const SizedBox(height: 12),
                  ] else if (snapshot.hasError) ...[
                    _QualNotice(
                      icon: Icons.cloud_off_rounded,
                      message:
                          'Autos could not be loaded. OPR and predictions are still available.',
                      actionLabel: 'Retry',
                      onAction: _refreshAutos,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (matches.isEmpty)
                    const _QualNotice(
                      icon: Icons.search_off_rounded,
                      message: 'No qualification matches include that team.',
                    )
                  else
                    for (var index = 0; index < matches.length; index++) ...[
                      _QualMatchCard(
                        prediction: matches[index],
                        statsByTeam: statsByTeam,
                        scoutingByTeam: scoutingByMatch[
                                _ParsedMatchKey.fromKey(matches[index].key)
                                    .matchNumber] ??
                            const <int, List<Map<String, dynamic>>>{},
                        autosAvailable: _canLoadAutos && !snapshot.hasError,
                        highlightedTeam: _searchedTeam,
                        expanded: _expandedMatchKey == matches[index].key,
                        onTap: () => _toggleMatch(matches[index].key),
                      ),
                      if (index != matches.length - 1)
                        const SizedBox(height: 14),
                    ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

Map<int, Map<int, List<Map<String, dynamic>>>> _groupQualScouting(
  List<Map<String, dynamic>> records,
) {
  final grouped = <int, Map<int, List<Map<String, dynamic>>>>{};

  for (final record in records) {
    final matchNumber = _qualificationNumberFromScouting(record['match']);
    final teamValue = record['team'];
    final team = teamValue is num
        ? teamValue.toInt()
        : int.tryParse(teamValue?.toString() ?? '');

    if (matchNumber == null || team == null) {
      continue;
    }

    grouped
        .putIfAbsent(matchNumber, () => <int, List<Map<String, dynamic>>>{})
        .putIfAbsent(team, () => <Map<String, dynamic>>[])
        .add(record);
  }

  return grouped;
}

int? _qualificationNumberFromScouting(dynamic value) {
  final text = value?.toString().trim().toLowerCase() ?? '';
  if (text.isEmpty ||
      text.contains('semi') ||
      text.contains('final') ||
      RegExp(r'(^|_)sf\d').hasMatch(text)) {
    return null;
  }

  final qualifiedMatch = RegExp(r'(?:^|_|\b)qm\s*0*(\d+)').firstMatch(text);
  if (qualifiedMatch != null) {
    return int.tryParse(qualifiedMatch.group(1)!);
  }

  final plainNumber = int.tryParse(text);
  if (plainNumber != null) {
    return plainNumber;
  }

  if (text.contains('qual')) {
    final trailingNumber = RegExp(r'(\d+)\s*$').firstMatch(text);
    return int.tryParse(trailingNumber?.group(1) ?? '');
  }

  return null;
}

class _QualMatchCard extends StatelessWidget {
  final MatchPrediction prediction;
  final Map<int, TeamStat> statsByTeam;
  final Map<int, List<Map<String, dynamic>>> scoutingByTeam;
  final bool autosAvailable;
  final int? highlightedTeam;
  final bool expanded;
  final VoidCallback onTap;

  const _QualMatchCard({
    required this.prediction,
    required this.statsByTeam,
    required this.scoutingByTeam,
    required this.autosAvailable,
    required this.highlightedTeam,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = _ParsedMatchKey.fromKey(prediction.key);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  color: _surfaceColorLight,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          parsed.displayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _QualScorePill(
                        label: 'Red',
                        score: prediction.red_score,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _QualScorePill(
                        label: 'Blue',
                        score: prediction.blue_score,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final red = _QualAlliancePanel(
                          name: 'Red Alliance',
                          color: Colors.red,
                          predictedScore: prediction.red_score,
                          teams: prediction.red_teams,
                          statsByTeam: statsByTeam,
                          scoutingByTeam: scoutingByTeam,
                          autosAvailable: autosAvailable,
                          highlightedTeam: highlightedTeam,
                        );
                        final blue = _QualAlliancePanel(
                          name: 'Blue Alliance',
                          color: Colors.blue,
                          predictedScore: prediction.blue_score,
                          teams: prediction.blue_teams,
                          statsByTeam: statsByTeam,
                          scoutingByTeam: scoutingByTeam,
                          autosAvailable: autosAvailable,
                          highlightedTeam: highlightedTeam,
                        );

                        if (constraints.maxWidth < 760) {
                          return Column(
                            children: [red, const SizedBox(height: 12), blue],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: red),
                            const SizedBox(width: 12),
                            Expanded(child: blue),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QualScorePill extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _QualScorePill({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        '$label ${score.toStringAsFixed(1)}',
        style: TextStyle(
          color: color.withValues(alpha: 0.92),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QualAlliancePanel extends StatelessWidget {
  final String name;
  final Color color;
  final double predictedScore;
  final List<int> teams;
  final Map<int, TeamStat> statsByTeam;
  final Map<int, List<Map<String, dynamic>>> scoutingByTeam;
  final bool autosAvailable;
  final int? highlightedTeam;

  const _QualAlliancePanel({
    required this.name,
    required this.color,
    required this.predictedScore,
    required this.teams,
    required this.statsByTeam,
    required this.scoutingByTeam,
    required this.autosAvailable,
    required this.highlightedTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Predicted Score ${predictedScore.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: color.withValues(alpha: 0.20)),
          for (var index = 0; index < teams.length; index++) ...[
            _QualTeamRow(
              team: teams[index],
              stat: statsByTeam[teams[index]],
              scoutingRecords: scoutingByTeam[teams[index]] ??
                  const <Map<String, dynamic>>[],
              autosAvailable: autosAvailable,
              highlighted: teams[index] == highlightedTeam,
            ),
            if (index != teams.length - 1)
              const Divider(height: 1, color: Colors.white10),
          ],
        ],
      ),
    );
  }
}

class _QualTeamRow extends StatelessWidget {
  final int team;
  final TeamStat? stat;
  final List<Map<String, dynamic>> scoutingRecords;
  final bool autosAvailable;
  final bool highlighted;

  const _QualTeamRow({
    required this.team,
    required this.stat,
    required this.scoutingRecords,
    required this.autosAvailable,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final auto = _QualAutoSummary.fromRecords(scoutingRecords);
    final autoDescription = !autosAvailable
        ? 'Auto unavailable'
        : scoutingRecords.isEmpty
            ? 'No auto scouting'
            : auto.description;

    return Container(
      color: highlighted ? _accentColor.withValues(alpha: 0.14) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              'Team $team',
              style: TextStyle(
                color: highlighted ? const Color(0xFFB9DAFF) : Colors.white,
                fontSize: highlighted ? 16 : 14,
                fontWeight: highlighted ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              stat == null ? 'OPR —' : 'OPR ${stat!.OPR.toStringAsFixed(1)}',
              style: TextStyle(
                color: const Color(0xFF91C5FF),
                fontSize: 12,
                fontWeight: highlighted ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: autoDescription,
              child: Text(
                autoDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      scoutingRecords.isEmpty ? Colors.white38 : Colors.white70,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: highlighted ? FontWeight.w800 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualAutoSummary {
  final String path;
  final double? averageFuel;
  final int reports;

  const _QualAutoSummary({
    required this.path,
    required this.averageFuel,
    required this.reports,
  });

  factory _QualAutoSummary.fromRecords(
    List<Map<String, dynamic>> records,
  ) {
    if (records.isEmpty) {
      return const _QualAutoSummary(path: '', averageFuel: null, reports: 0);
    }

    final sorted = [...records]..sort((a, b) {
        final aDate = DateTime.tryParse(a['submitted_at']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['submitted_at']?.toString() ?? '');
        return (aDate ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(bDate ?? DateTime.fromMillisecondsSinceEpoch(0));
      });

    var path = '';
    for (final record in sorted.reversed) {
      path = _readQualAutoPath(record);
      if (path.isNotEmpty) {
        break;
      }
    }

    final fuels = <double>[];
    for (final record in records) {
      final data = _qualMap(record['data']);
      final autoScouting = _qualMap(
        data['autoScouting'] ?? data['auto_scouting'],
      );
      final rawFuel = autoScouting['fuel_scored'];
      final fuel = rawFuel is num
          ? rawFuel.toDouble()
          : double.tryParse(rawFuel?.toString() ?? '');
      if (fuel != null) {
        fuels.add(fuel);
      }
    }

    return _QualAutoSummary(
      path: path,
      averageFuel:
          fuels.isEmpty ? null : fuels.reduce((a, b) => a + b) / fuels.length,
      reports: records.length,
    );
  }

  String get description {
    final details = <String>[];
    if (averageFuel != null) {
      final fuel = averageFuel!;
      details.add(
        '${fuel == fuel.roundToDouble() ? fuel.toStringAsFixed(0) : fuel.toStringAsFixed(1)} avg fuel',
      );
    }
    details.add(path.isEmpty ? 'No path recorded' : path);
    if (reports > 1) {
      details.add('$reports reports');
    }
    return details.join(' • ');
  }
}

String _readQualAutoPath(Map<String, dynamic> record) {
  final data = _qualMap(record['data']);
  final rawAutoPath = data['autoPath'] ??
      data['auto_path'] ??
      record['autoPath'] ??
      record['auto_path'];

  dynamic rawPath;
  if (rawAutoPath is Map) {
    final autoPath = Map<String, dynamic>.from(rawAutoPath);
    rawPath = autoPath['path'] ?? autoPath['steps'];
  } else {
    rawPath = rawAutoPath;
  }

  rawPath ??= data['path'];

  if (rawPath is List) {
    return rawPath
        .map((step) => step.toString().trim())
        .where((step) => step.isNotEmpty)
        .join(' → ');
  }

  if (rawPath is String) {
    return rawPath.trim();
  }

  return '';
}

Map<String, dynamic> _qualMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

class _QualCountPill extends StatelessWidget {
  final String label;

  const _QualCountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceColorLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QualNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _QualNotice({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white60, height: 1.35),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/* ---------------- PREDICTIONS ---------------- */

class _PredictionsView extends StatefulWidget {
  final String eventCode;
  final List<MatchPrediction> predictions;

  const _PredictionsView({
    required this.eventCode,
    required this.predictions,
  });

  @override
  State<_PredictionsView> createState() => _PredictionsViewState();
}

class _PredictionsViewState extends State<_PredictionsView> {
  final TextEditingController _searchController = TextEditingController();

  int? searchedTeam;
  String selectedStage = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MatchPrediction> get filteredPredictions {
    final results = widget.predictions.where((prediction) {
      final parsed = _ParsedMatchKey.fromKey(prediction.key);

      final matchesTeam = searchedTeam == null ||
          prediction.red_teams.contains(searchedTeam) ||
          prediction.blue_teams.contains(searchedTeam);

      final matchesStage =
          selectedStage == 'all' || parsed.compLevel == selectedStage;

      return matchesTeam && matchesStage;
    }).toList();

    results.sort((a, b) {
      final parsedA = _ParsedMatchKey.fromKey(a.key);
      final parsedB = _ParsedMatchKey.fromKey(b.key);

      return parsedA.compareTo(parsedB);
    });

    return results;
  }

  void _updateSearch(String value) {
    setState(() {
      searchedTeam = int.tryParse(value.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      searchedTeam = null;
    });
  }

  int _countStage(String stage) {
    return widget.predictions.where((prediction) {
      return _ParsedMatchKey.fromKey(prediction.key).compLevel == stage;
    }).length;
  }

  List<Widget> _buildPredictionSections(
    List<MatchPrediction> predictions,
  ) {
    const stages = ['qm', 'sf', 'f'];
    final children = <Widget>[];

    for (final stage in stages) {
      final stagePredictions = predictions.where((prediction) {
        return _ParsedMatchKey.fromKey(prediction.key).compLevel == stage;
      }).toList();

      if (stagePredictions.isEmpty) {
        continue;
      }

      children.add(
        _PredictionSectionHeader(
          title: _ParsedMatchKey.stageName(stage),
          count: stagePredictions.length,
          icon: _ParsedMatchKey.stageIcon(stage),
        ),
      );

      children.add(const SizedBox(height: 10));

      for (var index = 0; index < stagePredictions.length; index++) {
        children.add(
          _PredictionCard(
            prediction: stagePredictions[index],
            searchedTeam: searchedTeam,
          ),
        );

        if (index != stagePredictions.length - 1) {
          children.add(const SizedBox(height: 12));
        }
      }

      children.add(const SizedBox(height: 22));
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.predictions.isEmpty) {
      return _EmptyState(
        icon: Icons.analytics_outlined,
        title: 'No predictions',
        message:
            'Predictions for ${widget.eventCode} have not been cached yet.',
      );
    }

    final displayedPredictions = filteredPredictions;

    final predictedWins = searchedTeam == null
        ? 0
        : displayedPredictions.where((prediction) {
            final winner = _predictionWinner(prediction);
            final teamIsRed = prediction.red_teams.contains(searchedTeam);
            final teamIsBlue = prediction.blue_teams.contains(searchedTeam);

            return (teamIsRed && winner == _PredictedWinner.red) ||
                (teamIsBlue && winner == _PredictedWinner.blue);
          }).length;

    final predictedLosses = searchedTeam == null
        ? 0
        : displayedPredictions.where((prediction) {
            final winner = _predictionWinner(prediction);
            final teamIsRed = prediction.red_teams.contains(searchedTeam);
            final teamIsBlue = prediction.blue_teams.contains(searchedTeam);

            return (teamIsRed && winner == _PredictedWinner.blue) ||
                (teamIsBlue && winner == _PredictedWinner.red);
          }).length;

    final predictedTies = searchedTeam == null
        ? 0
        : displayedPredictions.where((prediction) {
            return _predictionWinner(prediction) == _PredictedWinner.tie;
          }).length;

    final decidedMatches = predictedWins + predictedLosses;

    final predictedWinRate = searchedTeam == null || decidedMatches == 0
        ? 0.0
        : predictedWins / decidedMatches;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: Color(0x36FFFFFF),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: Colors.indigo.shade200,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match Predictions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 21,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Predicted alliance scores by match stage',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${widget.predictions.length} matches',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                onChanged: _updateSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by team number',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white54,
                  ),
                  suffixIcon: searchedTeam != null
                      ? IconButton(
                          tooltip: 'Clear team search',
                          onPressed: _clearSearch,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white60,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(
                      color: Colors.indigo.shade300,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StageFilterChip(
                      label: 'All',
                      count: widget.predictions.length,
                      selected: selectedStage == 'all',
                      onSelected: () {
                        setState(() {
                          selectedStage = 'all';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _StageFilterChip(
                      label: 'Qualification',
                      count: _countStage('qm'),
                      selected: selectedStage == 'qm',
                      onSelected: () {
                        setState(() {
                          selectedStage = 'qm';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _StageFilterChip(
                      label: 'Semi-Final',
                      count: _countStage('sf'),
                      selected: selectedStage == 'sf',
                      onSelected: () {
                        setState(() {
                          selectedStage = 'sf';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _StageFilterChip(
                      label: 'Final',
                      count: _countStage('f'),
                      selected: selectedStage == 'f',
                      onSelected: () {
                        setState(() {
                          selectedStage = 'f';
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (searchedTeam != null) ...[
                const SizedBox(height: 14),
                if (displayedPredictions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.28),
                      ),
                    ),
                    child: Text(
                      'No ${_stageFilterName(selectedStage).toLowerCase()} matches found for Team $searchedTeam.',
                      style: TextStyle(
                        color: Colors.orange.shade200,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Team $searchedTeam prediction summary',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 10.0;
                      final cardWidth = constraints.maxWidth < 620
                          ? (constraints.maxWidth - gap) / 2
                          : (constraints.maxWidth - (gap * 3)) / 4;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _PredictionStatCard(
                              icon: Icons.emoji_events_outlined,
                              label: 'Predicted Wins',
                              value: predictedWins.toString(),
                              valueColor: Colors.green.shade300,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _PredictionStatCard(
                              icon: Icons.trending_down_rounded,
                              label: 'Predicted Losses',
                              value: predictedLosses.toString(),
                              valueColor: Colors.orange.shade300,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _PredictionStatCard(
                              icon: Icons.balance_rounded,
                              label: 'Predicted Ties',
                              value: predictedTies.toString(),
                              valueColor: Colors.amber.shade200,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _PredictionStatCard(
                              icon: Icons.percent_rounded,
                              label: 'Win Rate',
                              value:
                                  '${(predictedWinRate * 100).toStringAsFixed(0)}%',
                              valueColor: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
        Expanded(
          child: displayedPredictions.isEmpty
              ? _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: searchedTeam == null
                      ? 'No matches in this stage'
                      : 'Team not found',
                  message: searchedTeam == null
                      ? 'There are no ${_stageFilterName(selectedStage).toLowerCase()} predictions available.'
                      : 'Team $searchedTeam does not appear in the selected predictions.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  children: _buildPredictionSections(
                    displayedPredictions,
                  ),
                ),
        ),
      ],
    );
  }
}

String _stageFilterName(String stage) {
  switch (stage) {
    case 'qm':
      return 'Qualification';
    case 'sf':
      return 'Semi-Final';
    case 'f':
      return 'Final';
    default:
      return 'All';
  }
}

enum _PredictedWinner {
  red,
  blue,
  tie,
}

_PredictedWinner _predictionWinner(MatchPrediction prediction) {
  if (prediction.red_score > prediction.blue_score) {
    return _PredictedWinner.red;
  }

  if (prediction.blue_score > prediction.red_score) {
    return _PredictedWinner.blue;
  }

  return _PredictedWinner.tie;
}

class _ParsedMatchKey implements Comparable<_ParsedMatchKey> {
  final String originalKey;
  final String compLevel;
  final int setNumber;
  final int matchNumber;

  const _ParsedMatchKey({
    required this.originalKey,
    required this.compLevel,
    required this.setNumber,
    required this.matchNumber,
  });

  factory _ParsedMatchKey.fromKey(String key) {
    final match = RegExp(
      r'_(qm|sf|f)(\d+)(?:m(\d+))?$',
    ).firstMatch(key);

    if (match == null) {
      return _ParsedMatchKey(
        originalKey: key,
        compLevel: 'unknown',
        setNumber: 0,
        matchNumber: 0,
      );
    }

    final level = match.group(1)!;
    final firstNumber = int.tryParse(match.group(2) ?? '') ?? 0;
    final secondNumber = int.tryParse(match.group(3) ?? '') ?? 0;

    if (level == 'qm') {
      return _ParsedMatchKey(
        originalKey: key,
        compLevel: level,
        setNumber: 0,
        matchNumber: firstNumber,
      );
    }

    return _ParsedMatchKey(
      originalKey: key,
      compLevel: level,
      setNumber: firstNumber,
      matchNumber: secondNumber == 0 ? 1 : secondNumber,
    );
  }

  static int stageOrder(String stage) {
    switch (stage) {
      case 'qm':
        return 0;
      case 'sf':
        return 1;
      case 'f':
        return 2;
      default:
        return 99;
    }
  }

  static String stageName(String stage) {
    switch (stage) {
      case 'qm':
        return 'Qualification';
      case 'sf':
        return 'Semi-Final';
      case 'f':
        return 'Final';
      default:
        return 'Match';
    }
  }

  static IconData stageIcon(String stage) {
    switch (stage) {
      case 'qm':
        return Icons.format_list_numbered_rounded;
      case 'sf':
        return Icons.account_tree_outlined;
      case 'f':
        return Icons.emoji_events_outlined;
      default:
        return Icons.sports_score_outlined;
    }
  }

  String get displayTitle {
    switch (compLevel) {
      case 'qm':
        return 'Qualification $matchNumber';
      case 'sf':
        return 'Semi-Final $setNumber • Match $matchNumber';
      case 'f':
        return 'Final $setNumber • Match $matchNumber';
      default:
        return originalKey;
    }
  }

  @override
  int compareTo(_ParsedMatchKey other) {
    final stageComparison =
        stageOrder(compLevel).compareTo(stageOrder(other.compLevel));

    if (stageComparison != 0) {
      return stageComparison;
    }

    final setComparison = setNumber.compareTo(other.setNumber);

    if (setComparison != 0) {
      return setComparison;
    }

    final matchComparison = matchNumber.compareTo(other.matchNumber);

    if (matchComparison != 0) {
      return matchComparison;
    }

    return originalKey.compareTo(other.originalKey);
  }
}

class _StageFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  const _StageFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo.withOpacity(0.22) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.indigo.shade300 : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.indigo.withOpacity(0.38)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _PredictionSectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white54,
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(
            color: AppColors.border,
          ),
        ),
      ],
    );
  }
}

class _PredictionStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _PredictionStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 106,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: valueColor,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final MatchPrediction prediction;
  final int? searchedTeam;

  const _PredictionCard({
    required this.prediction,
    this.searchedTeam,
  });

  @override
  Widget build(BuildContext context) {
    final parsedMatch = _ParsedMatchKey.fromKey(prediction.key);
    final winner = _predictionWinner(prediction);

    final margin =
        (prediction.red_score - prediction.blue_score).abs().toStringAsFixed(1);

    final teamIsRed =
        searchedTeam != null && prediction.red_teams.contains(searchedTeam);

    final teamIsBlue =
        searchedTeam != null && prediction.blue_teams.contains(searchedTeam);

    final String? searchedTeamAlliance = teamIsRed
        ? 'Red Alliance'
        : teamIsBlue
            ? 'Blue Alliance'
            : null;

    final Color? searchedTeamColor = teamIsRed
        ? Colors.red
        : teamIsBlue
            ? Colors.blue
            : null;

    final searchedTeamPredictedToWin =
        (teamIsRed && winner == _PredictedWinner.red) ||
            (teamIsBlue && winner == _PredictedWinner.blue);

    final searchedTeamPredictedToTie =
        searchedTeamAlliance != null && winner == _PredictedWinner.tie;

    final winnerColor = winner == _PredictedWinner.red
        ? Colors.red.shade300
        : winner == _PredictedWinner.blue
            ? Colors.blue.shade300
            : Colors.amber.shade200;

    final winnerBackground = winner == _PredictedWinner.red
        ? Colors.red.withOpacity(0.13)
        : winner == _PredictedWinner.blue
            ? Colors.blue.withOpacity(0.13)
            : Colors.amber.withOpacity(0.12);

    final winnerText = winner == _PredictedWinner.tie
        ? 'Predicted tie'
        : '${winner == _PredictedWinner.red ? 'Red' : 'Blue'} by $margin';

    // Supports confidence values such as 0.87 or 87.0.
    final confidencePercentage = prediction.confidence_percentage <= 1
        ? prediction.confidence_percentage * 100
        : prediction.confidence_percentage;

    final normalizedConfidence =
        (confidencePercentage / 100).clamp(0.0, 1.0).toDouble();

    final confidenceColor = _confidenceColor(confidencePercentage);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _ParsedMatchKey.stageIcon(parsedMatch.compLevel),
                      color: Colors.white60,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      parsedMatch.displayTitle,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: winnerBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: winnerColor.withOpacity(0.28),
                      ),
                    ),
                    child: Text(
                      winnerText,
                      style: TextStyle(
                        color: winnerColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildConfidenceCard(
                    context: context,
                    label: prediction.confidence_label,
                    percentage: confidencePercentage,
                    normalizedValue: normalizedConfidence,
                    color: confidenceColor,
                  ),
                  const SizedBox(height: 13),
                  if (searchedTeamAlliance != null &&
                      searchedTeamColor != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: searchedTeamColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: searchedTeamColor.withOpacity(0.42),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            color: searchedTeamColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Team $searchedTeam • $searchedTeamAlliance',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: searchedTeamPredictedToTie
                                  ? Colors.amber.withOpacity(0.16)
                                  : searchedTeamPredictedToWin
                                      ? Colors.green.withOpacity(0.16)
                                      : Colors.orange.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              searchedTeamPredictedToTie
                                  ? 'Predicted Tie'
                                  : searchedTeamPredictedToWin
                                      ? 'Predicted Win'
                                      : 'Predicted Loss',
                              style: TextStyle(
                                color: searchedTeamPredictedToTie
                                    ? Colors.amber.shade200
                                    : searchedTeamPredictedToWin
                                        ? Colors.green.shade300
                                        : Colors.orange.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                  ],
                  _AlliancePredictionRow(
                    color: Colors.red,
                    name: 'Red',
                    score: prediction.red_score,
                    teams: prediction.red_teams,
                    highlightedTeam: searchedTeam,
                    predictedWinner: winner == _PredictedWinner.red,
                    probability: prediction.red_win_probability,
                  ),
                  const SizedBox(height: 10),
                  _AlliancePredictionRow(
                    color: Colors.blue,
                    name: 'Blue',
                    score: prediction.blue_score,
                    teams: prediction.blue_teams,
                    highlightedTeam: searchedTeam,
                    predictedWinner: winner == _PredictedWinner.blue,
                    probability: prediction.blue_win_probability,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard({
    required BuildContext context,
    required String label,
    required double percentage,
    required double normalizedValue,
    required Color color,
  }) {
    final displayLabel =
        label.trim().isEmpty ? 'Unknown Confidence' : label.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: color.withOpacity(0.28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prediction Confidence',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.clamp(0, 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalizedValue,
              minHeight: 6,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green.shade300;
    }

    if (percentage >= 50) {
      return Colors.amber.shade300;
    }

    return Colors.orange.shade300;
  }
}

class _AlliancePredictionRow extends StatelessWidget {
  final Color color;
  final String name;
  final double score;
  final double probability;
  final List<int> teams;
  final int? highlightedTeam;
  final bool predictedWinner;

  const _AlliancePredictionRow({
    required this.color,
    required this.name,
    required this.score,
    required this.probability,
    required this.teams,
    required this.predictedWinner,
    this.highlightedTeam,
  });

  @override
  Widget build(BuildContext context) {
    final probabilityPercent = probability;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: predictedWinner ? color.withOpacity(0.09) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: predictedWinner ? color.withOpacity(0.36) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$name Alliance',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (predictedWinner) ...[
                      const SizedBox(width: 7),
                      Icon(
                        Icons.check_circle_rounded,
                        color: color,
                        size: 16,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${probabilityPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: teams.map((team) {
                    final isHighlighted = team == highlightedTeam;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? color.withOpacity(0.22)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHighlighted ? color : AppColors.border,
                          width: isHighlighted ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHighlighted) ...[
                            Icon(
                              Icons.search_rounded,
                              color: color,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            team.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isHighlighted
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(
              minWidth: 64,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'SCORE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  size: 31,
                  color: _accentColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
