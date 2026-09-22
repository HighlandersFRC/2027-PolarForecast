// GENERATED CODE - DO NOT MODIFY BY HAND

part of '2026StatsModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$Stats2026Impl _$$Stats2026ImplFromJson(Map<String, dynamic> json) =>
    _$Stats2026Impl(
      Team: (json['Team'] as num).toInt(),
      Rank: (json['Rank'] as num).toInt(),
      OPR: (json['OPR'] as num).toDouble(),
      Auto: (json['Auto'] as num).toDouble(),
      Teleop: (json['Teleop'] as num).toDouble(),
      Endgame: (json['Endgame'] as num).toDouble(),
      Climb: (json['Climb'] as num).toDouble(),
      MatchHistory: (json['MatchHistory'] as List<dynamic>?)
              ?.map((e) => TeamMatchHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TeamMatchHistory>[],
    );

Map<String, dynamic> _$$Stats2026ImplToJson(_$Stats2026Impl instance) =>
    <String, dynamic>{
      'Team': instance.Team,
      'Rank': instance.Rank,
      'OPR': instance.OPR,
      'Auto': instance.Auto,
      'Teleop': instance.Teleop,
      'Endgame': instance.Endgame,
      'Climb': instance.Climb,
      'MatchHistory': instance.MatchHistory,
    };
