import 'dart:ui';

import 'package:app/APIService.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';

class PitScouting extends StatefulWidget {
  final String event;
  final String groupId;
  final String username;

  const PitScouting({
    super.key,
    required this.event,
    required this.groupId,
    required this.username,
  });

  @override
  State<PitScouting> createState() => _PitScoutingState();
}

class _TableHeading extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TableHeading({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.white54,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PitScoutingState extends State<PitScouting> {
  final APIService _api = APIService();
  final TextEditingController _searchController = TextEditingController();

  late Future<_PitScoutingPageData> _pageFuture;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_PitScoutingPageData> _loadData() async {
    final results = await Future.wait([
      _api.fetchTeamsPerEvent(widget.event),
      _api.getGroupPitStatus(
        groupId: widget.groupId,
        event: widget.event,
        username: widget.username,
      ),
    ]);

    final rawTeams = results[0] as List<dynamic>;
    final rawStatus = results[1] as Map<String, dynamic>;

    final Map<int, bool> pitScoutingByTeam = {};
    final Map<int, bool> followUpsByTeam = {};
    final Map<int, int> pendingFollowUpsByTeam = {};

    final statusData = rawStatus['data'];

    if (statusData is List) {
      for (final rawEntry in statusData) {
        if (rawEntry is! Map) continue;

        final teamNumber = _parseTeamNumber(rawEntry['team']);

        if (teamNumber == null) continue;

        pitScoutingByTeam[teamNumber] = rawEntry['pitscouting'] == true;

        // Missing values from older backend documents are treated as true.
        followUpsByTeam[teamNumber] = rawEntry['followups'] != false;

        pendingFollowUpsByTeam[teamNumber] =
            _parseInteger(rawEntry['pending_followup_count']) ?? 0;
      }
    }

    final Map<int, String> eventTeams = {};

    for (final rawTeam in rawTeams) {
      final teamNumber = _parseTeamNumber(rawTeam);

      if (teamNumber != null) {
        eventTeams[teamNumber] = rawTeam.toString();
      }
    }

    // Preserve teams present in the status response even when the event-team
    // cache is temporarily missing them.
    if (statusData is List) {
      for (final rawEntry in statusData) {
        if (rawEntry is! Map) continue;

        final teamNumber = _parseTeamNumber(rawEntry['team']);

        if (teamNumber != null) {
          eventTeams.putIfAbsent(
            teamNumber,
            () => 'frc$teamNumber',
          );
        }
      }
    }

    final teams = eventTeams.entries.map((entry) {
      final teamNumber = entry.key;

      return _PitTeamStatus(
        teamKey: entry.value,
        teamNumber: teamNumber,
        pitScoutingComplete: pitScoutingByTeam[teamNumber] ?? false,
        followUpsComplete: followUpsByTeam[teamNumber] ?? true,
        pendingFollowUpCount: pendingFollowUpsByTeam[teamNumber] ?? 0,
      );
    }).toList()
      ..sort(
        (a, b) => a.teamNumber.compareTo(b.teamNumber),
      );

    final completedPitCount =
        teams.where((team) => team.pitScoutingComplete).length;

    final completedFollowUpCount =
        teams.where((team) => team.followUpsComplete).length;

    final needsFollowUpCount =
        teams.where((team) => !team.followUpsComplete).length;

    return _PitScoutingPageData(
      teams: teams,
      completedPitCount:
          _parseInteger(rawStatus['completed_count']) ?? completedPitCount,
      completedFollowUpCount: completedFollowUpCount,
      needsFollowUpCount: needsFollowUpCount,
      totalCount: _parseInteger(rawStatus['total_count']) ?? teams.length,
    );
  }

  static int? _parseTeamNumber(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final normalized =
        value.toString().trim().toLowerCase().replaceFirst('frc', '');

    return int.tryParse(normalized);
  }

  static int? _parseInteger(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  List<_PitTeamStatus> _filterTeams(
    List<_PitTeamStatus> teams,
  ) {
    final rawQuery = _searchQuery.trim();

    if (rawQuery.isEmpty) {
      return teams;
    }

    final numericQuery = rawQuery.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (numericQuery.isEmpty) {
      return const [];
    }

    return teams.where((team) {
      return team.teamNumber.toString().contains(numericQuery);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> _refresh() async {
    final newFuture = _loadData();

    setState(() {
      _pageFuture = newFuture;
    });

    await newFuture;
  }

  Future<void> _openPitScouting(
    _PitTeamStatus team,
  ) async {
    await Navigator.pushNamed(
      context,
      '/event/${widget.event}/team/'
      '${team.teamNumber}/pitscouting',
    );

    if (!mounted) return;

    await _refresh();
  }

  Future<void> _openFollowUp(
    _PitTeamStatus team,
  ) async {
    await Navigator.pushNamed(
      context,
      '/event/${widget.event}/team/'
      '${team.teamNumber}/followup',
    );

    if (!mounted) return;

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<_PitScoutingPageData>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white70,
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error,
              onRetry: _refresh,
            );
          }

          final pageData = snapshot.data;

          if (pageData == null || pageData.teams.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Center(
                    child: Text(
                      'No teams found',
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final filteredTeams = _filterTeams(
            pageData.teams,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.white,
            backgroundColor: const Color(0xFF242428),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                24,
              ),
              children: [
                _buildSummaryCard(pageData),
                const SizedBox(height: 12),
                _buildSearchCard(
                  visibleCount: filteredTeams.length,
                  totalCount: pageData.teams.length,
                ),
                const SizedBox(height: 12),
                if (filteredTeams.isEmpty)
                  _buildNoSearchResults()
                else
                  _buildTeamTable(filteredTeams),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    _PitScoutingPageData pageData,
  ) {
    final total = pageData.totalCount;

    final pitProgress = total == 0 ? 0.0 : pageData.completedPitCount / total;

    final pitComplete = total > 0 && pageData.completedPitCount >= total;

    final hasPendingFollowUps = pageData.needsFollowUpCount > 0;

    return LiquidGlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      tint: LiquidGlassColors.primary,
      blurSigma: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: Color(0xFF93C5FD),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Team Scouting Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumns = constraints.maxWidth >= 520;

              final cardWidth = useTwoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildSummaryItem(
                      icon: pitComplete
                          ? Icons.task_alt_rounded
                          : Icons.pending_actions_rounded,
                      title: 'Pit Scouting',
                      value: '${pageData.completedPitCount} / $total',
                      subtitle: pitComplete
                          ? 'All pit scouting completed'
                          : '${total - pageData.completedPitCount} remaining',
                      color: pitComplete
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFACC15),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildSummaryItem(
                      icon: hasPendingFollowUps
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      title: 'Follow-Ups',
                      value: hasPendingFollowUps
                          ? '${pageData.needsFollowUpCount} needed'
                          : 'Complete',
                      subtitle: hasPendingFollowUps
                          ? 'Robots need follow-up'
                          : 'No pending follow-ups',
                      color: hasPendingFollowUps
                          ? const Color(0xFFF87171)
                          : const Color(0xFF4ADE80),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Pit scouting progress',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(pitProgress * 100).round()}%',
                style: TextStyle(
                  color: pitComplete
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFFACC15),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: pitProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                pitComplete ? const Color(0xFF4ADE80) : const Color(0xFFFACC15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            Colors.white.withOpacity(0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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

  Widget _buildSearchCard({
    required int visibleCount,
    required int totalCount,
  }) {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return LiquidGlassPanel(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(20),
      tint: LiquidGlassColors.aqua,
      blurSigma: 16,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: Colors.white70,
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
                color: Colors.white54,
              ),
              suffixIcon: isSearching
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.065),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: LiquidGlassColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: LiquidGlassColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF60A5FA),
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.groups_2_outlined,
                size: 16,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                isSearching
                    ? 'Showing $visibleCount of $totalCount teams'
                    : '$totalCount teams',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTable(
    List<_PitTeamStatus> teams,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.145),
                    LiquidGlassColors.primary.withOpacity(0.055),
                    Colors.white.withOpacity(0.035),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: LiquidGlassColors.border,
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Fill the entire card on larger screens, but allow
                    // horizontal scrolling on smaller screens.
                    minWidth: constraints.maxWidth,
                  ),
                  child: DataTable(
                    headingRowHeight: 56,
                    dataRowMinHeight: 68,
                    dataRowMaxHeight: 78,
                    horizontalMargin: 20,
                    columnSpacing: 30,
                    dividerThickness: 1,
                    showCheckboxColumn: false,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    headingRowColor: MaterialStateProperty.all(
                      Colors.white.withOpacity(0.075),
                    ),
                    dataRowColor: MaterialStateProperty.resolveWith(
                      (states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Colors.white.withOpacity(0.075);
                        }

                        if (states.contains(MaterialState.pressed)) {
                          return Colors.white.withOpacity(0.10);
                        }

                        return Colors.transparent;
                      },
                    ),
                    columns: const [
                      DataColumn(
                        label: _TableHeading(
                          icon: Icons.tag_rounded,
                          text: 'Team',
                        ),
                      ),
                      DataColumn(
                        label: _TableHeading(
                          icon: Icons.assignment_outlined,
                          text: 'Pit Scouting',
                        ),
                      ),
                      DataColumn(
                        label: _TableHeading(
                          icon: Icons.build_circle_outlined,
                          text: 'Follow-Up',
                        ),
                      ),
                      DataColumn(
                        label: _TableHeading(
                          icon: Icons.touch_app_outlined,
                          text: 'Actions',
                        ),
                      ),
                    ],
                    rows: teams.map((team) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF60A5FA)
                                        .withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF60A5FA)
                                          .withOpacity(0.22),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.precision_manufacturing_outlined,
                                    color: Color(0xFF93C5FD),
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Text(
                                  '${team.teamNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            _buildStatusBadge(
                              complete: team.pitScoutingComplete,
                              completeText: 'Complete',
                              incompleteText: 'Incomplete',
                              completeIcon: Icons.check_circle_outline_rounded,
                              incompleteIcon: Icons.error_outline_rounded,
                            ),
                            onTap: () => _openPitScouting(team),
                          ),
                          DataCell(
                            _buildFollowUpBadge(team),
                            onTap: () => _openFollowUp(team),
                          ),
                          DataCell(
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildGlassActionButton(
                                  icon: Icons.assignment_outlined,
                                  label: 'Pit Scout',
                                  color: const Color(0xFF93C5FD),
                                  onPressed: () => _openPitScouting(team),
                                ),
                                _buildGlassActionButton(
                                  icon: team.followUpsComplete
                                      ? Icons.visibility_outlined
                                      : Icons.notification_important_outlined,
                                  label: team.followUpsComplete
                                      ? 'View'
                                      : 'Follow Up',
                                  color: team.followUpsComplete
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFF87171),
                                  onPressed: () => _openFollowUp(team),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 17,
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withOpacity(0.11),
        side: BorderSide(
          color: color.withOpacity(0.40),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool complete,
    required String completeText,
    required String incompleteText,
    required IconData completeIcon,
    required IconData incompleteIcon,
  }) {
    final color = complete ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? completeIcon : incompleteIcon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            complete ? completeText : incompleteText,
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

  Widget _buildFollowUpBadge(
    _PitTeamStatus team,
  ) {
    final complete = team.followUpsComplete;

    final color = complete ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    final String text;

    if (complete) {
      text = 'Complete';
    } else if (team.pendingFollowUpCount > 1) {
      text = 'Needs Follow-Up (${team.pendingFollowUpCount})';
    } else {
      text = 'Needs Follow-Up';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
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

  Widget _buildNoSearchResults() {
    return LiquidGlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
      borderRadius: BorderRadius.circular(20),
      tint: LiquidGlassColors.secondary,
      blurSigma: 14,
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Colors.white38,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'No matching teams',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No team matches “${_searchQuery.trim()}”.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _clearSearch,
            icon: const Icon(
              Icons.close_rounded,
            ),
            label: const Text(
              'Clear search',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(
                color: Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitScoutingPageData {
  final List<_PitTeamStatus> teams;
  final int completedPitCount;
  final int completedFollowUpCount;
  final int needsFollowUpCount;
  final int totalCount;

  const _PitScoutingPageData({
    required this.teams,
    required this.completedPitCount,
    required this.completedFollowUpCount,
    required this.needsFollowUpCount,
    required this.totalCount,
  });
}

class _PitTeamStatus {
  final String teamKey;
  final int teamNumber;
  final bool pitScoutingComplete;
  final bool followUpsComplete;
  final int pendingFollowUpCount;

  const _PitTeamStatus({
    required this.teamKey,
    required this.teamNumber,
    required this.pitScoutingComplete,
    required this.followUpsComplete,
    required this.pendingFollowUpCount,
  });
}

class _ErrorState extends StatelessWidget {
  final Object? error;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFF87171),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Error loading scouting status',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error?.toString() ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
