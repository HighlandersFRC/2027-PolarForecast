import 'dart:ui' show FontFeature;

import 'package:app/models/team_stat.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// The same heatmapped table is used at every screen size.
class EventStatsGrid extends StatefulWidget {
  static const backgroundColor = Color(0xFF111821);
  static const surfaceColor = Color(0xFF18212B);
  static const headerColor = Color(0xFF222D39);
  static const borderColor = Color(0xFF35424F);

  final List<TeamStat> teams;
  final List<TeamStat> eventTeams;
  final bool showScoutingAnalysis;
  final String sortKey;
  final bool ascending;
  final ValueChanged<String> onSort;
  final ValueChanged<TeamStat> onTeamTap;

  const EventStatsGrid({
    super.key,
    required this.teams,
    required this.eventTeams,
    required this.showScoutingAnalysis,
    required this.sortKey,
    required this.ascending,
    required this.onSort,
    required this.onTeamTap,
  });

  @override
  State<EventStatsGrid> createState() => _EventStatsGridState();
}

class _EventStatsGridState extends State<EventStatsGrid> {
  final _source = _EventStatsSource();

  List<_Metric> get _metrics => [
        ..._coreMetrics,
        if (widget.showScoutingAnalysis) ..._scoutingMetrics,
      ];

  @override
  void initState() {
    super.initState();
    _updateSource();
  }

  @override
  void didUpdateWidget(covariant EventStatsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSource();
  }

