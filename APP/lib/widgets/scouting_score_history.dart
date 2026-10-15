import 'dart:math' as math;

import 'package:app/models/scouted_match_score.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ScoutingScoreHistory extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final String event;
  final int team;
  final String groupId;

  const ScoutingScoreHistory({
    super.key,
    required this.entries,
    required this.event,
    required this.team,
    required this.groupId,
  });

  static const _total = Color(0xFFB7CADF);
  static const _auto = Color(0xFFC9AB76);
  static const _teleop = Color(0xFF80B7A9);
  static const _muted = Color(0xFFADB9C5);

  @override
  Widget build(BuildContext context) {
    final scores = ScoutedMatchScore.fromEntries(entries,
        event: event, team: team, groupId: groupId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18212B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF35424F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scouted scoring by match',
              style: TextStyle(
                  color: Color(0xFFF2F3F4),
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Reported fuel from your group\'s match scouting',
              style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 14),
          if (scores.isEmpty)
            const Text('No complete scouting scores yet.',
                style: TextStyle(color: _muted))
          else ...[
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _legend('Total fuel', _total),
                _legend('Auto', _auto),
                _legend('Teleop', _teleop),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, constraints) {
              final width =
                  math.max(constraints.maxWidth, scores.length * 58.0 + 48);
              final highest =
                  scores.map((score) => score.totalFuel).reduce(math.max);
              final interval = math.max(1.0, (highest / 5).ceilToDouble());
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  height: 260,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: math.max(1.0, scores.length - 1.0),
                      minY: 0,
                      maxY: math.max(5.0,
                          (highest / interval).ceil() * interval + interval),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0xFF35424F), strokeWidth: 0.5),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text('Fuel scored',
                              style: TextStyle(color: _muted, fontSize: 10)),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: interval,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              meta: meta,
                              child: Text(value.toStringAsFixed(0),
                                  style: const TextStyle(
                                      color: _muted, fontSize: 10)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (value != index ||
                                index < 0 ||
                                index >= scores.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(scores[index].label,
                                  style: const TextStyle(
                                      color: _muted, fontSize: 10)),
                            );
                          },
                        )),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          maxContentWidth: 180,
                          getTooltipColor: (_) => const Color(0xFF222D39),
                          getTooltipItems: (spots) => [
                            for (final spot in spots)
                              if (spot.barIndex == 0)
                                _tooltip(scores[spot.x.toInt()])
                              else
                                null,
                          ],
                        ),
                      ),
                      lineBarsData: [
                        _line(scores, (score) => score.totalFuel, _total, 3),
                        _line(scores, (score) => score.autoFuel, _auto, 2),
                        _line(scores, (score) => score.teleopFuel, _teleop, 2),
                      ],
                    ),
                    duration: Duration.zero,
                  ),
                ),
              );
            }),
            if (scores.any((score) => score.reports > 1)) ...[
              const SizedBox(height: 10),
              const Text(
                  'Multiple reports for a match are combined using their mean.',
                  style: TextStyle(color: _muted, fontSize: 11)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      );

  LineChartBarData _line(
          List<ScoutedMatchScore> scores,
          double Function(ScoutedMatchScore) value,
          Color color,
          double width) =>
      LineChartBarData(
        spots: [
          for (var i = 0; i < scores.length; i++)
            FlSpot(i.toDouble(), value(scores[i]))
        ],
        color: color,
        barWidth: width,
        isCurved: false,
        dotData: const FlDotData(show: true),
      );

  LineTooltipItem _tooltip(ScoutedMatchScore score) => LineTooltipItem(
        '${score.label}\n'
        'Total: ${score.totalFuel.toStringAsFixed(1)}\n'
        'Auto: ${score.autoFuel.toStringAsFixed(1)}\n'
        'Teleop: ${score.teleopFuel.toStringAsFixed(1)}\n'
        '${score.reports} scouting report${score.reports == 1 ? '' : 's'}',
        const TextStyle(color: Color(0xFFF2F3F4), fontSize: 12),
      );
}
