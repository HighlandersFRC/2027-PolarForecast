import 'package:app/models/team_stat.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';

Future<void> showTeamComparison(BuildContext context, List<TeamStat> teams,
        {required bool scouting}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
          child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: TeamComparison(teams: teams, scouting: scouting),
      )),
    );

class TeamComparison extends StatefulWidget {
  final List<TeamStat> teams;
  final bool scouting;
  const TeamComparison(
      {super.key, required this.teams, required this.scouting});
  @override
  State<TeamComparison> createState() => _TeamComparisonState();
}

class _TeamComparisonState extends State<TeamComparison> {
  late _ComparisonSource _source;
  @override
  void initState() {
    super.initState();
    _source = _ComparisonSource(widget.teams, widget.scouting);
  }

  @override
  void didUpdateWidget(covariant TeamComparison oldWidget) {
    super.didUpdateWidget(oldWidget);
    _source.dispose();
    _source = _ComparisonSource(widget.teams, widget.scouting);
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('Compare your options',
                    style:
                        TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
            IconButton(
                tooltip: 'Close comparison',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded)),
          ]),
          const Text('Same event. Side-by-side performance.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          Expanded(
              child: SfDataGridTheme(
            data: const SfDataGridThemeData(
                headerColor: AppColors.surfaceRaised,
                gridLineColor: AppColors.border,
                frozenPaneElevation: 0),
            child: SfDataGrid(
              source: _source,
              frozenColumnsCount: 1,
              rowHeight: 52,
              headerRowHeight: 52,
              columnWidthMode: ColumnWidthMode.fill,
              columns: [
                GridColumn(
                    columnName: 'metric', width: 112, label: _header('Metric')),
                for (final team in widget.teams)
                  GridColumn(
                      columnName: '${team.Team}',
                      minimumWidth: 94,
                      label: _header('${team.Team}')),
              ],
            ),
          )),
          const SizedBox(height: 12),
          const Text(
              'OPR is an estimate of scoring contribution. A dash means no observation; defense rate measures frequency.',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 11, height: 1.5)),
        ]),
      );

  Widget _header(String text) => Center(
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.primary)));
}

class _ComparisonSource extends DataGridSource {
  @override
  final List<DataGridRow> rows;
  _ComparisonSource(List<TeamStat> teams, bool scouting)
      : rows = [
          for (final metric in <(String, String Function(TeamStat))>[
            ('Event rank', (t) => t.Rank > 0 ? '#${t.Rank}' : '—'),
            ('OPR', (t) => t.OPR.toStringAsFixed(1)),
            ('Auto', (t) => t.Auto.toStringAsFixed(1)),
            ('Teleop', (t) => t.Teleop.toStringAsFixed(1)),
            ('Tower', (t) => t.Tower.toStringAsFixed(1)),
            if (scouting) ...[
              ('Scouted', (t) => '${t.ScoutedMatches}'),
              (
                'Death rate',
                (t) =>
                    t.ScoutEntries > 0 ? '${(t.DeathRate * 100).round()}%' : '—'
              ),
              (
                'Defense rate',
                (t) => t.ScoutEntries > 0
                    ? '${(t.DefenseRate * 100).round()}%'
                    : '—'
              ),
            ],
          ])
            DataGridRow(cells: [
              DataGridCell<String>(columnName: 'metric', value: metric.$1),
              for (final team in teams)
                DataGridCell<String>(
                    columnName: '${team.Team}', value: metric.$2(team)),
            ]),
        ];

  @override
  DataGridRowAdapter buildRow(DataGridRow row) => DataGridRowAdapter(cells: [
        for (final cell in row.getCells())
          Container(
            alignment: cell.columnName == 'metric'
                ? Alignment.centerLeft
                : Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: cell.columnName == 'metric'
                ? AppColors.surfaceRaised
                : AppColors.surface,
            child: Text('${cell.value}',
                style: TextStyle(
                    fontWeight: cell.columnName == 'metric'
                        ? FontWeight.w500
                        : FontWeight.w700,
                    fontSize: 13)),
          ),
      ]);
}
