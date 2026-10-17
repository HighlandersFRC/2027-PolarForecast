class TeamEvent {
  final String key;
  final String name;
  final DateTime? start;
  final DateTime? end;
  final String location;

  const TeamEvent({
    required this.key,
    required this.name,
    this.start,
    this.end,
    this.location = '',
  });

  factory TeamEvent.fromJson(Map<String, dynamic> json) => TeamEvent(
        key: json['key'] as String,
        name: json['name'] as String,
        start: DateTime.tryParse(json['start_date'] as String? ?? ''),
        end: DateTime.tryParse(json['end_date'] as String? ?? ''),
        location: [json['city'], json['state_prov'], json['country']]
            .whereType<String>()
            .where((part) => part.trim().isNotEmpty)
            .join(', '),
      );
}
