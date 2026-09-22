import 'package:freezed_annotation/freezed_annotation.dart';

import 'scout_info.dart';

part 'follow_up.freezed.dart';
part 'follow_up.g.dart';

@freezed
class FollowUp with _$FollowUp {
  const factory FollowUp({
    required String event,
    required String match,
    required int team,
    @JsonKey(name: 'scout_info') required ScoutInfo scoutInfo,
    @JsonKey(name: 'groupID') required String groupId,
    required FollowUpData data,
  }) = _FollowUp;

  factory FollowUp.fromJson(Map<String, dynamic> json) =>
      _$FollowUpFromJson(json);
}

@freezed
class FollowUpData with _$FollowUpData {
  const factory FollowUpData({
    required String severity,
    required String comments,
  }) = _FollowUpData;

  factory FollowUpData.fromJson(Map<String, dynamic> json) =>
      _$FollowUpDataFromJson(json);
}

@freezed
class FollowUpIncident with _$FollowUpIncident {
  const factory FollowUpIncident({
    @JsonKey(name: 'incident_id') required String incidentId,
    required String event,
    required int team,
    required String match,
    @JsonKey(name: 'match_key') required String matchKey,
    required bool resolved,
    @JsonKey(name: 'report_count') required int reportCount,
    @Default(<DeathReport>[])
    @JsonKey(name: 'death_reports')
    List<DeathReport> deathReports,
    @Default(FollowUpResolution()) FollowUpResolution? followup,
  }) = _FollowUpIncident;

  factory FollowUpIncident.fromJson(Map<String, dynamic> json) =>
      _$FollowUpIncidentFromJson(json);
}

@freezed
class DeathReport with _$DeathReport {
  const factory DeathReport({
    @Default('') String comments,
    @Default('Unknown') @JsonKey(name: 'scout_name') String scoutName,
    @Default('') @JsonKey(name: 'scout_username') String scoutUsername,
    @JsonKey(name: 'submitted_at') String? submittedAt,
  }) = _DeathReport;

  factory DeathReport.fromJson(Map<String, dynamic> json) =>
      _$DeathReportFromJson(json);
}

@freezed
class FollowUpResolution with _$FollowUpResolution {
  const factory FollowUpResolution({
    @Default('') String severity,
    @Default('') String comments,
    @Default('Unknown') @JsonKey(name: 'scout_name') String scoutName,
    @JsonKey(name: 'submitted_at') String? submittedAt,
  }) = _FollowUpResolution;

  factory FollowUpResolution.fromJson(Map<String, dynamic> json) =>
      _$FollowUpResolutionFromJson(json);
}
