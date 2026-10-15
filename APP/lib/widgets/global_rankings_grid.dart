import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:app/models/global_ranking.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class GlobalRankingsGrid extends StatefulWidget {
  final List<GlobalRanking> teams;
  final Map<String, RankingMetricRange> ranges;
  final Future<Map<String, dynamic>> Function(int) identity;
  final ValueChanged<GlobalRanking> onTeamTap;
  final Future<void> Function()? onRefresh;
  final Widget? footer;

  const GlobalRankingsGrid(
      {super.key,
      required this.teams,
      required this.ranges,
      required this.identity,
      required this.onTeamTap,
      this.onRefresh,
      this.footer});

  @override
  State<GlobalRankingsGrid> createState() => _GlobalRankingsGridState();
}

class _GlobalRankingsGridState extends State<GlobalRankingsGrid> {
  final _source = _RankingSource();

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(covariant GlobalRankingsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    _source.onRefresh = widget.onRefresh;
    _source.update(widget.teams, widget.ranges, widget.identity);
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final rankWidth = compact ? 44.0 : 60.0;
        final teamWidth = compact
            ? math.max(168.0, constraints.maxWidth * 0.36)
            : math.max(230.0, (constraints.maxWidth - rankWidth) * 0.4);
        final metricWidth = compact
            ? math.max(88.0, (constraints.maxWidth - rankWidth - teamWidth) / 3)
            : double.nan;
        return SfDataGridTheme(
          data: const SfDataGridThemeData(
            headerColor: AppColors.surfaceRaised,
            gridLineColor: AppColors.border,
            gridLineStrokeWidth: 0.5,
            frozenPaneElevation: 0,
            frozenPaneLineColor: AppColors.border,
            frozenPaneLineWidth: 1,
          ),
          child: SfDataGrid(
            source: _source,
            frozenColumnsCount: 2,
            columnWidthMode: ColumnWidthMode.fill,
            rowHeight: compact ? 76 : 70,
            headerRowHeight: 40,
            gridLinesVisibility: GridLinesVisibility.both,
            headerGridLinesVisibility: GridLinesVisibility.both,
            highlightRowOnHover: false,
            isScrollbarAlwaysShown: !compact,
            allowPullToRefresh: widget.onRefresh != null,
            footer: widget.footer,
            footerHeight: 64,
            columns: [
              GridColumn(
                  columnName: 'rank',
                  width: rankWidth,
                  label: _header('Rank', Alignment.center)),
              GridColumn(
                  columnName: 'team',
                  width: teamWidth,
                  label: _header('Team', Alignment.centerLeft)),
              for (final (key, label) in [
                ('opr', 'OPR'),
                ('auto', 'Auto'),
                ('teleop', 'Teleop')
              ])
                GridColumn(
                    columnName: key,
                    width: metricWidth,
                    minimumWidth: compact ? 88 : 96,
                    label: _header(label, Alignment.centerRight)),
            ],
            onCellTap: (details) {
              final index = details.rowColumnIndex.rowIndex - 1;
              if (index >= 0 && index < widget.teams.length)
                widget.onTeamTap(widget.teams[index]);
            },
          ),
        );
      });

  Widget _header(String label, Alignment alignment) => Container(
        alignment: alignment,
        padding: EdgeInsets.symmetric(
            horizontal: alignment == Alignment.center ? 4 : 10),
        child: Text(label,
            maxLines: 1,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
}

class _RankingSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  Map<String, RankingMetricRange> _ranges = {};
  late Future<Map<String, dynamic>> Function(int) _identity;
  Future<void> Function()? onRefresh;

  @override
  Future<void> handleRefresh() async {
    await onRefresh?.call();
  }

  @override
  List<DataGridRow> get rows => _rows;

  void update(List<GlobalRanking> teams, Map<String, RankingMetricRange> ranges,
      Future<Map<String, dynamic>> Function(int) identity) {
    _ranges = ranges;
    _identity = identity;
    _rows = [
      for (final team in teams)
        DataGridRow(cells: [
          DataGridCell<int>(columnName: 'rank', value: team.rank),
          DataGridCell<GlobalRanking>(columnName: 'team', value: team),
          DataGridCell<double>(columnName: 'opr', value: team.opr),
          DataGridCell<double?>(columnName: 'auto', value: team.auto),
          DataGridCell<double?>(columnName: 'teleop', value: team.teleop),
        ])
    ];
    notifyListeners();
  }

  Color _color(String metric, num? value) {
    if (value == null || !value.isFinite) return AppColors.surface;
    final range = _ranges[metric];
    if (range == null || range.min == range.max) return const Color(0xFF3D464C);
    var position =
        ((value - range.min) / (range.max - range.min)).clamp(0.0, 1.0);
    if (metric == 'rank') position = 1 - position;
    const low = Color(0xFF543C43);
    const middle = Color(0xFF5F5943);
    const high = Color(0xFF315A4A);
    return position <= 0.5
        ? Color.lerp(low, middle, position * 2)!
        : Color.lerp(middle, high, (position - 0.5) * 2)!;
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final team = row.getCells()[1].value as GlobalRanking;
    return DataGridRowAdapter(cells: [
      for (final cell in row.getCells())
        if (cell.columnName == 'team')
          _team(team)
        else
          _metric(team.team, cell.columnName, cell.value as num?),
    ]);
  }

  Widget _metric(int team, String metric, num? value) {
    final label = value == null || !value.isFinite
        ? '\u2014'
        : metric == 'rank'
            ? value.toInt().toString()
            : value.toStringAsFixed(1);
    return Semantics(
        label: 'Team $team, $metric: $label',
        child: Container(
          key: ValueKey('ranking-cell-$team-$metric'),
          alignment:
              metric == 'rank' ? Alignment.center : Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: _color(metric, value),
          child: Text(label,
              maxLines: 1,
              style: TextStyle(
                  color: const Color(0xFFF2F3F4),
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight:
                      metric == 'opr' ? FontWeight.w700 : FontWeight.w500)),
        ));
  }

  Widget _team(GlobalRanking team) => Container(
        key: ValueKey('ranking-${team.team}'),
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(children: [
          _TeamAvatar(team: team.team, identity: () => _identity(team.team)),
          const SizedBox(width: 10),
          Expanded(
              child: Tooltip(
                  message: team.name,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${team.team}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(team.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ))),
        ]),
      );
}

class _TeamAvatar extends StatefulWidget {
  final int team;
  final Future<Map<String, dynamic>> Function() identity;
  const _TeamAvatar({required this.team, required this.identity});
  @override
  State<_TeamAvatar> createState() => _TeamAvatarState();
}

class _TeamAvatarState extends State<_TeamAvatar> {
  late Future<Map<String, dynamic>> _identity = widget.identity();
  @override
  void didUpdateWidget(covariant _TeamAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.team != widget.team) _identity = widget.identity();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _identity,
        builder: (context, snapshot) {
          Uint8List? avatar;
          final encoded = snapshot.data?['avatar'];
          if (encoded is String && encoded.isNotEmpty) {
            try {
              avatar = base64Decode(encoded);
            } on FormatException {/* Use the fallback. */}
          }
          const fallback =
              Icon(Icons.ac_unit_rounded, size: 23, color: AppColors.textMuted);
          return Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10)),
              child: avatar == null
                  ? fallback
                  : Image.memory(avatar,
                      fit: BoxFit.contain,
                      semanticLabel: 'Team ${widget.team} icon',
                      errorBuilder: (_, __, ___) => fallback));
        },
      );
}
