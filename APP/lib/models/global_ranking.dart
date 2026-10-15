class GlobalRanking {
  final int rank;
  final int team;
  final String name;
  final double opr;
  final double? auto;
  final double? teleop;
  final String eventKey;
  final String eventName;
  final String eventDate;

  const GlobalRanking({
    required this.rank,
    required this.team,
    required this.name,
    required this.opr,
    this.auto,
    this.teleop,
    required this.eventKey,
    required this.eventName,
    required this.eventDate,
  });

  factory GlobalRanking.fromJson(Map<String, dynamic> json) => GlobalRanking(
        rank: (json['rank'] as num).toInt(),
        team: (json['team'] as num).toInt(),
        name: json['name'] as String,
        opr: (json['opr'] as num).toDouble(),
        auto: (json['auto'] as num?)?.toDouble(),
        teleop: (json['teleop'] as num?)?.toDouble(),
        eventKey: json['event_key'] as String,
        eventName: json['event_name'] as String,
        eventDate: json['event_date'] as String,
      );
}

class RankingMetricRange {
  final double min;
  final double max;
  const RankingMetricRange(this.min, this.max);
}

class GlobalRankingPage {
  final List<GlobalRanking> teams;
  final int year;
  final int total;
  final int matched;
  final int? nextOffset;
  final String snapshot;
  final DateTime updatedAt;
  final Map<String, RankingMetricRange> ranges;

  const GlobalRankingPage({
    required this.teams,
    required this.year,
    required this.total,
    required this.matched,
    required this.nextOffset,
    required this.snapshot,
    required this.updatedAt,
    this.ranges = const {},
  });

  factory GlobalRankingPage.fromJson(Map<String, dynamic> json) =>
      GlobalRankingPage(
        teams: (json['data'] as List)
            .map(
                (row) => GlobalRanking.fromJson(Map<String, dynamic>.from(row)))
            .toList(),
        year: (json['year'] as num).toInt(),
        total: (json['total'] as num).toInt(),
        matched: (json['matched'] as num).toInt(),
        nextOffset: (json['next_offset'] as num?)?.toInt(),
        snapshot: json['snapshot'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        ranges: (json['ranges'] as Map<String, dynamic>? ?? {}).map(
            (key, value) => MapEntry(
                key,
                RankingMetricRange((value['min'] as num).toDouble(),
                    (value['max'] as num).toDouble()))),
      );
}

class RankingSnapshotExpired implements Exception {}
