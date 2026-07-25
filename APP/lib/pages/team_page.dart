import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/APIService.dart';
import 'package:app/models/follow_up.dart';
import 'package:app/models/team_stat.dart';
import 'package:app/models/team_stats.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TeamPage extends StatefulWidget {
  final String eventCode;
  final int team;
  final String groupId;
  final String username;

  const TeamPage({
    super.key,
    required this.eventCode,
    required this.team,
    required this.groupId,
    required this.username,
  });

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final double radius;
  final double blurSigma;
  final bool shadow;

  const _TeamGlassCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.tint = LiquidGlassColors.primary,
    this.radius = 20,
    this.blurSigma = 18,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LiquidGlassPanel(
        padding: padding,
        tint: tint,
        blurSigma: blurSigma,
        shadow: shadow,
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _TeamGlassInset extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final double radius;
  final bool expand;

  const _TeamGlassInset({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.tint = Colors.white,
    this.radius = 13,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.09),
            tint.withValues(alpha: 0.055),
            Colors.white.withValues(alpha: 0.025),
          ],
        ),
        border: Border.all(
          color: tint == Colors.white
              ? LiquidGlassColors.border
              : tint.withValues(alpha: 0.24),
        ),
      ),
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: surface) : surface;
  }
}

class _TeamPageState extends State<TeamPage> {
  late Future<TeamStats> _futureStats;
  late Future<List<dynamic>> _futureScouting;
  late Future<List<dynamic>> _futurePitScouting;
  late Future<List<FollowUpIncident>> _futureFollowUps;

  int _index = 0;

  // Dark theme colors (consistent palette)
  static const Color bg = Colors.transparent;
  static const Color card = LiquidGlassColors.glass;
  static const Color accent = LiquidGlassColors.primary;
  static const Color text = LiquidGlassColors.text;

