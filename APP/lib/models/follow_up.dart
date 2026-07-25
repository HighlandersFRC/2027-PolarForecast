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
    required ScoutInfo scoutInfo,
   required String groupId,
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
  required String incidentId,
    required String event,
    required int team,
    required String match,
    required String matchKey,
    required bool resolved,
   required int reportCount,
    
    @Default(<DeathReport>[])
    List<DeathReport> deathReports,
    FollowUpResolution? followup,
  }) = _FollowUpIncident;

  factory FollowUpIncident.fromJson(Map<String, dynamic> json) =>
      _$FollowUpIncidentFromJson(json);
}

@freezed
class DeathReport with _$DeathReport {
  const factory DeathReport({
    @Default('') String comments,
    String scoutName,
    String scoutUsername,
    String? submittedAt,
  }) = _DeathReport;

  factory DeathReport.fromJson(Map<String, dynamic> json) =>
      _$DeathReportFromJson(json);
}

@freezed
class FollowUpResolution with _$FollowUpResolution {
  const factory FollowUpResolution({
    @Default('') String severity,
    @Default('') String comments,
    String scoutName,
    String? submittedAt,
  }) = _FollowUpResolution;

  factory FollowUpResolution.fromJson(Map<String, dynamic> json) =>
      _$FollowUpResolutionFromJson(json);
}
