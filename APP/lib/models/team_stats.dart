import 'package:app/models/2026StatsModel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_stats.freezed.dart';
part 'team_stats.g.dart';

@freezed
class TeamStats with _$TeamStats {
  const factory TeamStats({
    required String event,
    required int team,
    required Stats2026 stats,
  }) = _TeamStats;

  factory TeamStats.fromJson(Map<String, dynamic> json) =>
      _$TeamStatsFromJson(json);
}