  @override
  void initState() {
    super.initState();

    _futureStats = APIService().getTeamStats(
      widget.eventCode,
      widget.team,
    );

    _futureScouting = APIService().getMatchScoutingByGroupTeamEvent(
      groupId: widget.groupId,
      username: widget.username,
      team: widget.team,
      event: widget.eventCode,
    );

    _futurePitScouting = APIService().getPitScoutingByGroupTeamEvent(
        groupId: widget.groupId,
        username: widget.username,
        team: widget.team,
        event: widget.eventCode);

    _futureFollowUps = APIService().fetchFollowUpIncidents(
      groupId: widget.groupId,
      username: widget.username,
      team: widget.team,
      event: widget.eventCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: PolarForecastAppBar(),
      body: BackdropGroup(
        child: IndexedStack(
          index: _index,
          children: [
            _buildStatsTab(),
            _buildScoutingTab(),
            _buildPitScoutingTab(),
            _buildFollowUpTab(),
          ],
        ),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            backgroundColor: LiquidGlassColors.glassStrong,
            selectedItemColor: accent,
            unselectedItemColor: LiquidGlassColors.textMuted,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: "Stats",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.remove_red_eye),
                label: "Match Scouting",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: "Pit Scouting",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.heart_broken_rounded),
                label: "Follow-Ups",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // STATS TAB (UI IMPROVED)
  // =========================
  Widget _buildStatsTab() {
    return FutureBuilder<TeamStats>(
      future: _futureStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load team statistics',
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Colors.white24,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'No statistics found',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final team = snapshot.data!;
        final teamStats = team.stats;

        final history = List<TeamMatchHistory>.from(
          teamStats.MatchHistory,
        )..sort(
            (a, b) => _historySortValue(a).compareTo(
              _historySortValue(b),
            ),
          );

        final firstOpr = history.isNotEmpty ? history.first.OPR : teamStats.OPR;

        final latestOpr = history.isNotEmpty ? history.last.OPR : teamStats.OPR;

        final oprChange = latestOpr - firstOpr;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _buildTeamStatsHeader(
              teamNumber: team.team,
              rank: teamStats.Rank,
              opr: teamStats.OPR,
              oprChange: oprChange,
              matchesPlayed:
                  history.isNotEmpty ? history.last.MatchesPlayed : 0,
            ),
            const SizedBox(height: 14),
            _buildStatsFieldAccessCard(),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 950
                    ? 5
                    : constraints.maxWidth >= 600
                        ? 3
                        : 2;

                const spacing = 10.0;

                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatMetricCard(
                        title: 'OPR',
                        value: teamStats.OPR,
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF69A7FF),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatMetricCard(
                        title: 'Auto',
                        value: teamStats.Auto,
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFFFFB74D),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatMetricCard(
                        title: 'Teleop',
                        value: teamStats.Teleop,
                        icon: Icons.sports_esports_rounded,
                        color: const Color(0xFF47D7B0),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatMetricCard(
                        title: 'Endgame',
                        value: teamStats.Endgame,
                        icon: Icons.flag_rounded,
                        color: const Color(0xFFB388FF),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatMetricCard(
                        title: 'Climb',
                        value: teamStats.Climb,
                        icon: Icons.vertical_align_top_rounded,
                        color: const Color(0xFFFF7188),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _buildOprHistoryCard(history),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildMatchHistoryList(history),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatsFieldAccessCard() {
    return FutureBuilder<List<dynamic>>(
      future: _futurePitScouting,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TeamGlassCard(
            padding: const EdgeInsets.all(18),
            shadow: false,
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading field access...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        bool trench = false;
        bool bump = false;

        final entries = snapshot.data ?? const <dynamic>[];

        if (entries.isNotEmpty) {
          final rawEntry = entries.last;
          final entry = rawEntry is Map
              ? Map<String, dynamic>.from(rawEntry)
              : <String, dynamic>{};
          final data = _asMap(entry['data']);

          trench = data['trench'] == true;
          bump = data['bump'] == true;
        }

        late final String accessLabel;
        late final String description;
        late final IconData accessIcon;
        late final Color accessColor;

        if (trench && bump) {
          accessLabel = 'Both';
          description =
              'This robot can travel through the trench and over the bump.';
          accessIcon = Icons.alt_route_rounded;
          accessColor = const Color(0xFFB388FF);
        } else if (trench) {
          accessLabel = 'Trench';
          description = 'This robot can travel through the trench.';
          accessIcon = Icons.horizontal_rule_rounded;
          accessColor = const Color(0xFF69A7FF);
        } else if (bump) {
          accessLabel = 'Bump';
          description = 'This robot can travel over the bump.';
          accessIcon = Icons.landscape_rounded;
          accessColor = const Color(0xFFFFB74D);
        } else {
          accessLabel = 'None';
          description = entries.isEmpty
              ? 'No field-access capability has been recorded in pit scouting.'
              : 'This robot is not recorded as using the trench or bump.';
          accessIcon = Icons.block_rounded;
          accessColor = Colors.white54;
        }

        return _TeamGlassCard(
          padding: const EdgeInsets.all(18),
          tint: accessColor,
          radius: 18,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              final heading = Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accessColor.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      color: accessColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FIELD ACCESS',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Robot traversal capability',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final access = _TeamGlassInset(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                tint: accessColor,
                radius: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      accessIcon,
                      color: accessColor,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      accessLabel,
                      style: TextStyle(
                        color: accessColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compact) ...[
                    heading,
                    const SizedBox(height: 14),
                    access,
                  ] else
                    Row(
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 16),
                        access,
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTeamStatsHeader({
    required int teamNumber,
    required int rank,
    required double opr,
    required double oprChange,
    required int matchesPlayed,
  }) {
    final isImproving = oprChange > 0;
    final isDeclining = oprChange < 0;

    final trendColor = isImproving
        ? Colors.greenAccent
        : isDeclining
            ? Colors.redAccent
            : Colors.white54;

    final trendIcon = isImproving
        ? Icons.trending_up_rounded
        : isDeclining
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    return _TeamGlassCard(
      padding: const EdgeInsets.all(20),
      tint: const Color(0xFF69A7FF),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final teamInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TEAM PERFORMANCE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Team $teamNumber',
                style: const TextStyle(
                  color: text,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildHeaderChip(
                    icon: Icons.emoji_events_outlined,
                    label: 'Rank $rank',
                    color: const Color(0xFFFFC857),
                  ),
                  if (matchesPlayed > 0)
                    _buildHeaderChip(
                      icon: Icons.sports_score_rounded,
                      label: '$matchesPlayed Matches',
                      color: Colors.white70,
                    ),
                ],
              ),
            ],
          );

          final oprInfo = _TeamGlassInset(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            tint: const Color(0xFF69A7FF),
            radius: 15,
            child: Column(
              crossAxisAlignment:
                  compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                const Text(
                  'CURRENT OPR',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatStatValue(opr),
                  style: const TextStyle(
                    color: Color(0xFF8CBAFF),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendIcon,
                      color: trendColor,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${oprChange >= 0 ? '+' : ''}'
                      '${oprChange.toStringAsFixed(1)} over event',
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                teamInfo,
                const SizedBox(height: 16),
                oprInfo,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: teamInfo),
              const SizedBox(width: 20),
              oprInfo,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetricCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return _TeamGlassInset(
      padding: const EdgeInsets.all(14),
      tint: color,
      radius: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _formatStatValue(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: text,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOprHistoryCard(
    List<TeamMatchHistory> history,
  ) {
    const graphColor = Color(0xFF69A7FF);

    if (history.isEmpty) {
      return const _TeamGlassCard(
        padding: const EdgeInsets.all(24),
        tint: graphColor,
        radius: 18,
        child: const Column(
          children: [
            Icon(
              Icons.show_chart_rounded,
              color: Colors.white24,
              size: 42,
            ),
            SizedBox(height: 10),
            Text(
              'No OPR history available',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'The graph will appear as matches are played.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];

    var minimumOpr = history.first.OPR;
    var maximumOpr = history.first.OPR;

    for (var index = 0; index < history.length; index++) {
      final opr = history[index].OPR;

      if (opr < minimumOpr) {
        minimumOpr = opr;
      }

      if (opr > maximumOpr) {
        maximumOpr = opr;
      }

      spots.add(
        FlSpot(index.toDouble(), opr),
      );
    }

    final range = maximumOpr - minimumOpr;
    final padding = range == 0 ? (maximumOpr.abs() * 0.15) + 5 : range * 0.2;

    final minimumY = minimumOpr < 0 ? minimumOpr - padding : 0.0;

    final maximumY = maximumOpr + padding;

    final horizontalInterval =
        ((maximumY - minimumY) / 4).clamp(1.0, double.infinity).toDouble();

    final matchLabelInterval =
        history.length <= 7 ? 1 : (history.length / 7).ceil();

    final lowestMatch = history.reduce(
      (a, b) => a.OPR < b.OPR ? a : b,
    );

    final highestMatch = history.reduce(
      (a, b) => a.OPR > b.OPR ? a : b,
    );

    return _TeamGlassCard(
      padding: const EdgeInsets.all(18),
      tint: graphColor,
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OPR History',
            style: TextStyle(
              color: text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estimated contribution after each completed match',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHistorySummary(
                  label: 'Starting',
                  value: history.first.OPR,
                  match: _shortHistoryMatchLabel(history.first),
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHistorySummary(
                  label: 'Highest',
                  value: highestMatch.OPR,
                  match: _shortHistoryMatchLabel(highestMatch),
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHistorySummary(
                  label: 'Lowest',
                  value: lowestMatch.OPR,
                  match: _shortHistoryMatchLabel(lowestMatch),
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: history.length > 1 ? (history.length - 1).toDouble() : 1,
                minY: minimumY,
                maxY: maximumY,
                clipData: const FlClipData.all(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (_) {
                    return const FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: horizontalInterval,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
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
                      interval: 1,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();

                        if (index < 0 ||
                            index >= history.length ||
                            index % matchLabelInterval != 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _shortHistoryMatchLabel(history[index]),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(10),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.round();
                        final match = history[index];

                        return LineTooltipItem(
                          '${_historyMatchLabel(match)}\n'
                          'OPR ${spot.y.toStringAsFixed(1)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: graphColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: history.length <= 18,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: graphColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySummary({
    required String label,
    required double value,
    required String match,
    required Color color,
  }) {
    return _TeamGlassInset(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      tint: color,
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatStatValue(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            match,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryList(
    List<TeamMatchHistory> history,
  ) {
    return _TeamGlassCard(
      tint: const Color(0xFF69A7FF),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: Color(0xFF8CBAFF),
                  size: 20,
                ),
                SizedBox(width: 9),
                Text(
                  'Match History',
                  style: TextStyle(
                    color: text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Colors.white10,
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) {
              return const Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: Colors.white10,
              );
            },
            itemBuilder: (context, index) {
              final match = history[index];

              final previousOpr =
                  index > 0 ? history[index - 1].OPR : match.OPR;

              final change = match.OPR - previousOpr;

              final changeColor = change > 0
                  ? Colors.greenAccent
                  : change < 0
                      ? Colors.redAccent
                      : Colors.white38;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF69A7FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        _shortHistoryMatchLabel(match),
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF9BC3FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _historyMatchLabel(match),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${match.MatchesPlayed} matches played',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatStatValue(match.OPR),
                          style: const TextStyle(
                            color: text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (index > 0)
                          Text(
                            '${change >= 0 ? '+' : ''}'
                            '${change.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: changeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatStatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  int _historySortValue(TeamMatchHistory history) {
    final compLevel = history.CompLevel?.toLowerCase().trim() ?? '';

    if (compLevel == 'qm') {
      return history.MatchNumber;
    }

    if (compLevel == 'sf') {
      return 100000 + history.SetNumber * 100 + history.MatchNumber;
    }

    if (compLevel == 'f') {
      return 200000 + history.MatchNumber;
    }

    final match = history.Match.toLowerCase();

    final qualification = RegExp(r'qm(\d+)').firstMatch(match);

    if (qualification != null) {
      return int.tryParse(
            qualification.group(1) ?? '',
          ) ??
          0;
    }

    final semifinal = RegExp(r'sf(\d+)(?:m(\d+))?').firstMatch(match);

    if (semifinal != null) {
      final setNumber = int.tryParse(
            semifinal.group(1) ?? '',
          ) ??
          0;

      final matchNumber = int.tryParse(
            semifinal.group(2) ?? '',
          ) ??
          0;

      return 100000 + setNumber * 100 + matchNumber;
    }

    final finalMatch = RegExp(r'(?:^|_)f(\d+)').firstMatch(match);

    if (finalMatch != null) {
      return 200000 +
          (int.tryParse(
                finalMatch.group(1) ?? '',
              ) ??
              0);
    }

    return 300000 + history.MatchNumber;
  }

  String _historyMatchLabel(TeamMatchHistory history) {
    final compLevel = history.CompLevel?.toLowerCase().trim() ?? '';

    if (compLevel == 'qm') {
      return 'Qualification ${history.MatchNumber}';
    }

    if (compLevel == 'sf') {
      if (history.SetNumber > 0) {
        return 'Semi-Final ${history.SetNumber}-${history.MatchNumber}';
      }

      return 'Semi-Final ${history.MatchNumber}';
    }

    if (compLevel == 'f') {
      return 'Final ${history.MatchNumber}';
    }

    final match = history.Match.toLowerCase();

    final qualification = RegExp(r'qm(\d+)').firstMatch(match);

    if (qualification != null) {
      return 'Qualification ${qualification.group(1)}';
    }

    final semifinal = RegExp(r'sf(\d+)(?:m(\d+))?').firstMatch(match);

    if (semifinal != null) {
      final setNumber = semifinal.group(1);
      final matchNumber = semifinal.group(2);

      return matchNumber == null
          ? 'Semi-Final $setNumber'
          : 'Semi-Final $setNumber-$matchNumber';
    }

    final finalMatch = RegExp(r'(?:^|_)f(\d+)').firstMatch(match);

    if (finalMatch != null) {
      return 'Final ${finalMatch.group(1)}';
    }

    return history.Match;
  }

  String _shortHistoryMatchLabel(
    TeamMatchHistory history,
  ) {
    final compLevel = history.CompLevel?.toLowerCase().trim() ?? '';

    if (compLevel == 'qm') {
      return 'Q${history.MatchNumber}';
    }

    if (compLevel == 'sf') {
      if (history.SetNumber > 0) {
        return 'SF${history.SetNumber}-${history.MatchNumber}';
      }

      return 'SF${history.MatchNumber}';
    }

    if (compLevel == 'f') {
      return 'F${history.MatchNumber}';
    }

    final match = history.Match.toLowerCase();

    final qualification = RegExp(r'qm(\d+)').firstMatch(match);

    if (qualification != null) {
      return 'Q${qualification.group(1)}';
    }

    final semifinal = RegExp(r'sf(\d+)(?:m(\d+))?').firstMatch(match);

    if (semifinal != null) {
      final setNumber = semifinal.group(1);
      final matchNumber = semifinal.group(2);

      return matchNumber == null ? 'SF$setNumber' : 'SF$setNumber-$matchNumber';
    }

    final finalMatch = RegExp(r'(?:^|_)f(\d+)').firstMatch(match);

    if (finalMatch != null) {
      return 'F${finalMatch.group(1)}';
    }

    return history.Match;
  }

  // =========================
  // SCOUTING TAB (UI IMPROVED)
  // =========================
  Widget _buildScoutingTab() {
    return FutureBuilder<List<dynamic>>(
      future: _futureScouting,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load scouting entries',
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        }

        final scoutingEntries = (snapshot.data ?? [])
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList()
          ..sort(
            (a, b) => _matchSortValue(a['match']).compareTo(
              _matchSortValue(b['match']),
            ),
          );

        if (scoutingEntries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.query_stats_rounded,
                  color: Colors.white24,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'No scouting entries found',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Scouted matches will appear here.',
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: _buildScoutingTrendCard(scoutingEntries),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;

                    final columns = constraints.maxWidth >= 1200
                        ? 3
                        : constraints.maxWidth >= 760
                            ? 2
                            : 1;

                    final cardWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: scoutingEntries.map((entry) {
                        return SizedBox(
                          width: cardWidth,
                          child: _buildScoutingEntryCard(entry),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoutingTrendCard(
    List<Map<String, dynamic>> scoutingEntries,
  ) {
    const autoColor = Color(0xFF67A4FF);
    const teleopColor = Color(0xFF36D6B5);

    final autoSpots = <FlSpot>[];
    final teleopSpots = <FlSpot>[];

    var totalAuto = 0.0;
    var totalTeleop = 0.0;
    var highestValue = 0.0;

    for (var index = 0; index < scoutingEntries.length; index++) {
      final entry = scoutingEntries[index];
      final data = _asMap(entry['data']);
      final auto = _asMap(data['autoScouting']);
      final teleop = _asMap(data['teleopScouting']);

      final autoFuel = _asDouble(auto['fuel_scored']);
      final teleopFuel = _asDouble(teleop['fuel_scored']);

      totalAuto += autoFuel;
      totalTeleop += teleopFuel;

      highestValue = math.max(
        highestValue,
        math.max(autoFuel, teleopFuel),
      );

      autoSpots.add(
        FlSpot(index.toDouble(), autoFuel),
      );

      teleopSpots.add(
        FlSpot(index.toDouble(), teleopFuel),
      );
    }

    final averageAuto = totalAuto / scoutingEntries.length;
    final averageTeleop = totalTeleop / scoutingEntries.length;

    final chartMaxY = math.max(
      10.0,
      (highestValue * 1.2).ceilToDouble(),
    );

    final horizontalInterval = math.max(
      1.0,
      (chartMaxY / 4).ceilToDouble(),
    );

    final labelInterval = math.max(
      1,
      (scoutingEntries.length / 7).ceil(),
    );

    return _TeamGlassCard(
      tint: teleopColor,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Over Time',
                      style: TextStyle(
                        color: text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Auto and teleop fuel scored by match',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLegendItem(
                      label: 'Auto',
                      color: autoColor,
                    ),
                    _buildLegendItem(
                      label: 'Teleop',
                      color: teleopColor,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;

                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryTile(
                        icon: Icons.sports_score_rounded,
                        label: 'Matches',
                        value: scoutingEntries.length.toString(),
                        accent: Colors.white70,
                        compact: compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryTile(
                        icon: Icons.bolt_rounded,
                        label: 'Avg. Auto',
                        value: averageAuto.toStringAsFixed(1),
                        accent: autoColor,
                        compact: compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryTile(
                        icon: Icons.speed_rounded,
                        label: 'Avg. Teleop',
                        value: averageTeleop.toStringAsFixed(1),
                        accent: teleopColor,
                        compact: compact,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math
                      .max(
                        1,
                        scoutingEntries.length - 1,
                      )
                      .toDouble(),
                  minY: 0,
                  maxY: chartMaxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: horizontalInterval,
                    getDrawingHorizontalLine: (_) {
                      return const FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.circular(10),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final label = spot.barIndex == 0 ? 'Auto' : 'Teleop';

                          final color =
                              spot.barIndex == 0 ? autoColor : teleopColor;

                          return LineTooltipItem(
                            '$label: ${spot.y.toStringAsFixed(0)}',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList();
                      },
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: horizontalInterval,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              value.toStringAsFixed(0),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();

                          if (index < 0 ||
                              index >= scoutingEntries.length ||
                              index % labelInterval != 0) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _shortMatchName(
                                scoutingEntries[index]['match'],
                              ),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: autoSpots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: autoColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: scoutingEntries.length <= 15,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: autoColor.withOpacity(0.08),
                      ),
                    ),
                    LineChartBarData(
                      spots: teleopSpots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: teleopColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: scoutingEntries.length <= 15,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: teleopColor.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoutingEntryCard(Map<String, dynamic> entry) {
    const autoColor = Color(0xFF67A4FF);
    const teleopColor = Color(0xFF36D6B5);

    final data = _asMap(entry['data']);
    final auto = _asMap(data['autoScouting']);
    final teleop = _asMap(data['teleopScouting']);
    final misc = _asMap(data['misc']);
    final scoutInfo = _asMap(entry['scoutInfo']);

    // MatchScouting2026 stores the ordered autonomous route here:
    // data.autoPath.path
    final autoPathData = _asMap(data['autoPath'] ?? data['auto_path']);
    final autoPath = _asStringList(autoPathData['path']);

    final autoFuel = _asDouble(auto['fuel_scored']);
    final teleopFuel = _asDouble(teleop['fuel_scored']);

    final died = misc['died'] == true;
    final playedDefense =
        misc['defense'] == true || misc['played_defense'] == true;

    final comments = misc['comments']?.toString().trim() ?? '';
    final scoutName = scoutInfo['firstName']?.toString().trim() ?? 'Unknown';

    return _TeamGlassCard(
      tint: autoColor,
      radius: 16,
      blurSigma: 14,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formattedMatchName(entry['match']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry['event']?.toString() ?? 'Unknown event',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF67A4FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF67A4FF).withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    'Team ${entry['team'] ?? '—'}',
                    style: const TextStyle(
                      color: Color(0xFF9FC5FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(
              height: 1,
              color: Colors.white10,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildFuelMetric(
                    label: 'Auto Fuel',
                    value: autoFuel,
                    icon: Icons.bolt_rounded,
                    color: autoColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFuelMetric(
                    label: 'Teleop Fuel',
                    value: teleopFuel,
                    icon: Icons.speed_rounded,
                    color: teleopColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(
                  icon:
                      died ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  label: died ? 'Robot Died' : 'Robot Survived',
                  color: died ? Colors.redAccent : Colors.greenAccent,
                ),
                if (playedDefense)
                  _buildStatusChip(
                    icon: Icons.shield_rounded,
                    label: 'Played Defense',
                    color: Colors.orangeAccent,
                  ),
              ],
            ),
            if (comments.isNotEmpty) ...[
              const SizedBox(height: 14),
              _TeamGlassInset(
                padding: const EdgeInsets.all(12),
                radius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Comments',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      comments,
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white10,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white54,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scouted by $scoutName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AutoPathReplay(
              key: ValueKey(
                '${entry['event']}-${entry['match']}-${entry['team']}-${scoutInfo['username']}',
              ),
              path: autoPath,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelMetric({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return _TeamGlassInset(
      padding: const EdgeInsets.all(12),
      tint: color,
      radius: 12,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatNumber(value),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required bool compact,
  }) {
    return _TeamGlassInset(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: 11,
      ),
      tint: accent,
      radius: 12,
      child: Row(
        children: [
          if (!compact) ...[
            Icon(
              icon,
              color: accent,
              size: 19,
            ),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: accent,
                    fontSize: compact ? 17 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required Color color,
  }) {
    return _TeamGlassInset(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      tint: color,
      radius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return _TeamGlassInset(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      tint: color,
      radius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formattedMatchName(dynamic value) {
    final rawMatch = value?.toString().toLowerCase() ?? '';

    final qualificationMatch = RegExp(r'qm(\d+)').firstMatch(rawMatch);

    if (qualificationMatch != null) {
      return 'Qualification ${qualificationMatch.group(1)}';
    }

    final semifinalMatch = RegExp(r'sf(\d+)(?:m(\d+))?').firstMatch(rawMatch);

    if (semifinalMatch != null) {
      final setNumber = semifinalMatch.group(1);
      final matchNumber = semifinalMatch.group(2);

      return matchNumber == null
          ? 'Semi-Final $setNumber'
          : 'Semi-Final $setNumber-$matchNumber';
    }

    final finalMatch = RegExp(r'(?:^|_)f(\d+)').firstMatch(rawMatch);

    if (finalMatch != null) {
      return 'Final ${finalMatch.group(1)}';
    }

    return 'Match ${value ?? 'Unknown'}';
  }

  String _shortMatchName(dynamic value) {
    final rawMatch = value?.toString().toLowerCase() ?? '';

    final qualificationMatch = RegExp(r'qm(\d+)').firstMatch(rawMatch);

    if (qualificationMatch != null) {
      return 'Q${qualificationMatch.group(1)}';
    }

    final semifinalMatch = RegExp(r'sf(\d+)(?:m(\d+))?').firstMatch(rawMatch);

    if (semifinalMatch != null) {
      final setNumber = semifinalMatch.group(1);
      final matchNumber = semifinalMatch.group(2);

      return matchNumber == null ? 'SF$setNumber' : 'SF$setNumber-$matchNumber';
    }

    final finalMatch = RegExp(r'(?:^|_)f(\d+)').firstMatch(rawMatch);

    if (finalMatch != null) {
      return 'F${finalMatch.group(1)}';
    }

    return value?.toString() ?? '';
  }

  int _matchSortValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    final rawMatch = value?.toString().toLowerCase() ?? '';

    final qualificationMatch = RegExp(r'qm(\d+)').firstMatch(rawMatch);

    if (qualificationMatch != null) {
      return int.tryParse(qualificationMatch.group(1) ?? '') ?? 0;
    }

    final semifinalMatch = RegExp(r'sf(\d+)(?:m(\d+))?').firstMatch(rawMatch);

    if (semifinalMatch != null) {
      final setNumber = int.tryParse(semifinalMatch.group(1) ?? '') ?? 0;

      final matchNumber = int.tryParse(semifinalMatch.group(2) ?? '') ?? 0;

      return 100000 + setNumber * 100 + matchNumber;
    }

    final finalMatch = RegExp(r'(?:^|_)f(\d+)').firstMatch(rawMatch);

    if (finalMatch != null) {
      final matchNumber = int.tryParse(finalMatch.group(1) ?? '') ?? 0;

      return 200000 + matchNumber;
    }

    final fallbackNumber = RegExp(r'\d+').allMatches(rawMatch).toList();

    if (fallbackNumber.isNotEmpty) {
      return 300000 + (int.tryParse(fallbackNumber.last.group(0) ?? '') ?? 0);
    }

    return 400000;
  }

  // =========================
  // FOLLOW-UP / ROBOT DEATHS TAB
  // =========================
  Widget _buildFollowUpTab() {
    return FutureBuilder<List<FollowUpIncident>>(
      future: _futureFollowUps,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 46,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load robot deaths',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refreshFollowUps,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final incidents = List<FollowUpIncident>.from(
          snapshot.data ?? const <FollowUpIncident>[],
        )..sort(
            (a, b) => _matchSortValue(a.match).compareTo(
              _matchSortValue(b.match),
            ),
          );

        if (incidents.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshFollowUps,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 100),
                Icon(
                  Icons.health_and_safety_outlined,
                  color: Color(0xFF4ADE80),
                  size: 54,
                ),
                SizedBox(height: 14),
                Text(
                  'No robot deaths recorded',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'This team has no match-scouting entries marked as died.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }

        final pendingCount = incidents.where((incident) {
          return !incident.resolved;
        }).length;

        final resolvedCount = incidents.length - pendingCount;

        return RefreshIndicator(
          onRefresh: _refreshFollowUps,
          color: Colors.white,
          backgroundColor: card,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            children: [
              _buildFollowUpSummary(
                totalDeaths: incidents.length,
                pendingCount: pendingCount,
                resolvedCount: resolvedCount,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 12.0;

                  final columns = constraints.maxWidth >= 1100
                      ? 3
                      : constraints.maxWidth >= 720
                          ? 2
                          : 1;

                  final itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: incidents.map((incident) {
                      return SizedBox(
                        width: itemWidth,
                        child: _buildDeathIncidentCard(incident),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowUpSummary({
    required int totalDeaths,
    required int pendingCount,
    required int resolvedCount,
  }) {
    final hasPending = pendingCount > 0;
    final statusColor =
        hasPending ? const Color(0xFFF87171) : const Color(0xFF4ADE80);

    return _TeamGlassCard(
      padding: const EdgeInsets.all(18),
      tint: statusColor,
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasPending
                      ? Icons.notification_important_outlined
                      : Icons.task_alt_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Robot Deaths & Follow-Ups',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasPending
                          ? '$pendingCount death incident${pendingCount == 1 ? '' : 's'} still need follow-up.'
                          : 'Every recorded death incident has been followed up.',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refreshFollowUps,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFollowUpSummaryMetric(
                  label: 'Deaths',
                  value: totalDeaths.toString(),
                  color: const Color(0xFFF87171),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFollowUpSummaryMetric(
                  label: 'Pending',
                  value: pendingCount.toString(),
                  color: pendingCount > 0
                      ? const Color(0xFFFACC15)
                      : const Color(0xFF4ADE80),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFollowUpSummaryMetric(
                  label: 'Resolved',
                  value: resolvedCount.toString(),
                  color: const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpSummaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return _TeamGlassInset(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      tint: color,
      radius: 12,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeathIncidentCard(
    FollowUpIncident incident,
  ) {
    final resolved = incident.resolved;
    final statusColor =
        resolved ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    return _TeamGlassCard(
      tint: statusColor,
      radius: 17,
      blurSigma: 14,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.heart_broken_rounded,
                    color: statusColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formattedMatchName(incident.match),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${incident.reportCount} death report${incident.reportCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildFollowUpIncidentStatus(
                  resolved: resolved,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(
              height: 1,
              color: Colors.white10,
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  color: Color(0xFFFCA5A5),
                  size: 17,
                ),
                SizedBox(width: 7),
                Text(
                  'What the scouts saw',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (incident.deathReports.isEmpty)
              _buildDeathReportEmptyState()
            else
              ...List.generate(
                incident.deathReports.length,
                (index) {
                  final report = incident.deathReports[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == incident.deathReports.length - 1 ? 0 : 9,
                    ),
                    child: _buildDeathReportCard(report),
                  );
                },
              ),
            const SizedBox(height: 14),
            if (resolved && incident.followup != null)
              _buildResolutionCard(incident.followup!)
            else
              _buildPendingResolutionCard(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openFollowUpPage(),
                icon: Icon(
                  resolved
                      ? Icons.visibility_outlined
                      : Icons.build_circle_outlined,
                ),
                label: Text(
                  resolved ? 'View Follow-Ups' : 'Complete Follow-Up',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: statusColor,
                  backgroundColor: statusColor.withOpacity(0.06),
                  side: BorderSide(
                    color: statusColor.withOpacity(0.45),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpIncidentStatus({
    required bool resolved,
  }) {
    final color = resolved ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    return _TeamGlassInset(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      tint: color,
      radius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            resolved
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            resolved ? 'Resolved' : 'Needs Follow-Up',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeathReportCard(DeathReport report) {
    final comments = report.comments.trim();
    final timestamp = _formatFollowUpTimestamp(report.submittedAt);

    return _TeamGlassInset(
      padding: const EdgeInsets.all(12),
      tint: const Color(0xFFF87171),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comments.isEmpty
                ? 'The robot was marked as died, but no explanation was provided.'
                : comments,
            style: TextStyle(
              color: comments.isEmpty ? Colors.white38 : Colors.white70,
              fontSize: 13,
              height: 1.4,
              fontStyle: comments.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              _buildIncidentMetadata(
                icon: Icons.person_outline_rounded,
                text: report.scoutName.trim().isEmpty
                    ? 'Unknown scout'
                    : report.scoutName,
              ),
              if (timestamp != null)
                _buildIncidentMetadata(
                  icon: Icons.schedule_rounded,
                  text: timestamp,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeathReportEmptyState() {
    return const _TeamGlassInset(
      padding: const EdgeInsets.all(12),
      radius: 12,
      child: const Text(
        'No death-report details were returned for this match.',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildResolutionCard(
    FollowUpResolution resolution,
  ) {
    final severity = resolution.severity.trim();
    final comments = resolution.comments.trim();
    final timestamp = _formatFollowUpTimestamp(resolution.submittedAt);

    return _TeamGlassInset(
      padding: const EdgeInsets.all(13),
      tint: const Color(0xFF4ADE80),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF4ADE80),
                size: 18,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Follow-Up Completed',
                  style: TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (severity.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.055),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    severity,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            comments.isEmpty
                ? 'No resolution comments were provided.'
                : comments,
            style: TextStyle(
              color: comments.isEmpty ? Colors.white38 : Colors.white70,
              fontSize: 13,
              height: 1.4,
              fontStyle: comments.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              _buildIncidentMetadata(
                icon: Icons.engineering_outlined,
                text: resolution.scoutName.trim().isEmpty
                    ? 'Unknown scout'
                    : resolution.scoutName,
              ),
              if (timestamp != null)
                _buildIncidentMetadata(
                  icon: Icons.schedule_rounded,
                  text: timestamp,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingResolutionCard() {
    return const _TeamGlassInset(
      padding: const EdgeInsets.all(13),
      tint: Color(0xFFFACC15),
      radius: 12,
      child: const Row(
        children: [
          Icon(
            Icons.pending_actions_rounded,
            color: Color(0xFFFACC15),
            size: 19,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'This death still needs a follow-up explaining the cause and repair.',
              style: TextStyle(
                color: Color(0xFFFDE68A),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentMetadata({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white38,
          size: 14,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String? _formatFollowUpTimestamp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value)?.toLocal();

    if (parsed == null) {
      return value;
    }

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hourValue = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';

    return '$month/$day $hourValue:$minute $period';
  }

  Future<void> _refreshFollowUps() async {
    final future = APIService().fetchFollowUpIncidents(
      groupId: widget.groupId,
      username: widget.username,
      team: widget.team,
      event: widget.eventCode,
    );

    setState(() {
      _futureFollowUps = future;
    });

    await future;
  }

  Future<void> _openFollowUpPage() async {
    await Navigator.pushNamed(
      context,
      '/event/${widget.eventCode}/team/${widget.team}/followup',
    );

    if (!mounted) return;

    await _refreshFollowUps();
  }

  Widget _buildPitScoutingTab() {
    return FutureBuilder<List<dynamic>>(
      future: _futurePitScouting,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "Could not load pit scouting:\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
          );
        }

        final scoutingEntries = snapshot.data ?? [];

        if (scoutingEntries.isEmpty) {
          return const Center(
            child: Text(
              "No pit scouting found",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final dynamic rawEntry = scoutingEntries.last;

        final Map<String, dynamic> entry = rawEntry is Map
            ? Map<String, dynamic>.from(rawEntry)
            : <String, dynamic>{};

        final Map<String, dynamic> scoutInfo = entry['scoutInfo'] is Map
            ? Map<String, dynamic>.from(entry['scoutInfo'])
            : <String, dynamic>{};

        final Map<String, dynamic> data = entry['data'] is Map
            ? Map<String, dynamic>.from(entry['data'])
            : <String, dynamic>{};

        /*
       * Expected structure:
       *
       * data: {
       *   autos: {
       *     autos: {
       *       auto_path: [...]
       *     }
       *   }
       * }
       *
       * The fallback logic also supports:
       * data.autos.auto_path
       * data.auto_path
       */
        final List<Map<String, dynamic>> autoPaths = _readPitAutoPaths(data);

        final bool trench = data['trench'] == true;
        final bool bump = data['bump'] == true;

        final String shooterType = _displayPitValue(data['shooter_type']);

        final String climb = _displayPitValue(data['climb']);

        final String driveTrain = _displayPitValue(data['drive_train']);

        final String favoriteRobotPart =
            _displayPitValue(data['favorite_robot_part']);

        final String comments = _displayPitValue(data['comments']);

        final int driverEvents =
            int.tryParse(data['driver_events']?.toString() ?? '') ?? 0;

        final double bps = double.tryParse(data['bps']?.toString() ?? '') ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header
              _TeamGlassCard(
                padding: const EdgeInsets.all(16),
                tint: Colors.blueAccent,
                radius: 16,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing_outlined,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Team ${entry['team'] ?? widget.team}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: text,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayPitValue(entry['event']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Field access
              _buildPitDisplaySection(
                icon: Icons.route_outlined,
                title: "Field Access",
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildPitBooleanTile(
                          label: "Trench",
                          value: trench,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPitBooleanTile(
                          label: "Bump",
                          value: bump,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Robot configuration
              _buildPitDisplaySection(
                icon: Icons.settings_outlined,
                title: "Robot Configuration",
                children: [
                  _buildPitInformationRow(
                    icon: Icons.sports_basketball_outlined,
                    label: "Shooter Type",
                    value: shooterType,
                  ),
                  const SizedBox(height: 10),
                  _buildPitInformationRow(
                    icon: Icons.vertical_align_top_rounded,
                    label: "Climb",
                    value: climb,
                  ),
                  const SizedBox(height: 10),
                  _buildPitInformationRow(
                    icon: Icons.tire_repair_outlined,
                    label: "Drivetrain",
                    value: driveTrain,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Autonomous path
              _buildPitDisplaySection(
                icon: Icons.alt_route_rounded,
                title: "Autonomous Paths",
                subtitle:
                    "${autoPaths.length} ${autoPaths.length == 1 ? 'path' : 'paths'} recorded",
                children: [
                  if (autoPaths.isEmpty)
                    const _TeamGlassInset(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 18,
                      ),
                      expand: true,
                      radius: 12,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.route_outlined,
                            color: Colors.white38,
                            size: 30,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "No autonomous paths recorded.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: List.generate(
                        autoPaths.length,
                        (pathIndex) {
                          final pathData = autoPaths[pathIndex];

                          final String pathName =
                              (pathData['name'] ?? 'Auto ${pathIndex + 1}')
                                  .toString();

                          final List<String> actions = pathData['path'] is List
                              ? List<String>.from(
                                  (pathData['path'] as List).map(
                                    (item) => item.toString(),
                                  ),
                                )
                              : <String>[];

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  pathIndex == autoPaths.length - 1 ? 0 : 14,
                            ),
                            child: _TeamGlassInset(
                              padding: const EdgeInsets.all(14),
                              tint: Colors.blueAccent,
                              expand: true,
                              radius: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${pathIndex + 1}",
                                          style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pathName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              "${actions.length} "
                                              "${actions.length == 1 ? 'action' : 'actions'}",
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (actions.isEmpty)
                                    const _TeamGlassInset(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      expand: true,
                                      radius: 10,
                                      child: const Text(
                                        "No actions recorded for this path.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      children: List.generate(
                                        actions.length,
                                        (actionIndex) {
                                          final action = actions[actionIndex];

                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: actionIndex ==
                                                      actions.length - 1
                                                  ? 0
                                                  : 9,
                                            ),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                minHeight: 56,
                                              ),
                                              child: _TeamGlassInset(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 11,
                                                  vertical: 9,
                                                ),
                                                tint: Colors.blueAccent,
                                                expand: true,
                                                radius: 11,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 34,
                                                      height: 34,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blueAccent
                                                            .withValues(
                                                          alpha: 0.14,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          9,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        "${actionIndex + 1}",
                                                        style: const TextStyle(
                                                          color:
                                                              Colors.blueAccent,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 11),
                                                    Expanded(
                                                      child: Text(
                                                        action,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          height: 1.35,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Experience
              _buildPitDisplaySection(
                icon: Icons.sports_esports_outlined,
                title: "Driver Experience",
                children: [
                  _buildPitInformationRow(
                    icon: Icons.event_outlined,
                    label: "Driver Events",
                    value:
                        "$driverEvents ${driverEvents == 1 ? 'event' : 'events'}",
                  ),
                ],
              ),

              _buildPitDisplaySection(
                icon: Icons.sports_esports_outlined,
                title: "Fuel Per Second",
                children: [
                  _buildPitInformationRow(
                    icon: Icons.event_outlined,
                    label: "FPS",
                    value: "${bps} Fuel Per Second",
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Favorite feature
              _buildPitDisplaySection(
                icon: Icons.favorite_border_rounded,
                title: "Favorite Robot Feature",
                children: [
                  _buildPitTextBlock(
                    value: favoriteRobotPart,
                    emptyMessage: "No favorite robot feature provided.",
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Comments
              _buildPitDisplaySection(
                icon: Icons.notes_outlined,
                title: "Comments",
                children: [
                  _buildPitTextBlock(
                    value: comments,
                    emptyMessage: "No comments provided.",
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Scout information
              _buildPitDisplaySection(
                icon: Icons.person_outline_rounded,
                title: "Scout Information",
                children: [
                  _buildPitInformationRow(
                    icon: Icons.badge_outlined,
                    label: "Name",
                    value: _displayPitValue(
                      scoutInfo['firstName'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPitDisplaySection({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return _TeamGlassCard(
      padding: const EdgeInsets.all(14),
      tint: Colors.blueAccent,
      radius: 16,
      blurSigma: 14,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.blueAccent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPitBooleanTile({
    required String label,
    required bool value,
  }) {
    final tileColor = value ? Colors.greenAccent : Colors.white;

    return _TeamGlassInset(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      tint: tileColor,
      radius: 12,
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: value ? Colors.greenAccent : Colors.white38,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value ? "Yes" : "No",
            style: TextStyle(
              color: value ? Colors.greenAccent : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return _TeamGlassInset(
      padding: const EdgeInsets.all(12),
      expand: true,
      radius: 12,
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitTextBlock({
    required String value,
    required String emptyMessage,
  }) {
    final bool hasValue = value.trim().isNotEmpty && value != "Not provided";

    return _TeamGlassInset(
      padding: const EdgeInsets.all(13),
      expand: true,
      radius: 12,
      child: Text(
        hasValue ? value : emptyMessage,
        style: TextStyle(
          color: hasValue ? Colors.white70 : Colors.white38,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }

  String _displayPitValue(dynamic value) {
    if (value == null) {
      return "Not provided";
    }

    final String result = value.toString().trim();

    if (result.isEmpty ||
        result.toLowerCase() == "null" ||
        result.toLowerCase() == "none") {
      return "Not provided";
    }

    return result;
  }

  List<Map<String, dynamic>> _readPitAutoPaths(
    Map<String, dynamic> data,
  ) {
    dynamic rawAutoPaths;

    final dynamic autosValue = data['autos'];

    if (autosValue is Map) {
      final autos = Map<String, dynamic>.from(autosValue);

      final dynamic nestedAutosValue = autos['autos'];

      if (nestedAutosValue is Map) {
        final nestedAutos = Map<String, dynamic>.from(nestedAutosValue);

        rawAutoPaths = nestedAutos['auto_paths'];

        // Compatibility with the old single-path format.
        if (rawAutoPaths == null && nestedAutos['auto_path'] is List) {
          rawAutoPaths = [
            {
              'name': 'Auto 1',
              'path': nestedAutos['auto_path'],
            },
          ];
        }
      } else {
        rawAutoPaths = autos['auto_paths'];

        if (rawAutoPaths == null && autos['auto_path'] is List) {
          rawAutoPaths = [
            {
              'name': 'Auto 1',
              'path': autos['auto_path'],
            },
          ];
        }
      }
    }

    rawAutoPaths ??= data['auto_paths'];

    if (rawAutoPaths == null && data['auto_path'] is List) {
      rawAutoPaths = [
        {
          'name': 'Auto 1',
          'path': data['auto_path'],
        },
      ];
    }

    if (rawAutoPaths is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawAutoPaths.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);

      final rawPath = map['path'];

      return <String, dynamic>{
        'name': (map['name'] ?? 'Auto').toString(),
        'path': rawPath is List
            ? rawPath
                .map((action) => action.toString().trim())
                .where((action) => action.isNotEmpty)
                .toList()
            : <String>[],
      };
    }).toList();
  }
}

// ============================================================
// MATCH-SCOUTING AUTO PATH REPLAY
// ============================================================

class _AutoPathReplay extends StatefulWidget {
  final List<String> path;
  final String fieldImagePath;

  const _AutoPathReplay({
    super.key,
    required this.path,
  }) : fieldImagePath = '2026FRCFeildImageFull.png';

  @override
  State<_AutoPathReplay> createState() => _AutoPathReplayState();
}

class _AutoPathReplayState extends State<_AutoPathReplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _playing = false;

  List<_AutoWaypoint> get _allWaypoints {
    return widget.path
        .asMap()
        .entries
        .map((entry) {
          final action = entry.value;
          final position = _AutoPathCoordinates.positionFor(action);

          if (position == null) {
            return null;
          }

          return _AutoWaypoint(
            action: action,
            stepNumber: entry.key + 1,
            normalizedPosition: position,
            countsForMovement: _AutoPathCoordinates.countsForMovement(action),
          );
        })
        .whereType<_AutoWaypoint>()
        .toList();
  }

  List<_AutoWaypoint> get _movementWaypoints {
    return _allWaypoints
        .where((waypoint) => waypoint.countsForMovement)
        .toList();
  }

  List<_AutoReplayStep> get _replaySteps {
    final steps = <_AutoReplayStep>[];
    Offset? robotPosition;

    for (final waypoint in _allWaypoints) {
      if (waypoint.countsForMovement) {
        if (robotPosition == null) {
          robotPosition = waypoint.normalizedPosition;
          continue;
        }

        final difference = waypoint.normalizedPosition - robotPosition;
        final heading = difference.distanceSquared > 0.000001
            ? math.atan2(difference.dy, difference.dx)
            : 0.0;

        steps.add(
          _AutoReplayStep(
            type: _AutoReplayStepType.movement,
            robotStart: robotPosition,
            robotEnd: waypoint.normalizedPosition,
            target: null,
            heading: heading,
            durationMilliseconds: 1050,
          ),
        );

        robotPosition = waypoint.normalizedPosition;
        continue;
      }

      // A hub action is a shot, not a robot destination. The robot remains at
      // its latest movement waypoint while the game piece travels to the hub.
      if (robotPosition != null) {
        final difference = waypoint.normalizedPosition - robotPosition;
        final heading = difference.distanceSquared > 0.000001
            ? math.atan2(difference.dy, difference.dx)
            : 0.0;

        steps.add(
          _AutoReplayStep(
            type: _AutoReplayStepType.shot,
            robotStart: robotPosition,
            robotEnd: robotPosition,
            target: waypoint.normalizedPosition,
            heading: heading,
            durationMilliseconds: 700,
          ),
        );
      }
    }

    return steps;
  }

  bool get _hasReplayAnimation => _replaySteps.isNotEmpty;

  Duration get _animationDuration {
    final totalMilliseconds = _replaySteps.fold<int>(
      0,
      (total, step) => total + step.durationMilliseconds,
    );

    return Duration(
      milliseconds: math.max(1200, totalMilliseconds),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..addStatusListener((status) {
        if (!mounted) return;

        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          setState(() => _playing = false);
        }
      });
  }

  @override
  void didUpdateWidget(covariant _AutoPathReplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.path.join('\u0000') != widget.path.join('\u0000')) {
      _controller
        ..stop()
        ..reset()
        ..duration = _animationDuration;

      _playing = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_hasReplayAnimation) {
      return;
    }

    if (_controller.isAnimating) {
      _controller.stop();
      setState(() => _playing = false);
      return;
    }

    if (_controller.isCompleted) {
      _controller.reset();
    }

    _controller.forward();
    setState(() => _playing = true);
  }

  void _restart() {
    if (!_hasReplayAnimation) {
      return;
    }

    _controller.forward(from: 0);
    setState(() => _playing = true);
  }

  _AutoReplayFrame _frameAt(double progress) {
    final movementWaypoints = _movementWaypoints;
    final steps = _replaySteps;

    final initialPosition = movementWaypoints.isNotEmpty
        ? movementWaypoints.first.normalizedPosition
        : Offset.zero;

    if (steps.isEmpty) {
      return _AutoReplayFrame(
        robotPosition: initialPosition,
        robotHeading: 0,
        ballPosition: null,
        ballOpacity: 0,
        ballScale: 1,
      );
    }

    final totalMilliseconds = steps.fold<int>(
      0,
      (total, step) => total + step.durationMilliseconds,
    );

    final elapsedMilliseconds =
        progress.clamp(0.0, 1.0).toDouble() * totalMilliseconds;

    var consumedMilliseconds = 0.0;

    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      final stepEnd =
          consumedMilliseconds + step.durationMilliseconds.toDouble();
      final isLastStep = index == steps.length - 1;

      if (elapsedMilliseconds <= stepEnd || isLastStep) {
        final localProgress = ((elapsedMilliseconds - consumedMilliseconds) /
                step.durationMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble();

        if (step.type == _AutoReplayStepType.movement) {
          final easedProgress = Curves.easeInOut.transform(localProgress);

          return _AutoReplayFrame(
            robotPosition: Offset.lerp(
                  step.robotStart,
                  step.robotEnd,
                  easedProgress,
                ) ??
                step.robotEnd,
            robotHeading: step.heading,
            ballPosition: null,
            ballOpacity: 0,
            ballScale: 1,
          );
        }

        final target = step.target ?? step.robotStart;
        final shotProgress = Curves.easeOutCubic.transform(localProgress);
        final fadeProgress =
            ((localProgress - 0.82) / 0.18).clamp(0.0, 1.0).toDouble();

        return _AutoReplayFrame(
          robotPosition: step.robotStart,
          robotHeading: step.heading,
          ballPosition: Offset.lerp(
                step.robotStart,
                target,
                shotProgress,
              ) ??
              target,
          ballOpacity: 1 - fadeProgress,
          ballScale: 0.82 + math.sin(localProgress * math.pi) * 0.32,
        );
      }

      consumedMilliseconds = stepEnd;
    }

    final lastStep = steps.last;

    return _AutoReplayFrame(
      robotPosition: lastStep.robotEnd,
      robotHeading: lastStep.heading,
      ballPosition: null,
      ballOpacity: 0,
      ballScale: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final waypoints = _allWaypoints;
    final movementWaypoints = _movementWaypoints;
    final unknownActionCount = widget.path.length - waypoints.length;

    return _TeamGlassInset(
      padding: const EdgeInsets.all(13),
      tint: const Color(0xFF67A4FF),
      expand: true,
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF67A4FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Color(0xFF8AB8FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Autonomous Replay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.path.length} '
                      '${widget.path.length == 1 ? 'action' : 'actions'} recorded',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasReplayAnimation) ...[
                IconButton(
                  tooltip: 'Restart auto',
                  onPressed: _restart,
                  icon: const Icon(
                    Icons.replay_rounded,
                    color: Colors.white60,
                    size: 20,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(_playing ? 'Pause' : 'Play'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF397DDE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (widget.path.isEmpty)
            const _TeamGlassInset(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              expand: true,
              radius: 12,
              child: const Column(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: Colors.white30,
                    size: 28,
                  ),
                  SizedBox(height: 7),
                  Text(
                    'No autonomous path was recorded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (waypoints.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final displayWidth = math.min(
                    constraints.maxWidth,
                    430.0,
                  );

                  return Center(
                    child: SizedBox(
                      width: displayWidth,
                      child: AspectRatio(
                        // The source field is 1000 x 500. Rotating it 90 degrees
                        // makes the visible replay 500 x 1000 (portrait).
                        aspectRatio: 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF101216),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF67A4FF).withOpacity(0.34),
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.34),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: RotatedBox(
                              // Match the orientation used by the scouting form.
                              quarterTurns: 3,
                              child: LayoutBuilder(
                                builder: (context, fieldConstraints) {
                                  final fieldWidth = fieldConstraints.maxWidth;
                                  final fieldHeight =
                                      fieldConstraints.maxHeight;
                                  final robotSize = (fieldHeight * 0.16)
                                      .clamp(28.0, 44.0)
                                      .toDouble();

                                  final pixelPoints = waypoints.map((waypoint) {
                                    return Offset(
                                      waypoint.normalizedPosition.dx *
                                          fieldWidth,
                                      waypoint.normalizedPosition.dy *
                                          fieldHeight,
                                    );
                                  }).toList();

                                  final ballSize = (robotSize * 0.30)
                                      .clamp(9.0, 14.0)
                                      .toDouble();

                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      const ColoredBox(
                                        color: Color(0xFF090A0D),
                                      ),
                                      Image.asset(
                                        widget.fieldImagePath,
                                        // Never distort the field image. The
                                        // AspectRatio above supplies the matching
                                        // rotated dimensions.
                                        fit: BoxFit.contain,
                                        alignment: Alignment.center,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const ColoredBox(
                                            color: Color(0xFF0C1016),
                                            child: Center(
                                              child: Icon(
                                                Icons.stadium_outlined,
                                                color: Colors.white24,
                                                size: 42,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.04),
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.12),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: CustomPaint(
                                            painter: _AutoPathPainter(
                                              normalizedPoints:
                                                  movementWaypoints
                                                      .map(
                                                        (waypoint) => waypoint
                                                            .normalizedPosition,
                                                      )
                                                      .toList(),
                                              color: const Color(0xFF8AB8FF),
                                            ),
                                          ),
                                        ),
                                      ),
                                      ...List.generate(
                                        waypoints.length,
                                        (index) {
                                          final point = pixelPoints[index];
                                          final waypoint = waypoints[index];
                                          const markerSize = 24.0;
                                          final isMarkerOnly =
                                              !waypoint.countsForMovement;

                                          return Positioned(
                                            left: (point.dx - markerSize / 2)
                                                .clamp(
                                                  0.0,
                                                  fieldWidth - markerSize,
                                                )
                                                .toDouble(),
                                            top: (point.dy - markerSize / 2)
                                                .clamp(
                                                  0.0,
                                                  fieldHeight - markerSize,
                                                )
                                                .toDouble(),
                                            child: Tooltip(
                                              message: isMarkerOnly
                                                  ? '${waypoint.action} '
                                                      '(shoots game piece)'
                                                  : waypoint.action,
                                              child: Container(
                                                width: markerSize,
                                                height: markerSize,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: isMarkerOnly
                                                      ? const Color(0xFF47351A)
                                                      : const Color(0xFF18243A),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isMarkerOnly
                                                        ? const Color(
                                                            0xFFFFC878,
                                                          )
                                                        : const Color(
                                                            0xFFA8CAFF,
                                                          ),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                // Counter-rotate the number so it
                                                // stays upright after the field is
                                                // rotated counter-clockwise.
                                                child: RotatedBox(
                                                  quarterTurns: 1,
                                                  child: Text(
                                                    '${waypoint.stepNumber}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      if (movementWaypoints.isNotEmpty)
                                        Positioned.fill(
                                          child: AnimatedBuilder(
                                            animation: _controller,
                                            builder: (context, child) {
                                              final frame =
                                                  _frameAt(_controller.value);

                                              final robotPosition = Offset(
                                                frame.robotPosition.dx *
                                                    fieldWidth,
                                                frame.robotPosition.dy *
                                                    fieldHeight,
                                              );

                                              final ballPosition = frame
                                                          .ballPosition ==
                                                      null
                                                  ? null
                                                  : Offset(
                                                      frame.ballPosition!.dx *
                                                          fieldWidth,
                                                      frame.ballPosition!.dy *
                                                          fieldHeight,
                                                    );

                                              return Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  if (ballPosition != null &&
                                                      frame.ballOpacity > 0)
                                                    Positioned(
                                                      left: (ballPosition.dx -
                                                              ballSize / 2)
                                                          .clamp(
                                                            0.0,
                                                            fieldWidth -
                                                                ballSize,
                                                          )
                                                          .toDouble(),
                                                      top: (ballPosition.dy -
                                                              ballSize / 2)
                                                          .clamp(
                                                            0.0,
                                                            fieldHeight -
                                                                ballSize,
                                                          )
                                                          .toDouble(),
                                                      child: Opacity(
                                                        opacity:
                                                            frame.ballOpacity,
                                                        child: Transform.scale(
                                                          scale:
                                                              frame.ballScale,
                                                          child: Container(
                                                            width: ballSize,
                                                            height: ballSize,
                                                            decoration:
                                                                const BoxDecoration(
                                                              color: Color(
                                                                0xFFFFD83D,
                                                              ),
                                                              shape: BoxShape
                                                                  .circle,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Color(
                                                                    0xCCFFD83D,
                                                                  ),
                                                                  blurRadius:
                                                                      10,
                                                                  spreadRadius:
                                                                      2,
                                                                ),
                                                                BoxShadow(
                                                                  color: Color(
                                                                    0x88000000,
                                                                  ),
                                                                  blurRadius: 5,
                                                                  offset:
                                                                      Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  Positioned(
                                                    left: (robotPosition.dx -
                                                            robotSize / 2)
                                                        .clamp(
                                                          0.0,
                                                          fieldWidth -
                                                              robotSize,
                                                        )
                                                        .toDouble(),
                                                    top: (robotPosition.dy -
                                                            robotSize / 2)
                                                        .clamp(
                                                          0.0,
                                                          fieldHeight -
                                                              robotSize,
                                                        )
                                                        .toDouble(),
                                                    child: Transform.rotate(
                                                      angle: frame.robotHeading,
                                                      child: Container(
                                                        width: robotSize,
                                                        height: robotSize,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                            0xFF397DDE,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            8,
                                                          ),
                                                          border: Border.all(
                                                            color: Colors.white,
                                                            width: 2,
                                                          ),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                              color: Color(
                                                                0x88000000,
                                                              ),
                                                              blurRadius: 9,
                                                              offset: Offset(
                                                                0,
                                                                4,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.smart_toy,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (waypoints.isEmpty)
              const _TeamGlassInset(
                padding: const EdgeInsets.all(13),
                tint: Colors.orangeAccent,
                expand: true,
                radius: 12,
                child: const Text(
                  'The actions were saved, but none match a known field '
                  'coordinate. They are still listed below.',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            if (unknownActionCount > 0 && waypoints.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                '$unknownActionCount recorded '
                '${unknownActionCount == 1 ? 'action has' : 'actions have'} '
                'no mapped field coordinate and cannot be animated.',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...List.generate(widget.path.length, (index) {
              final action = widget.path[index];
              final hasCoordinate =
                  _AutoPathCoordinates.positionFor(action) != null;
              final isMarkerOnly =
                  _AutoPathCoordinates.isMarkerOnlyAction(action);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == widget.path.length - 1 ? 0 : 7,
                ),
                child: _TeamGlassInset(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  tint: hasCoordinate || isMarkerOnly
                      ? const Color(0xFF67A4FF)
                      : Colors.orangeAccent,
                  expand: true,
                  radius: 10,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF67A4FF).withOpacity(0.13),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFF9FC5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isMarkerOnly)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  'Shoots Game Piece',
                                  style: TextStyle(
                                    color: Color(0xFFFFD27A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        isMarkerOnly
                            ? Icons.adjust_rounded
                            : hasCoordinate
                                ? Icons.location_on_outlined
                                : Icons.location_off_outlined,
                        color: isMarkerOnly
                            ? const Color(0xFFFFD27A)
                            : hasCoordinate
                                ? const Color(0xFF8AB8FF)
                                : Colors.orangeAccent,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _AutoPathPainter extends CustomPainter {
  final List<Offset> normalizedPoints;
  final Color color;

  const _AutoPathPainter({
    required this.normalizedPoints,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedPoints.isEmpty) {
      return;
    }

    final points = normalizedPoints.map((point) {
      return Offset(
        point.dx * size.width,
        point.dy * size.height,
      );
    }).toList();

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pathPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < points.length - 1; index++) {
      canvas.drawLine(points[index], points[index + 1], shadowPaint);
      canvas.drawLine(points[index], points[index + 1], pathPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AutoPathPainter oldDelegate) {
    return oldDelegate.normalizedPoints != normalizedPoints ||
        oldDelegate.color != color;
  }
}

enum _AutoReplayStepType {
  movement,
  shot,
}

class _AutoReplayStep {
  final _AutoReplayStepType type;
  final Offset robotStart;
  final Offset robotEnd;
  final Offset? target;
  final double heading;
  final int durationMilliseconds;

  const _AutoReplayStep({
    required this.type,
    required this.robotStart,
    required this.robotEnd,
    required this.target,
    required this.heading,
    required this.durationMilliseconds,
  });
}

class _AutoReplayFrame {
  final Offset robotPosition;
  final double robotHeading;
  final Offset? ballPosition;
  final double ballOpacity;
  final double ballScale;

  const _AutoReplayFrame({
    required this.robotPosition,
    required this.robotHeading,
    required this.ballPosition,
    required this.ballOpacity,
    required this.ballScale,
  });
}

class _AutoWaypoint {
  final String action;
  final int stepNumber;
  final Offset normalizedPosition;
  final bool countsForMovement;

  const _AutoWaypoint({
    required this.action,
    required this.stepNumber,
    required this.normalizedPosition,
    required this.countsForMovement,
  });
}

class _AutoPathCoordinates {
  static final Set<String> _markerOnlyActions = {
    'shot at hub',
    'hub',
  };

  static final Map<String, Offset> _positions = {
    'intaked at depot': const Offset(0.260, 0.260),
    'depot': const Offset(0.260, 0.260),
    'went under left trench': const Offset(0.500, 0.080),
    'left trench': const Offset(0.500, 0.080),
    'went over left bump': const Offset(0.500, 0.300),
    'left bump': const Offset(0.500, 0.300),
    'went over right bump': const Offset(0.500, 0.700),
    'right bump': const Offset(0.500, 0.700),
    'went under right trench': const Offset(0.500, 0.980),
    'right trench': const Offset(0.500, 0.980),
    'shot at hub': const Offset(0.530, 0.500),
    'hub': const Offset(0.530, 0.500),
    'intaked at neutral zone': const Offset(0.730, 0.500),
    'neutral zone': const Offset(0.730, 0.500),
  };

  static Offset? positionFor(String action) {
    return _positions[_normalize(action)];
  }

  static bool isMarkerOnlyAction(String action) {
    return _markerOnlyActions.contains(_normalize(action));
  }

  static bool countsForMovement(String action) {
    return !isMarkerOnlyAction(action);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
