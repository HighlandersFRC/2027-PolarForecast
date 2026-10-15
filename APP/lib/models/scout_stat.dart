class ScoutStat {
  final String id;
  final String name;
  final String username;
  final double? trustRating;
  final double contribution;
  final int entries;
  final bool provisional;

  const ScoutStat({
    required this.id,
    required this.name,
    required this.username,
    required this.trustRating,
    required this.contribution,
    required this.entries,
    required this.provisional,
  });

  factory ScoutStat.fromJson(Map<String, dynamic> json) => ScoutStat(
        id: json['ScoutId'] as String,
        name: json['Name'] as String,
        username: json['Username'] as String? ?? '',
        trustRating: (json['TrustRating'] as num?)?.toDouble(),
        contribution: (json['Contribution'] as num).toDouble(),
        entries: (json['Entries'] as num).toInt(),
        provisional: json['Provisional'] as bool? ?? true,
      );
}
