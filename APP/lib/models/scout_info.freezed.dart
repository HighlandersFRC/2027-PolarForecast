// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scout_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScoutInfo _$ScoutInfoFromJson(Map<String, dynamic> json) {
  return _ScoutInfo.fromJson(json);
}

/// @nodoc
mixin _$ScoutInfo {
  String get userId => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get team => throw _privateConstructorUsedError;

  /// Serializes this ScoutInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScoutInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScoutInfoCopyWith<ScoutInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScoutInfoCopyWith<$Res> {
  factory $ScoutInfoCopyWith(ScoutInfo value, $Res Function(ScoutInfo) then) =
      _$ScoutInfoCopyWithImpl<$Res, ScoutInfo>;
  @useResult
  $Res call({String userId, String firstName, String username, String team});
}

/// @nodoc
class _$ScoutInfoCopyWithImpl<$Res, $Val extends ScoutInfo>
    implements $ScoutInfoCopyWith<$Res> {
  _$ScoutInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScoutInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? firstName = null,
    Object? username = null,
    Object? team = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: null == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScoutInfoImplCopyWith<$Res>
    implements $ScoutInfoCopyWith<$Res> {
  factory _$$ScoutInfoImplCopyWith(
          _$ScoutInfoImpl value, $Res Function(_$ScoutInfoImpl) then) =
      __$$ScoutInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, String firstName, String username, String team});
}

/// @nodoc
class __$$ScoutInfoImplCopyWithImpl<$Res>
    extends _$ScoutInfoCopyWithImpl<$Res, _$ScoutInfoImpl>
    implements _$$ScoutInfoImplCopyWith<$Res> {
  __$$ScoutInfoImplCopyWithImpl(
      _$ScoutInfoImpl _value, $Res Function(_$ScoutInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScoutInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? firstName = null,
    Object? username = null,
    Object? team = null,
  }) {
    return _then(_$ScoutInfoImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: null == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScoutInfoImpl implements _ScoutInfo {
  const _$ScoutInfoImpl(
      {required this.userId,
      required this.firstName,
      required this.username,
      required this.team});

  factory _$ScoutInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScoutInfoImplFromJson(json);

  @override
  final String userId;
  @override
  final String firstName;
  @override
  final String username;
  @override
  final String team;

  @override
  String toString() {
    return 'ScoutInfo(userId: $userId, firstName: $firstName, username: $username, team: $team)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScoutInfoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.team, team) || other.team == team));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, firstName, username, team);

  /// Create a copy of ScoutInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScoutInfoImplCopyWith<_$ScoutInfoImpl> get copyWith =>
      __$$ScoutInfoImplCopyWithImpl<_$ScoutInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScoutInfoImplToJson(
      this,
    );
  }
}

abstract class _ScoutInfo implements ScoutInfo {
  const factory _ScoutInfo(
      {required final String userId,
      required final String firstName,
      required final String username,
      required final String team}) = _$ScoutInfoImpl;

  factory _ScoutInfo.fromJson(Map<String, dynamic> json) =
      _$ScoutInfoImpl.fromJson;

  @override
  String get userId;
  @override
  String get firstName;
  @override
  String get username;
  @override
  String get team;

  /// Create a copy of ScoutInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScoutInfoImplCopyWith<_$ScoutInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
