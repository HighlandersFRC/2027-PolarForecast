// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_stat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamStatImpl _$$TeamStatImplFromJson(Map<String, dynamic> json) =>
    _$TeamStatImpl(
      Team: (json['Team'] as num).toInt(),
      Rank: (json['Rank'] as num?)?.toInt() ?? 0,
      OPR: (json['totalOPR'] as num?)?.toDouble() ?? 0.0,
      Auto: (json['autoOPR'] as num?)?.toDouble() ?? 0.0,
      Teleop: (json['teleopOPR'] as num?)?.toDouble() ?? 0.0,
      Tower: (json['towerOPR'] as num?)?.toDouble() ?? 0.0,
      AverageAutoFuel: (json['AverageAutoFuel'] as num?)?.toDouble(),
      AverageTeleopFuel: (json['AverageTeleopFuel'] as num?)?.toDouble(),
      AverageTotalFuel: (json['AverageTotalFuel'] as num?)?.toDouble(),
      DeathRate: (json['DeathRate'] as num?)?.toDouble() ?? 0.0,
      DefenseRate: (json['DefenseRate'] as num?)?.toDouble() ?? 0.0,
      DefenseCount: (json['DefenseCount'] as num?)?.toInt() ?? 0,
      MatchesPlayed: (json['MatchesPlayed'] as num?)?.toInt() ?? 0,
      ScoutEntries: (json['ScoutEntries'] as num?)?.toInt() ?? 0,
      ScoutedMatches: (json['ScoutedMatches'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TeamStatImplToJson(_$TeamStatImpl instance) =>
    <String, dynamic>{
      'Team': instance.Team,
      'Rank': instance.Rank,
      'totalOPR': instance.OPR,
      'autoOPR': instance.Auto,
      'teleopOPR': instance.Teleop,
      'towerOPR': instance.Tower,
      'AverageAutoFuel': instance.AverageAutoFuel,
      'AverageTeleopFuel': instance.AverageTeleopFuel,
      'AverageTotalFuel': instance.AverageTotalFuel,
      'DeathRate': instance.DeathRate,
      'DefenseRate': instance.DefenseRate,
      'DefenseCount': instance.DefenseCount,
      'MatchesPlayed': instance.MatchesPlayed,
      'ScoutEntries': instance.ScoutEntries,
      'ScoutedMatches': instance.ScoutedMatches,
    };
