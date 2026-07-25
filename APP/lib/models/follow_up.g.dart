// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_up.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FollowUpImpl _$$FollowUpImplFromJson(Map<String, dynamic> json) =>
    _$FollowUpImpl(
      event: json['event'] as String,
      match: json['match'] as String,
      team: (json['team'] as num).toInt(),
      scoutInfo: ScoutInfo.fromJson(json['scout_info'] as Map<String, dynamic>),
      groupId: json['groupID'] as String,
      data: FollowUpData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$FollowUpImplToJson(_$FollowUpImpl instance) =>
    <String, dynamic>{
      'event': instance.event,
      'match': instance.match,
      'team': instance.team,
      'scout_info': instance.scoutInfo,
      'groupID': instance.groupId,
      'data': instance.data,
    };

_$FollowUpDataImpl _$$FollowUpDataImplFromJson(Map<String, dynamic> json) =>
    _$FollowUpDataImpl(
      severity: json['severity'] as String,
      comments: json['comments'] as String,
    );

Map<String, dynamic> _$$FollowUpDataImplToJson(_$FollowUpDataImpl instance) =>
    <String, dynamic>{
      'severity': instance.severity,
      'comments': instance.comments,
    };

_$FollowUpIncidentImpl _$$FollowUpIncidentImplFromJson(
        Map<String, dynamic> json) =>
    _$FollowUpIncidentImpl(
      incidentId: json['incident_id'] as String,
      event: json['event'] as String,
      team: (json['team'] as num).toInt(),
      match: json['match'] as String,
      matchKey: json['match_key'] as String,
      resolved: json['resolved'] as bool,
      reportCount: (json['report_count'] as num).toInt(),
      deathReports: (json['death_reports'] as List<dynamic>?)
              ?.map((e) => DeathReport.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DeathReport>[],
      followup: json['followup'] == null
          ? null
          : FollowUpResolution.fromJson(
              json['followup'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$FollowUpIncidentImplToJson(
        _$FollowUpIncidentImpl instance) =>
    <String, dynamic>{
      'incident_id': instance.incidentId,
      'event': instance.event,
      'team': instance.team,
      'match': instance.match,
      'match_key': instance.matchKey,
      'resolved': instance.resolved,
      'report_count': instance.reportCount,
      'death_reports': instance.deathReports,
      'followup': instance.followup,
    };

_$DeathReportImpl _$$DeathReportImplFromJson(Map<String, dynamic> json) =>
    _$DeathReportImpl(
      comments: json['comments'] as String? ?? '',
      scoutName: json['scout_name'] as String? ?? 'Unknown',
      scoutUsername: json['scout_username'] as String? ?? '',
      submittedAt: json['submitted_at'] as String?,
    );

Map<String, dynamic> _$$DeathReportImplToJson(_$DeathReportImpl instance) =>
    <String, dynamic>{
      'comments': instance.comments,
      'scout_name': instance.scoutName,
      'scout_username': instance.scoutUsername,
      'submitted_at': instance.submittedAt,
    };

_$FollowUpResolutionImpl _$$FollowUpResolutionImplFromJson(
        Map<String, dynamic> json) =>
    _$FollowUpResolutionImpl(
      severity: json['severity'] as String? ?? '',
      comments: json['comments'] as String? ?? '',
      scoutName: json['scout_name'] as String? ?? 'Unknown',
      submittedAt: json['submitted_at'] as String?,
    );

Map<String, dynamic> _$$FollowUpResolutionImplToJson(
        _$FollowUpResolutionImpl instance) =>
    <String, dynamic>{
      'severity': instance.severity,
      'comments': instance.comments,
      'scout_name': instance.scoutName,
      'submitted_at': instance.submittedAt,
    };
