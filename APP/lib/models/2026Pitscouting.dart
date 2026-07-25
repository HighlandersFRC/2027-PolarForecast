import 'package:app/models/scout_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '2026Pitscouting.g.dart';
part '2026Pitscouting.freezed.dart';

@freezed
class PitScouting2026 with _$PitScouting2026 {
  const factory PitScouting2026(
      {required String event,
      required int team,
      required Data data,
      String? groupId,
      required ScoutInfo scoutInfo}) = _PitScouting2026;

  factory PitScouting2026.fromJson(Map<String, dynamic> json) =>
      _$PitScouting2026FromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    required bool trench,
    required bool bump,
    required String shooter_type,
    required String climb,
    required double bps,

    // DATA VALIDATION
    required Auto autos,
    required int driver_events,
    required String favorite_robot_part,
    required String drive_train,
    required String comments,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
class AutoPathPit with _$AutoPathPit {
  const factory AutoPathPit({
    @Default(<PitAutoRoutine>[]) List<PitAutoRoutine> auto_paths,
  }) = _AutoPathPit;

  factory AutoPathPit.fromJson(Map<String, dynamic> json) =>
      _$AutoPathPitFromJson(json);
}

@freezed
class PitAutoRoutine with _$PitAutoRoutine {
  const factory PitAutoRoutine({
    required String name,
    @Default(<String>[]) List<String> path,
  }) = _PitAutoRoutine;

  factory PitAutoRoutine.fromJson(Map<String, dynamic> json) =>
      _$PitAutoRoutineFromJson(json);
}

@freezed
class Auto with _$Auto {
  const factory Auto({required AutoPathPit autos}) = _Auto;

  factory Auto.fromJson(Map<String, dynamic> json) => _$AutoFromJson(json);
}
