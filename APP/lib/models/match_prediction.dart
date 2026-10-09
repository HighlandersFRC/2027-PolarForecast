// match_prediction.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_prediction.freezed.dart';
part 'match_prediction.g.dart';

@freezed
class MatchPrediction with _$MatchPrediction {
  const factory MatchPrediction(
      {required String key,
      required double red_score,
      required double blue_score,
      required List<int> red_teams,
      required List<int> blue_teams,
      required double confidence_percentage,
      required String confidence_label,
      required double red_win_probability,
      required double blue_win_probability}) = _MatchPrediction;

  factory MatchPrediction.fromJson(Map<String, dynamic> json) =>
      _$MatchPredictionFromJson(json);
}
