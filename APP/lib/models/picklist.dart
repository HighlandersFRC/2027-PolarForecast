class PicklistEntry {
  final int team;
  String tier;
  String note;

  PicklistEntry({
    required this.team,
    this.tier = '',
    this.note = '',
  });

  factory PicklistEntry.fromJson(Map<String, dynamic> json) {
    return PicklistEntry(
      team: (json['team'] as num).toInt(),
      tier: json['tier']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'team': team,
        'tier': tier,
        'note': note,
      };
}

class PicklistData {
  final String id;
  String name;
  String sortBy;
  List<PicklistEntry> teams;

  PicklistData({
    required this.id,
    required this.name,
    required this.sortBy,
    required this.teams,
  });

  factory PicklistData.fromJson(Map<String, dynamic> json) {
    final rawTeams = json['teams'];
    return PicklistData(
      id: json['picklist_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Main Picklist',
      sortBy: json['sort_by']?.toString() ?? 'manual',
      teams: rawTeams is List
          ? rawTeams
              .whereType<Map>()
              .map((item) => PicklistEntry.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : [],
    );
  }
}

const Map<String, String> picklistSortLabels = {
  'manual': 'Manual order',
  'rank': 'Event rank',
  'opr': 'OPR',
  'defense': 'Played defense',
  'team': 'Team number',
};
