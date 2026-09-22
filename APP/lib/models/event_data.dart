// event_data.dart

import 'package:app/models/match_prediction.dart';
import 'package:app/models/team_stat.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_data.freezed.dart';
part 'event_data.g.dart';

@freezed
class EventData with _$EventData {
  const factory EventData({
    required List<TeamStat> stats,
    required List<MatchPrediction> predictions,
  }) = _EventData;

  factory EventData.fromJson(Map<String, dynamic> json) =>
      _$EventDataFromJson(json);
}
