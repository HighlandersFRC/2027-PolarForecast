// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part '2026StatsModel.freezed.dart';
part '2026StatsModel.g.dart';

@freezed
class Stats2026 with _$Stats2026 {
  const factory Stats2026({
    required int Team,
    @Default(0) int Rank,
    @JsonKey(name: 'totalOPR') @Default(0.0) double OPR,
    @JsonKey(name: 'autoOPR') @Default(0.0) double Auto,
    @JsonKey(name: 'teleopOPR') @Default(0.0) double Teleop,
    @JsonKey(name: 'towerOPR') @Default(0.0) double Tower,
  }) = _Stats2026;

  factory Stats2026.fromJson(Map<String, dynamic> json) =>
      _$Stats2026FromJson(json);
}
