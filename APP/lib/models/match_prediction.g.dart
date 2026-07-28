// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_prediction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MatchPredictionImpl _$$MatchPredictionImplFromJson(
        Map<String, dynamic> json) =>
    _$MatchPredictionImpl(
      key: json['key'] as String,
      red_score: (json['red_score'] as num).toDouble(),
      blue_score: (json['blue_score'] as num).toDouble(),
      red_teams: (json['red_teams'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      blue_teams: (json['blue_teams'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      confidence_percentage: (json['confidence_percentage'] as num).toDouble(),
      confidence_label: json['confidence_label'] as String,
      red_win_probability: (json['red_win_probability'] as num).toDouble(),
      blue_win_probability: (json['blue_win_probability'] as num).toDouble(),
    );

Map<String, dynamic> _$$MatchPredictionImplToJson(
        _$MatchPredictionImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'red_score': instance.red_score,
      'blue_score': instance.blue_score,
      'red_teams': instance.red_teams,
      'blue_teams': instance.blue_teams,
      'confidence_percentage': instance.confidence_percentage,
      'confidence_label': instance.confidence_label,
      'red_win_probability': instance.red_win_probability,
      'blue_win_probability': instance.blue_win_probability,
    };
