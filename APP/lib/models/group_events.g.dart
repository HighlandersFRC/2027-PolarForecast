// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroupEventsImpl _$$GroupEventsImplFromJson(Map<String, dynamic> json) =>
    _$GroupEventsImpl(
      events:
          (json['events'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$GroupEventsImplToJson(_$GroupEventsImpl instance) =>
    <String, dynamic>{
      'events': instance.events,
    };
