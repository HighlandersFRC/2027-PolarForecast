// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_stat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamStatImpl _$$TeamStatImplFromJson(Map<String, dynamic> json) =>
    _$TeamStatImpl(
      Team: (json['Team'] as num).toInt(),
      Rank: (json['Rank'] as num?)?.toInt() ?? 0,
      OPR: (json['OPR'] as num?)?.toDouble() ?? 0.0,
      Auto: (json['Auto'] as num?)?.toDouble() ?? 0.0,
      Teleop: (json['Teleop'] as num?)?.toDouble() ?? 0.0,
      Endgame: (json['Endgame'] as num?)?.toDouble() ?? 0.0,
      Climb: (json['Climb'] as num?)?.toDouble() ?? 0.0,
      MatchHistory: (json['MatchHistory'] as List<dynamic>?)
              ?.map((e) => TeamMatchHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TeamMatchHistory>[],
    );

Map<String, dynamic> _$$TeamStatImplToJson(_$TeamStatImpl instance) =>
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

_$TeamMatchHistoryImpl _$$TeamMatchHistoryImplFromJson(
        Map<String, dynamic> json) =>
    _$TeamMatchHistoryImpl(
      Match: json['Match'] as String,
      CompLevel: json['CompLevel'] as String?,
      SetNumber: (json['SetNumber'] as num?)?.toInt() ?? 0,
      MatchNumber: (json['MatchNumber'] as num?)?.toInt() ?? 0,
      ActualTime: (json['ActualTime'] as num?)?.toInt(),
      MatchesPlayed: (json['MatchesPlayed'] as num?)?.toInt() ?? 0,
      OPR: (json['OPR'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$TeamMatchHistoryImplToJson(
        _$TeamMatchHistoryImpl instance) =>
    <String, dynamic>{
      'Match': instance.Match,
      'CompLevel': instance.CompLevel,
      'SetNumber': instance.SetNumber,
      'MatchNumber': instance.MatchNumber,
      'ActualTime': instance.ActualTime,
      'MatchesPlayed': instance.MatchesPlayed,
      'OPR': instance.OPR,
    };
