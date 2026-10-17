// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_group_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserGroupInfo _$UserGroupInfoFromJson(Map<String, dynamic> json) {
  return _UserGroupInfo.fromJson(json);
}

/// @nodoc
mixin _$UserGroupInfo {
  String get group_id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;

  /// Serializes this UserGroupInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserGroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserGroupInfoCopyWith<UserGroupInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserGroupInfoCopyWith<$Res> {
  factory $UserGroupInfoCopyWith(
          UserGroupInfo value, $Res Function(UserGroupInfo) then) =
      _$UserGroupInfoCopyWithImpl<$Res, UserGroupInfo>;
  @useResult
  $Res call({String group_id, String name, String role});
}

/// @nodoc
class _$UserGroupInfoCopyWithImpl<$Res, $Val extends UserGroupInfo>
    implements $UserGroupInfoCopyWith<$Res> {
  _$UserGroupInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserGroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? group_id = null,
    Object? name = null,
    Object? role = null,
  }) {
    return _then(_value.copyWith(
      group_id: null == group_id
          ? _value.group_id
          : group_id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserGroupInfoImplCopyWith<$Res>
    implements $UserGroupInfoCopyWith<$Res> {
  factory _$$UserGroupInfoImplCopyWith(
          _$UserGroupInfoImpl value, $Res Function(_$UserGroupInfoImpl) then) =
      __$$UserGroupInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String group_id, String name, String role});
}

/// @nodoc
class __$$UserGroupInfoImplCopyWithImpl<$Res>
    extends _$UserGroupInfoCopyWithImpl<$Res, _$UserGroupInfoImpl>
    implements _$$UserGroupInfoImplCopyWith<$Res> {
  __$$UserGroupInfoImplCopyWithImpl(
      _$UserGroupInfoImpl _value, $Res Function(_$UserGroupInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserGroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? group_id = null,
    Object? name = null,
    Object? role = null,
  }) {
    return _then(_$UserGroupInfoImpl(
      group_id: null == group_id
          ? _value.group_id
          : group_id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserGroupInfoImpl implements _UserGroupInfo {
  const _$UserGroupInfoImpl(
      {required this.group_id, required this.name, required this.role});

  factory _$UserGroupInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserGroupInfoImplFromJson(json);

  @override
  final String group_id;
  @override
  final String name;
  @override
  final String role;

  @override
  String toString() {
    return 'UserGroupInfo(group_id: $group_id, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserGroupInfoImpl &&
            (identical(other.group_id, group_id) ||
                other.group_id == group_id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.role, role) || other.role == role));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, group_id, name, role);

  /// Create a copy of UserGroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserGroupInfoImplCopyWith<_$UserGroupInfoImpl> get copyWith =>
      __$$UserGroupInfoImplCopyWithImpl<_$UserGroupInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserGroupInfoImplToJson(
      this,
    );
  }
}

abstract class _UserGroupInfo implements UserGroupInfo {
  const factory _UserGroupInfo(
      {required final String group_id,
      required final String name,
      required final String role}) = _$UserGroupInfoImpl;

  factory _UserGroupInfo.fromJson(Map<String, dynamic> json) =
      _$UserGroupInfoImpl.fromJson;

  @override
  String get group_id;
  @override
  String get name;
  @override
  String get role;

  /// Create a copy of UserGroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserGroupInfoImplCopyWith<_$UserGroupInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
