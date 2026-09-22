import 'package:freezed_annotation/freezed_annotation.dart';

part 'scout_info.freezed.dart';
part 'scout_info.g.dart';

@freezed
class ScoutInfo with _$ScoutInfo {
  const factory ScoutInfo({
    required String userId,
    required String firstName,
    required String username,
    required String team,
  }) = _ScoutInfo;

  factory ScoutInfo.fromJson(Map<String, dynamic> json) =>
      _$ScoutInfoFromJson(json);
}
