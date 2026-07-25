import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_group_details.freezed.dart';
part 'user_group_details.g.dart';

@freezed
class UserGroupInfo with _$UserGroupInfo {
  const factory UserGroupInfo({
    required String group_id,
    required String name,
    required String role,
  }) = _UserGroupInfo;

  factory UserGroupInfo.fromJson(Map<String, dynamic> json) =>
      _$UserGroupInfoFromJson(json);
}