  void _updateSource() {
    _source.update(widget.teams, widget.eventTeams, _metrics);
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      final metrics = _metrics;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: EventStatsGrid.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EventStatsGrid.borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Expanded(
                child: SfDataGridTheme(
                  data: const SfDataGridThemeData(
                    headerColor: EventStatsGrid.headerColor,
                    headerHoverColor: Color(0xFF2B3947),
                    gridLineColor: EventStatsGrid.borderColor,
                    gridLineStrokeWidth: 0.5,
                    frozenPaneElevation: 0,
                    frozenPaneLineColor: EventStatsGrid.borderColor,
                    frozenPaneLineWidth: 1,
                  ),
                  child: SfDataGrid(
                    source: _source,
                    frozenColumnsCount: 1,
                    rowHeight: compact ? 48 : 52,
                    headerRowHeight: compact ? 42 : 46,
                    columnWidthMode: ColumnWidthMode.fill,
                    gridLinesVisibility: GridLinesVisibility.both,
                    headerGridLinesVisibility: GridLinesVisibility.both,
                    highlightRowOnHover: false,
                    isScrollbarAlwaysShown: !compact,
                    columns: [
                      for (final metric in metrics)
                        GridColumn(
                          columnName: metric.key,
                          width: compact
                              ? metric.mobileWidth
                              : metric.key == 'team'
                                  ? 96
                                  : double.nan,
                          minimumWidth: compact ? metric.mobileWidth : 88,
                          label: Semantics(
                            button: true,
                            label: 'Sort by ${metric.label}',
                            onTap: () => widget.onSort(metric.key),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              alignment: metric.key == 'team'
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Row(
                                mainAxisAlignment: metric.key == 'team'
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(metric.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Color(0xFFBCC7D1),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  if (widget.sortKey == metric.key) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                        widget.ascending
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        color: const Color(0xFFBCC7D1),
                                        size: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                    // Keep the table, toolbar, and CSV in the same sort order.
                    onCellTap: (details) {
                      final index = details.rowColumnIndex;
                      if (index.columnIndex < 0 ||
                          index.columnIndex >= metrics.length) return;
                      if (index.rowIndex == 0) {
                        widget.onSort(metrics[index.columnIndex].key);
                      } else if (index.rowIndex > 0 &&
                          index.rowIndex <= widget.teams.length) {
                        widget.onTeamTap(widget.teams[index.rowIndex - 1]);
                      }
                    },
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: EventStatsGrid.surfaceColor,
                  border: Border(
                      top: BorderSide(color: EventStatsGrid.borderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${widget.teams.length} of ${widget.eventTeams.length} teams',
                          style: const TextStyle(
                              color: Color(0xFFADB9C5), fontSize: 11)),
                    ),
                    Tooltip(
                      message: 'Colors compare all teams at this event. '
                          'Green means higher values, except rank and death rate '
                          'where lower values are greener. Missing data stays neutral.',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final color in [_low, _middle, _high])
                            Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 3),
                                color: color),
                          const SizedBox(width: 4),
                          Text(compact ? 'Swipe for more' : 'Heatmap',
                              style: const TextStyle(
                                  color: Color(0xFFADB9C5), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

const _low = Color(0xFF633E43);
const _middle = Color(0xFF5F5943);
const _high = Color(0xFF315A4A);

const _coreMetrics = [
  _Metric('team', 'Team', 84),
  _Metric('rank', 'Rank', 64, reversed: true),
  _Metric('rp', 'RP', 64),
  _Metric('opr', 'OPR', 76),
  _Metric('auto', 'Auto', 72),
  _Metric('teleop', 'Teleop', 80),
  _Metric('tower', 'Tower', 76),
];
const _scoutingMetrics = [
  _Metric('death', 'Death %', 92, reversed: true, percent: true),
  _Metric('defense', 'Defense %', 100, percent: true),
  _Metric('scouted', 'Scouted', 92),
];

class _Metric {
  final String key;
  final String label;
  final double mobileWidth;
  final bool reversed;
  final bool percent;

  const _Metric(this.key, this.label, this.mobileWidth,
      {this.reversed = false, this.percent = false});

  num? value(TeamStat team) => switch (key) {
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
}

class _EventStatsSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  List<_Metric> _metrics = [];
  final Map<String, (double, double)> _ranges = {};

  @override
  List<DataGridRow> get rows => _rows;

  void update(
      List<TeamStat> teams, List<TeamStat> eventTeams, List<_Metric> metrics) {
    _metrics = metrics;
    _ranges.clear();
    for (final metric in metrics.where((metric) => metric.key != 'team')) {
      final values = eventTeams
          .map(metric.value)
          .whereType<num>()
          .where((value) => value.isFinite);
      if (values.isEmpty) continue;
      var minimum = double.infinity;
      var maximum = double.negativeInfinity;
      for (final value in values) {
        if (value < minimum) minimum = value.toDouble();
        if (value > maximum) maximum = value.toDouble();
      }
      _ranges[metric.key] = (minimum, maximum);
    }
    _rows = [
      for (final team in teams)
        DataGridRow(cells: [
          for (final metric in metrics)
            DataGridCell<num?>(
                columnName: metric.key, value: metric.value(team)),
        ]),
    ];
    notifyListeners();
  }

  Color _color(_Metric metric, num? value) {
    if (metric.key == 'team') return EventStatsGrid.headerColor;
    if (value == null || !value.isFinite) return EventStatsGrid.surfaceColor;
    final range = _ranges[metric.key];
    if (range == null || range.$1 == range.$2) return const Color(0xFF3D464C);
    var position = ((value - range.$1) / (range.$2 - range.$1)).clamp(0.0, 1.0);
    if (metric.reversed) position = 1 - position;
    return position <= 0.5
        ? Color.lerp(_low, _middle, position * 2)!
        : Color.lerp(_middle, _high, (position - 0.5) * 2)!;
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final team = row.getCells().first.value;
    return DataGridRowAdapter(cells: [
      for (var i = 0; i < _metrics.length; i++)
        _cell(_metrics[i], row.getCells()[i].value as num?, team),
    ]);
  }

  Widget _cell(_Metric metric, num? value, Object? team) {
    final label = value == null || !value.isFinite
        ? '\u2014'
        : metric.percent
            ? '${(value * 100).toStringAsFixed(0)}%'
            : metric.key == 'team' ||
                    metric.key == 'rank' ||
                    metric.key == 'rp' ||
                    metric.key == 'scouted'
                ? value.toInt().toString()
                : value.toStringAsFixed(1);
    return Semantics(
      label: 'Team $team, ${metric.label}: $label',
      child: Container(
        key: ValueKey('stats-cell-$team-${metric.key}'),
        alignment:
            metric.key == 'team' ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: _color(metric, value),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: metric.key == 'team'
                    ? const Color(0xFFBAD0E3)
                    : const Color(0xFFF2F3F4),
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: metric.key == 'team' || metric.key == 'opr'
                    ? FontWeight.w700
                    : FontWeight.w500)),
      ),
    );
  }
}
