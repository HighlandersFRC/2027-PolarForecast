import 'package:app/models/team_stat.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '2026StatsModel.freezed.dart';
part '2026StatsModel.g.dart';

@freezed
class Stats2026 with _$Stats2026 {
  const factory Stats2026({
    required int Team,
    required int Rank,
    required double OPR,
    required double Auto,
    required double Teleop,
    required double Endgame,
    required double Climb,
    @Default(<TeamMatchHistory>[]) List<TeamMatchHistory> MatchHistory,
  }) = _Stats2026;

  factory Stats2026.fromJson(Map<String, dynamic> json) =>
      _$Stats2026FromJson(json);
}
