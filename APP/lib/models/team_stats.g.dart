// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamStatsImpl _$$TeamStatsImplFromJson(Map<String, dynamic> json) =>
    _$TeamStatsImpl(
      event: json['event'] as String,
      team: (json['team'] as num).toInt(),
      stats: Stats2026.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TeamStatsImplToJson(_$TeamStatsImpl instance) =>
    <String, dynamic>{
      'event': instance.event,
      'team': instance.team,
      'stats': instance.stats,
    };
