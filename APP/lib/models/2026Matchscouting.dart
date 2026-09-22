import 'package:app/models/scout_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '2026Matchscouting.g.dart';
part '2026Matchscouting.freezed.dart';

@freezed
class MatchScouting2026 with _$MatchScouting2026 {
  const factory MatchScouting2026(
      {required String event,
      required String match,
      required int team,
      required Data data,
      String? groupId,
      required ScoutInfo scoutInfo}) = _MatchScouting2026;

  factory MatchScouting2026.fromJson(Map<String, dynamic> json) =>
      _$MatchScouting2026FromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    required AutoPath autoPath,
    required AutoScouting autoScouting,
    required TeleopScouting teleopScouting,
    required Misc misc,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
class AutoScouting with _$AutoScouting {
  const factory AutoScouting({required int fuel_scored}) = _AutoScouting;

  factory AutoScouting.fromJson(Map<String, dynamic> json) =>
      _$AutoScoutingFromJson(json);
}

@freezed
class TeleopScouting with _$TeleopScouting {
  const factory TeleopScouting({required int fuel_scored}) = _TeleopScouting;

  factory TeleopScouting.fromJson(Map<String, dynamic> json) =>
      _$TeleopScoutingFromJson(json);
}

@freezed
class AutoPath with _$AutoPath {
  const factory AutoPath({required List<String> path}) = _AutoPath;

  factory AutoPath.fromJson(Map<String, dynamic> json) =>
      _$AutoPathFromJson(json);
}

@freezed
class Misc with _$Misc {
  const factory Misc({
    required bool died,
    required bool defense,
    required String comments,
  }) = _Misc;

  factory Misc.fromJson(Map<String, dynamic> json) => _$MiscFromJson(json);
}
