// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_stat.freezed.dart';
part 'team_stat.g.dart';

@freezed
class TeamStat with _$TeamStat {
  const TeamStat._();

  const factory TeamStat({
    required int Team,

    // A team may temporarily have no rank before rankings exist.
    @Default(0) int Rank,
    @JsonKey(name: 'totalOPR') @Default(0.0) double OPR,
    @JsonKey(name: 'autoOPR') @Default(0.0) double Auto,
    @JsonKey(name: 'teleopOPR') @Default(0.0) double Teleop,
    @JsonKey(name: 'towerOPR') @Default(0.0) double Tower,
    double? AverageAutoFuel,
    double? AverageTeleopFuel,
    double? AverageTotalFuel,
    @Default(0.0) double DeathRate,
    @Default(0.0) double DefenseRate,
    @Default(0) int DefenseCount,
    @Default(0) int MatchesPlayed,
    @Default(0) int ScoutEntries,
    @Default(0) int ScoutedMatches,
  }) = _TeamStat;

  factory TeamStat.fromJson(Map<String, dynamic> json) =>
      _$TeamStatFromJson(json);

  static TeamStat fromApiResponse(Map<String, dynamic> response) {
    final rawStats = response['stats'];

    if (rawStats is! Map) {
      throw const FormatException(
        'The team response does not contain a valid "stats" object.',
      );
    }

    return TeamStat.fromJson(
      Map<String, dynamic>.from(rawStats),
    );
  }
}
