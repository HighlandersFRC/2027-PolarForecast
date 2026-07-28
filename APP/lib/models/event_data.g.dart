// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EventDataImpl _$$EventDataImplFromJson(Map<String, dynamic> json) =>
    _$EventDataImpl(
      stats: (json['stats'] as List<dynamic>)
          .map((e) => TeamStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      predictions: (json['predictions'] as List<dynamic>)
          .map((e) => MatchPrediction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$EventDataImplToJson(_$EventDataImpl instance) =>
    <String, dynamic>{
      'stats': instance.stats,
      'predictions': instance.predictions,
    };
