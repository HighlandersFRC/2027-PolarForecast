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
    @Default(0.0) double OPR,
    @Default(0.0) double Auto,
    @Default(0.0) double Teleop,
    @Default(0.0) double Endgame,
    @Default(0.0) double Climb,
    double? AutoFuelOPR,
    double? TeleopFuelOPR,
    double? TBAFuelOPR,
    double? TBANonFuelOPR,
    double? AverageAutoFuel,
    double? AverageTeleopFuel,
    double? AverageTotalFuel,
    double? CombinedFuelOPR,
    double? TBAOPR,
    @Default(0.0) double DeathRate,
    @Default(0.0) double DefenseRate,
    @Default(0) int DefenseCount,
    @Default(0) int MatchesPlayed,
    @Default(0) int ScoutEntries,
    @Default(0) int ScoutedMatches,
    @Default(<TeamMatchHistory>[]) List<TeamMatchHistory> MatchHistory,
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

@freezed
class TeamMatchHistory with _$TeamMatchHistory {
  const factory TeamMatchHistory({
    required String Match,
    String? CompLevel,
    @Default(0) int SetNumber,
    @Default(0) int MatchNumber,
    int? ActualTime,
    @Default(0) int MatchesPlayed,
    @Default(0.0) double OPR,
  }) = _TeamMatchHistory;

  factory TeamMatchHistory.fromJson(Map<String, dynamic> json) =>
      _$TeamMatchHistoryFromJson(json);
}
