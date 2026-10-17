import 'package:app/APIService.dart';
import 'package:app/models/scout_stat.dart';
import 'package:app/services/live_data_controller.dart';
import 'package:app/widgets/event_stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ScoutStatsView extends StatefulWidget {
  final String eventKey;
  final String groupId;
  final String username;

  const ScoutStatsView({
    super.key,
    required this.eventKey,
    required this.groupId,
    required this.username,
  });

  @override
  State<ScoutStatsView> createState() => _ScoutStatsViewState();
}

class _ScoutStatsViewState extends State<ScoutStatsView> {
  final _api = APIService();
  late final LiveDataController<List<ScoutStat>> _data;

  @override
  void initState() {
    super.initState();
    _data = LiveDataController(
        load: () => _api.fetchScoutStats(
              eventKey: widget.eventKey,
              groupId: widget.groupId,
              username: widget.username,
            ));
  }

  @override
  void dispose() {
    _data.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('Scout stats',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
            IconButton(
                tooltip: 'Refresh scout stats',
                onPressed: () => _data.refresh(),
                icon: const Icon(Icons.refresh)),
          ]),
          const Text('Match reports · Your group · * Provisional trust rating',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 10),
          Expanded(
              child: ValueListenableBuilder<AsyncSnapshot<List<ScoutStat>>>(
            valueListenable: _data,
            builder: (context, snapshot, _) {
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  TextButton(
                      onPressed: () => _data.refresh(),
                      child: const Text('Try again')),
                ]));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No scouts found in your group.'));
              }
              return ScoutStatsGrid(scouts: snapshot.data!);
            },
          )),
        ]),
      );
}

/// Keeps names visible while the metric columns scroll on narrow screens.
class ScoutStatsGrid extends StatefulWidget {
  final List<ScoutStat> scouts;
  const ScoutStatsGrid({super.key, required this.scouts});

  @override
  State<ScoutStatsGrid> createState() => _ScoutStatsGridState();
}

class _ScoutStatsGridState extends State<ScoutStatsGrid> {
  final _source = _ScoutSource();
  String _sort = 'trust';
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(covariant ScoutStatsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() => _source.update(widget.scouts, _sort, _ascending);

  void _sortBy(String key) => setState(() {
        _ascending = key == _sort ? !_ascending : key == 'name';
        _sort = key;
        _update();
      });

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return SfDataGridTheme(
          data: const SfDataGridThemeData(
            headerColor: EventStatsGrid.headerColor,
            gridLineColor: EventStatsGrid.borderColor,
            frozenPaneElevation: 0,
            frozenPaneLineColor: EventStatsGrid.borderColor,
          ),
          child: SfDataGrid(
            source: _source,
            frozenColumnsCount: 1,
            rowHeight: 52,
            headerRowHeight: 48,
            columnWidthMode: ColumnWidthMode.fill,
            gridLinesVisibility: GridLinesVisibility.both,
            headerGridLinesVisibility: GridLinesVisibility.both,
            onCellTap: (details) {
              if (details.rowColumnIndex.rowIndex == 0) {
                _sortBy(_columns.keys
                    .elementAt(details.rowColumnIndex.columnIndex));
              }
            },
            columns: [
              for (final column in _columns.entries)
                GridColumn(
                  columnName: column.key,
                  width:
                      compact ? (column.key == 'name' ? 150 : 135) : double.nan,
                  minimumWidth: column.key == 'name' ? 150 : 120,
                  label: Semantics(
                    button: true,
                    label: 'Sort by ${column.value}',
                    onTap: () => _sortBy(column.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      child: Row(children: [
                        Flexible(
                            child: Text(column.value,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                        if (_sort == column.key)
                          Icon(
                              _ascending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        );
      });
}

const _columns = {
  'name': '# / Scout name',
  'trust': 'Trust / 100',
  'contribution': 'Contribution %',
  'entries': 'Entries',
};

num? _metric(ScoutStat scout, String key) => switch (key) {
      'trust' => scout.trustRating,
      'contribution' => scout.contribution,
      'entries' => scout.entries,
      _ => null,
    };

class _ScoutSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  List<ScoutStat> _scouts = [];
  final Map<String, (double, double)> _ranges = {};

  @override
  List<DataGridRow> get rows => _rows;

  void update(List<ScoutStat> scouts, String sort, bool ascending) {
    _scouts = List.of(scouts)
      ..sort((a, b) {
        if (sort == 'name') {
          final order = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return ascending ? order : -order;
        }
        final av = _metric(a, sort), bv = _metric(b, sort);
        if (av == null && bv != null) return 1;
        if (bv == null && av != null) return -1;
        final order = av?.compareTo(bv!) ?? 0;
        if (order != 0) return ascending ? order : -order;
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    _ranges.clear();
    for (final key in ['trust', 'contribution', 'entries']) {
      final values = scouts
          .map((scout) => _metric(scout, key))
          .whereType<num>()
          .map((value) => value.toDouble())
          .toList()
        ..sort();
      if (values.isNotEmpty) _ranges[key] = (values.first, values.last);
    }
    _rows = [
      for (final scout in _scouts)
        DataGridRow(cells: [
          DataGridCell<String>(columnName: 'name', value: scout.name),
          for (final key in _columns.keys.skip(1))
            DataGridCell<num>(columnName: key, value: _metric(scout, key)),
        ])
    ];
    notifyListeners();
  }

  Color _color(String key, num? value) {
    final range = _ranges[key];
    if (range == null || value == null) return EventStatsGrid.surfaceColor;
    if (range.$1 == range.$2) return const Color(0xFF3D464C);
    final t = ((value - range.$1) / (range.$2 - range.$1)).clamp(0.0, 1.0);
    return t <= 0.5
        ? Color.lerp(const Color(0xFF763B46), const Color(0xFF76643A), t * 2)!
        : Color.lerp(
            const Color(0xFF76643A), const Color(0xFF286759), (t - 0.5) * 2)!;
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = _rows.indexOf(row);
    final scout = _scouts[index];
    return DataGridRowAdapter(cells: [
      for (final key in _columns.keys)
        Builder(builder: (context) {
          final value = _metric(scout, key);
          final label = switch (key) {
            'name' => '${index + 1}. ${scout.name}',
            'trust' => value == null
                ? '—'
                : '${value.toStringAsFixed(1)}${scout.provisional ? '*' : ''}',
            'contribution' => '${value!.toStringAsFixed(1)}%',
            _ => value!.toInt().toString(),
          };
          return Tooltip(
            message: key == 'trust'
                ? (scout.provisional
                    ? 'Provisional estimate.'
                    : 'Consistency estimate.')
                : key == 'name'
                    ? '${scout.name} (@${scout.username})'
                    : '${_columns[key]}: $label',
            child: Semantics(
              label: '${scout.name}, ${_columns[key]}: $label',
              child: Container(
                key: ValueKey('scout-cell-${scout.id}-$key'),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: key == 'name'
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                color: _color(key, value),
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            key == 'name' ? FontWeight.w700 : FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ),
          );
        }),
    ]);
  }
}
