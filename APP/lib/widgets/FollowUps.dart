import 'package:app/APIService.dart';
import 'package:app/models/follow_up.dart';
import 'package:app/models/scout_info.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FollowUpPage extends StatefulWidget {
  final String eventCode;
  final int teamNumber;

  const FollowUpPage({
    super.key,
    required this.eventCode,
    required this.teamNumber,
  });

  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> {
  final APIService _api = APIService();

  late Future<List<FollowUpIncident>> _incidentsFuture;

  @override
  void initState() {
    super.initState();
    _incidentsFuture = _loadIncidents();
  }

  Future<List<FollowUpIncident>> _loadIncidents() {
    final auth = context.read<AuthService>();

    return _api.fetchFollowUpIncidents(
      groupId: auth.groupId ?? '',
      username: auth.username ?? '',
      team: widget.teamNumber,
      event: widget.eventCode,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _incidentsFuture = _loadIncidents();
    });

    await _incidentsFuture;
  }

  Future<void> _submitIncident({
    required FollowUpIncident incident,
    required String severity,
    required String comments,
  }) async {
    final auth = context.read<AuthService>();

    final followUp = FollowUp(
      event: widget.eventCode,
      match: incident.match,
      team: widget.teamNumber,
      groupId: auth.groupId ?? '',
      scoutInfo: ScoutInfo(
        userId: auth.username ?? '',
        firstName: auth.firstName ?? '',
        username: auth.username ?? '',
        team: auth.team.toString(),
      ),
      data: FollowUpData(
        severity: severity,
        comments: comments,
      ),
    );

    await _api.submitFollowUps(followUp);
    await _refresh();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            '${_displayMatch(incident.match)} follow-up submitted.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PolarForecastAppBar(
        extraText: "${widget.teamNumber} Follow Up",
      ),
      body: FutureBuilder<List<FollowUpIncident>>(
        future: _incidentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error,
              onRetry: _refresh,
            );
          }

          final incidents = snapshot.data ?? const <FollowUpIncident>[];
          final pendingCount =
              incidents.where((incident) => !incident.resolved).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.white,
            backgroundColor: const Color(0xFF242428),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _buildHeader(
                  incidentCount: incidents.length,
                  pendingCount: pendingCount,
                ),
                const SizedBox(height: 14),
                if (incidents.isEmpty)
                  _buildEmptyState()
                else ...[
                  ...incidents.where((incident) => !incident.resolved).map(
                        (incident) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FollowUpIncidentCard(
                            key: ValueKey(incident.incidentId),
                            incident: incident,
                            onSubmit: ({
                              required severity,
                              required comments,
                            }) {
                              return _submitIncident(
                                incident: incident,
                                severity: severity,
                                comments: comments,
                              );
                            },
                          ),
                        ),
                      ),
                  ...incidents.where((incident) => incident.resolved).map(
                        (incident) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FollowUpIncidentCard(
                            key: ValueKey(incident.incidentId),
                            incident: incident,
                            onSubmit: ({
                              required severity,
                              required comments,
                            }) {
                              return _submitIncident(
                                incident: incident,
                                severity: severity,
                                comments: comments,
                              );
                            },
                          ),
                        ),
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required int incidentCount,
    required int pendingCount,
  }) {
    final complete = incidentCount > 0 && pendingCount == 0;
    final color = complete
        ? const Color(0xFF4ADE80)
        : pendingCount > 0
            ? const Color(0xFFF87171)
            : const Color(0xFF60A5FA);

    return LiquidGlassPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(22),
      tint: color,
      blurSigma: 16,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              complete ? Icons.task_alt_rounded : Icons.build_circle_outlined,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team ${widget.teamNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$incidentCount death ${incidentCount == 1 ? 'incident' : 'incidents'} • '
                  '$pendingCount pending',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.eventCode.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
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

  Widget _buildEmptyState() {
    return LiquidGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
      borderRadius: BorderRadius.circular(22),
      tint: LiquidGlassColors.aqua,
      blurSigma: 16,
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 44,
            color: Color(0xFF4ADE80),
          ),
          SizedBox(height: 12),
          Text(
            'No robot deaths reported',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Match scouting has not reported this robot dying at this event.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FollowUpIncidentCard extends StatefulWidget {
  final FollowUpIncident incident;
  final Future<void> Function({
    required String severity,
    required String comments,
  }) onSubmit;

  const _FollowUpIncidentCard({
    super.key,
    required this.incident,
    required this.onSubmit,
  });

  @override
  State<_FollowUpIncidentCard> createState() => _FollowUpIncidentCardState();
}

class _FollowUpIncidentCardState extends State<_FollowUpIncidentCard> {
  final TextEditingController _commentsController = TextEditingController();

  String _severity = 'Medium';
  bool _submitting = false;

  static const List<String> _severities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comments = _commentsController.text.trim();

    if (comments.length < 10) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Add more detail about what was found or repaired.'),
          ),
        );
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.onSubmit(
        severity: _severity,
        comments: comments,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB3261E),
            content: Text(_cleanError(error)),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final statusColor =
        incident.resolved ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    return LiquidGlassPanel(
      borderRadius: BorderRadius.circular(22),
      tint: statusColor,
      blurSigma: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.14),
                  Colors.white.withOpacity(0.045),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(
                  color: statusColor.withOpacity(0.22),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sports_score_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayMatch(incident.match),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${incident.reportCount} death ${incident.reportCount == 1 ? 'report' : 'reports'}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
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
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    incident.resolved ? 'Resolved' : 'Needs follow-up',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'How the robot died',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                ...incident.deathReports.asMap().entries.map((entry) {
                  final index = entry.key;
                  final report = entry.value;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == incident.deathReports.length - 1 ? 0 : 8,
                    ),
                    child: _DeathReportView(report: report),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 16),
                if (incident.resolved)
                  _ResolvedFollowUpView(
                    resolution: incident.followup,
                  )
                else ...[
                  const Text(
                    'Follow-up severity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _severities.map((severity) {
                      final selected = severity == _severity;
                      final color = _severityColor(severity);

                      return ChoiceChip(
                        selected: selected,
                        onSelected: _submitting
                            ? null
                            : (_) {
                                setState(() => _severity = severity);
                              },
                        label: Text(severity),
                        labelStyle: TextStyle(
                          color: selected ? color : Colors.white60,
                          fontWeight: FontWeight.w700,
                        ),
                        selectedColor: color.withOpacity(0.15),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        side: BorderSide(
                          color: selected
                              ? color.withOpacity(0.65)
                              : Colors.white10,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _commentsController,
                    enabled: !_submitting,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Explain what caused the failure, what was repaired, '
                          'and whether the robot is ready to play.',
                      hintStyle: const TextStyle(
                        color: Colors.white30,
                        height: 1.4,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.065),
                      counterStyle: const TextStyle(color: Colors.white38),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF60A5FA),
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.task_alt_rounded),
                      label: Text(
                        _submitting
                            ? 'Submitting...'
                            : 'Resolve ${_displayMatch(incident.match)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            LiquidGlassColors.primary.withValues(alpha: 0.80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: LiquidGlassColors.border,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeathReportView extends StatelessWidget {
  final DeathReport report;

  const _DeathReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    final comments = report.comments.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.075),
            Colors.white.withOpacity(0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  report.scoutName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comments.isEmpty
                ? 'The scout marked the robot as dead but did not add comments.'
                : comments,
            style: TextStyle(
              color: comments.isEmpty ? Colors.white38 : Colors.white70,
              fontSize: 13,
              height: 1.4,
              fontStyle: comments.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedFollowUpView extends StatelessWidget {
  final FollowUpResolution? resolution;

  const _ResolvedFollowUpView({required this.resolution});

  @override
  Widget build(BuildContext context) {
    final data = resolution;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4ADE80).withOpacity(0.13),
            Colors.white.withOpacity(0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF4ADE80),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Follow-up completed',
                  style: TextStyle(
                    color: Color(0xFF4ADE80),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if ((data?.severity ?? '').isNotEmpty)
                Text(
                  data!.severity,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (data?.comments.trim().isNotEmpty ?? false)
                ? data!.comments
                : 'No resolution notes were provided.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          if ((data?.scoutName ?? '').isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              'Resolved by ${data!.scoutName}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
        child: LiquidGlassPanel(
          padding: const EdgeInsets.all(24),
          tint: const Color(0xFFF87171),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFF87171),
                size: 44,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load follow-ups',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _cleanError(error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _displayMatch(String rawMatch) {
  final raw = rawMatch.trim();
  final lower = raw.toLowerCase();

  final qualification = RegExp(r'(?:^|_)qm(\d+)$').firstMatch(lower);
  if (qualification != null) {
    return 'Qualification ${qualification.group(1)}';
  }

  if (RegExp(r'^\d+$').hasMatch(lower)) {
    return 'Match $raw';
  }

  final semifinal = RegExp(r'(?:^|_)sf(\d+)(?:m(\d+))?$').firstMatch(lower);
  if (semifinal != null) {
    final setNumber = semifinal.group(1);
    final matchNumber = semifinal.group(2);
    return matchNumber == null
        ? 'Semifinal $setNumber'
        : 'Semifinal $setNumber Match $matchNumber';
  }

  final finalMatch = RegExp(r'(?:^|_)f(\d+)$').firstMatch(lower);
  if (finalMatch != null) {
    return 'Final ${finalMatch.group(1)}';
  }

  return 'Match $raw';
}

Color _severityColor(String severity) {
  switch (severity) {
    case 'Low':
      return const Color(0xFF4ADE80);
    case 'Medium':
      return const Color(0xFFFACC15);
    case 'High':
      return const Color(0xFFFB923C);
    case 'Critical':
      return const Color(0xFFF87171);
    default:
      return Colors.white70;
  }
}

String _cleanError(Object? error) {
  final text = error?.toString() ?? 'Unknown error';
  return text.startsWith('Exception: ')
      ? text.substring('Exception: '.length)
      : text;
}
