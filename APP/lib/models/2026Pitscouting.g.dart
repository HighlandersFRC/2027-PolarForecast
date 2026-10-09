// GENERATED CODE - DO NOT MODIFY BY HAND

part of '2026Pitscouting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PitScouting2026Impl _$$PitScouting2026ImplFromJson(
        Map<String, dynamic> json) =>
    _$PitScouting2026Impl(
      event: json['event'] as String,
      team: (json['team'] as num).toInt(),
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
      groupId: json['groupId'] as String?,
      scoutInfo: ScoutInfo.fromJson(json['scoutInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PitScouting2026ImplToJson(
        _$PitScouting2026Impl instance) =>
    <String, dynamic>{
      'event': instance.event,
      'team': instance.team,
      'data': instance.data,
      'groupId': instance.groupId,
      'scoutInfo': instance.scoutInfo,
    };

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
      trench: json['trench'] as bool,
      bump: json['bump'] as bool,
      shooter_type: json['shooter_type'] as String,
      climb: json['climb'] as String,
      bps: (json['bps'] as num).toDouble(),
      autos: Auto.fromJson(json['autos'] as Map<String, dynamic>),
      driver_events: (json['driver_events'] as num).toInt(),
      favorite_robot_part: json['favorite_robot_part'] as String,
      drive_train: json['drive_train'] as String,
      comments: json['comments'] as String,
    );

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{
      'trench': instance.trench,
      'bump': instance.bump,
      'shooter_type': instance.shooter_type,
      'climb': instance.climb,
      'bps': instance.bps,
      'autos': instance.autos,
      'driver_events': instance.driver_events,
      'favorite_robot_part': instance.favorite_robot_part,
      'drive_train': instance.drive_train,
      'comments': instance.comments,
    };

_$AutoPathPitImpl _$$AutoPathPitImplFromJson(Map<String, dynamic> json) =>
    _$AutoPathPitImpl(
      auto_paths: (json['auto_paths'] as List<dynamic>?)
              ?.map((e) => PitAutoRoutine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PitAutoRoutine>[],
    );

Map<String, dynamic> _$$AutoPathPitImplToJson(_$AutoPathPitImpl instance) =>
    <String, dynamic>{
      'auto_paths': instance.auto_paths,
    };

_$PitAutoRoutineImpl _$$PitAutoRoutineImplFromJson(Map<String, dynamic> json) =>
    _$PitAutoRoutineImpl(
      name: json['name'] as String,
      path:
          (json['path'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
    );

Map<String, dynamic> _$$PitAutoRoutineImplToJson(
        _$PitAutoRoutineImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
    };

_$AutoImpl _$$AutoImplFromJson(Map<String, dynamic> json) => _$AutoImpl(
      autos: AutoPathPit.fromJson(json['autos'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AutoImplToJson(_$AutoImpl instance) =>
    <String, dynamic>{
      'autos': instance.autos,
    };
