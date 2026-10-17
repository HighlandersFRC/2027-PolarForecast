/// Direct observations from group match-scouting documents only.
class ScoutedMatchScore {
  final String match;
  final String label;
  final double autoFuel;
  final double teleopFuel;
  final int reports;

  double get totalFuel => autoFuel + teleopFuel;

  const ScoutedMatchScore({
    required this.match,
    required this.label,
    required this.autoFuel,
    required this.teleopFuel,
    required this.reports,
  });

  static List<ScoutedMatchScore> fromEntries(
    List<Map<String, dynamic>> entries, {
    required String event,
    required int team,
    required String groupId,
  }) {
    if (groupId.trim().isEmpty) return [];
    final matches = <String, _Reports>{};
    for (final entry in entries) {
      if (entry['event'] != event ||
          entry['groupId'] != groupId ||
          int.tryParse(entry['team'].toString()) != team) continue;

      final match = _Match.parse(entry['match'], event);
      final data = entry['data'];
      if (match == null || data is! Map) continue;
      final auto = _fuel(data['autoScouting'], 300);
      final teleop = _fuel(data['teleopScouting'], 1000);
      // An incomplete report is not a measured zero or a total score.
      if (auto == null || teleop == null) continue;

      final reports = matches.putIfAbsent(match.key, () => _Reports(match));
      reports.auto += auto;
      reports.teleop += teleop;
      reports.count++;
    }

    final ordered = matches.values.toList()
      ..sort((a, b) {
        final phase = a.match.phase.compareTo(b.match.phase);
        if (phase != 0) return phase;
        final set = a.match.set.compareTo(b.match.set);
        return set != 0 ? set : a.match.number.compareTo(b.match.number);
      });
    return [
      for (final reports in ordered)
        ScoutedMatchScore(
          match: reports.match.key,
          label: reports.match.label,
          // Multiple scouts describe one robot performance, not extra fuel.
          autoFuel: reports.auto / reports.count,
          teleopFuel: reports.teleop / reports.count,
          reports: reports.count,
        ),
    ];
  }

  static double? _fuel(dynamic phase, double maximum) {
    if (phase is! Map) return null;
    final raw = phase['fuel_scored'];
    if (raw is! num && raw is! String) return null;
    final value = double.tryParse(raw.toString());
    return value != null && value.isFinite && value >= 0 && value <= maximum
        ? value
        : null;
  }
}

class _Reports {
  final _Match match;
  double auto = 0;
  double teleop = 0;
  int count = 0;
  _Reports(this.match);
}

class _Match {
  final String key;
  final String label;
  final int phase;
  final int set;
  final int number;
  const _Match(this.key, this.label, this.phase, this.set, this.number);

  static _Match? parse(dynamic value, String event) {
    var text = value?.toString().trim().toLowerCase() ?? '';
    if (text.startsWith('${event.toLowerCase()}_')) {
      text = text.substring(event.length + 1);
    }
    if (RegExp(r'^\d+$').hasMatch(text)) text = 'qm$text';
    final match = RegExp(r'^(qm|ef|qf|sf|f)(\d+)(?:m(\d+))?$').firstMatch(text);
    if (match == null) return null;
    final level = match.group(1)!;
    final set = int.parse(match.group(2)!);
    final number = int.tryParse(match.group(3) ?? '') ?? 1;
    if (set <= 0 || number <= 0 || (level == 'qm' && match.group(3) != null))
      return null;
    final key = level == 'qm' ? 'qm$set' : '${level}${set}m$number';
    final label =
        level == 'qm' ? 'QM$set' : '${level.toUpperCase()}$set-$number';
    return _Match(
        key, label, ['qm', 'ef', 'qf', 'sf', 'f'].indexOf(level), set, number);
  }
}
