// GENERATED CODE - DO NOT MODIFY BY HAND

part of '2026StatsModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$Stats2026Impl _$$Stats2026ImplFromJson(Map<String, dynamic> json) =>
    _$Stats2026Impl(
      Team: (json['Team'] as num).toInt(),
      Rank: (json['Rank'] as num?)?.toInt() ?? 0,
      OPR: (json['totalOPR'] as num?)?.toDouble() ?? 0.0,
      Auto: (json['autoOPR'] as num?)?.toDouble() ?? 0.0,
      Teleop: (json['teleopOPR'] as num?)?.toDouble() ?? 0.0,
      Tower: (json['towerOPR'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$Stats2026ImplToJson(_$Stats2026Impl instance) =>
    <String, dynamic>{
      'Team': instance.Team,
      'Rank': instance.Rank,
      'totalOPR': instance.OPR,
      'autoOPR': instance.Auto,
      'teleopOPR': instance.Teleop,
      'towerOPR': instance.Tower,
    };
