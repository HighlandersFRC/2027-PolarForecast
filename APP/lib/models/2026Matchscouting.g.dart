// GENERATED CODE - DO NOT MODIFY BY HAND

part of '2026Matchscouting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MatchScouting2026Impl _$$MatchScouting2026ImplFromJson(
        Map<String, dynamic> json) =>
    _$MatchScouting2026Impl(
      event: json['event'] as String,
      match: json['match'] as String,
      team: (json['team'] as num).toInt(),
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
      groupId: json['groupId'] as String?,
      scoutInfo: ScoutInfo.fromJson(json['scoutInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MatchScouting2026ImplToJson(
        _$MatchScouting2026Impl instance) =>
    <String, dynamic>{
      'event': instance.event,
      'match': instance.match,
      'team': instance.team,
      'data': instance.data,
      'groupId': instance.groupId,
      'scoutInfo': instance.scoutInfo,
    };

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
      autoPath: AutoPath.fromJson(json['autoPath'] as Map<String, dynamic>),
      autoScouting:
          AutoScouting.fromJson(json['autoScouting'] as Map<String, dynamic>),
      teleopScouting: TeleopScouting.fromJson(
          json['teleopScouting'] as Map<String, dynamic>),
      misc: Misc.fromJson(json['misc'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{
      'autoPath': instance.autoPath,
      'autoScouting': instance.autoScouting,
      'teleopScouting': instance.teleopScouting,
      'misc': instance.misc,
    };

_$AutoScoutingImpl _$$AutoScoutingImplFromJson(Map<String, dynamic> json) =>
    _$AutoScoutingImpl(
      fuel_scored: (json['fuel_scored'] as num).toInt(),
    );

Map<String, dynamic> _$$AutoScoutingImplToJson(_$AutoScoutingImpl instance) =>
    <String, dynamic>{
      'fuel_scored': instance.fuel_scored,
    };

_$TeleopScoutingImpl _$$TeleopScoutingImplFromJson(Map<String, dynamic> json) =>
    _$TeleopScoutingImpl(
      fuel_scored: (json['fuel_scored'] as num).toInt(),
    );

Map<String, dynamic> _$$TeleopScoutingImplToJson(
        _$TeleopScoutingImpl instance) =>
    <String, dynamic>{
      'fuel_scored': instance.fuel_scored,
    };

_$AutoPathImpl _$$AutoPathImplFromJson(Map<String, dynamic> json) =>
    _$AutoPathImpl(
      path: (json['path'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$AutoPathImplToJson(_$AutoPathImpl instance) =>
    <String, dynamic>{
      'path': instance.path,
    };

_$MiscImpl _$$MiscImplFromJson(Map<String, dynamic> json) => _$MiscImpl(
      died: json['died'] as bool,
      defense: json['defense'] as bool,
      comments: json['comments'] as String,
    );

Map<String, dynamic> _$$MiscImplToJson(_$MiscImpl instance) =>
    <String, dynamic>{
      'died': instance.died,
      'defense': instance.defense,
      'comments': instance.comments,
    };
