// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '2026StatsModel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Stats2026 _$Stats2026FromJson(Map<String, dynamic> json) {
  return _Stats2026.fromJson(json);
}

/// @nodoc
mixin _$Stats2026 {
  int get Team => throw _privateConstructorUsedError;
  int get Rank => throw _privateConstructorUsedError;
  @JsonKey(name: 'totalOPR')
  double get OPR => throw _privateConstructorUsedError;
  @JsonKey(name: 'autoOPR')
  double get Auto => throw _privateConstructorUsedError;
  @JsonKey(name: 'teleopOPR')
  double get Teleop => throw _privateConstructorUsedError;
  @JsonKey(name: 'towerOPR')
  double get Tower => throw _privateConstructorUsedError;

  /// Serializes this Stats2026 to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Stats2026
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Stats2026CopyWith<Stats2026> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Stats2026CopyWith<$Res> {
  factory $Stats2026CopyWith(Stats2026 value, $Res Function(Stats2026) then) =
      _$Stats2026CopyWithImpl<$Res, Stats2026>;
  @useResult
  $Res call(
      {int Team,
      int Rank,
      @JsonKey(name: 'totalOPR') double OPR,
      @JsonKey(name: 'autoOPR') double Auto,
      @JsonKey(name: 'teleopOPR') double Teleop,
      @JsonKey(name: 'towerOPR') double Tower});
}

/// @nodoc
class _$Stats2026CopyWithImpl<$Res, $Val extends Stats2026>
    implements $Stats2026CopyWith<$Res> {
  _$Stats2026CopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Stats2026
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? Team = null,
    Object? Rank = null,
    Object? OPR = null,
    Object? Auto = null,
    Object? Teleop = null,
    Object? Tower = null,
  }) {
    return _then(_value.copyWith(
      Team: null == Team
          ? _value.Team
          : Team // ignore: cast_nullable_to_non_nullable
              as int,
      Rank: null == Rank
          ? _value.Rank
          : Rank // ignore: cast_nullable_to_non_nullable
              as int,
      OPR: null == OPR
          ? _value.OPR
          : OPR // ignore: cast_nullable_to_non_nullable
              as double,
      Auto: null == Auto
          ? _value.Auto
          : Auto // ignore: cast_nullable_to_non_nullable
              as double,
      Teleop: null == Teleop
          ? _value.Teleop
          : Teleop // ignore: cast_nullable_to_non_nullable
              as double,
      Tower: null == Tower
          ? _value.Tower
          : Tower // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Stats2026ImplCopyWith<$Res>
    implements $Stats2026CopyWith<$Res> {
  factory _$$Stats2026ImplCopyWith(
          _$Stats2026Impl value, $Res Function(_$Stats2026Impl) then) =
      __$$Stats2026ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int Team,
      int Rank,
      @JsonKey(name: 'totalOPR') double OPR,
      @JsonKey(name: 'autoOPR') double Auto,
      @JsonKey(name: 'teleopOPR') double Teleop,
      @JsonKey(name: 'towerOPR') double Tower});
}

/// @nodoc
class __$$Stats2026ImplCopyWithImpl<$Res>
    extends _$Stats2026CopyWithImpl<$Res, _$Stats2026Impl>
    implements _$$Stats2026ImplCopyWith<$Res> {
  __$$Stats2026ImplCopyWithImpl(
      _$Stats2026Impl _value, $Res Function(_$Stats2026Impl) _then)
      : super(_value, _then);

  /// Create a copy of Stats2026
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? Team = null,
    Object? Rank = null,
    Object? OPR = null,
    Object? Auto = null,
    Object? Teleop = null,
    Object? Tower = null,
  }) {
    return _then(_$Stats2026Impl(
      Team: null == Team
          ? _value.Team
          : Team // ignore: cast_nullable_to_non_nullable
              as int,
      Rank: null == Rank
          ? _value.Rank
          : Rank // ignore: cast_nullable_to_non_nullable
              as int,
      OPR: null == OPR
          ? _value.OPR
          : OPR // ignore: cast_nullable_to_non_nullable
              as double,
      Auto: null == Auto
          ? _value.Auto
          : Auto // ignore: cast_nullable_to_non_nullable
              as double,
      Teleop: null == Teleop
          ? _value.Teleop
          : Teleop // ignore: cast_nullable_to_non_nullable
              as double,
      Tower: null == Tower
          ? _value.Tower
          : Tower // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Stats2026Impl implements _Stats2026 {
  const _$Stats2026Impl(
      {required this.Team,
      this.Rank = 0,
      @JsonKey(name: 'totalOPR') this.OPR = 0.0,
      @JsonKey(name: 'autoOPR') this.Auto = 0.0,
      @JsonKey(name: 'teleopOPR') this.Teleop = 0.0,
      @JsonKey(name: 'towerOPR') this.Tower = 0.0});

  factory _$Stats2026Impl.fromJson(Map<String, dynamic> json) =>
      _$$Stats2026ImplFromJson(json);

  @override
  final int Team;
  @override
  @JsonKey()
  final int Rank;
  @override
  @JsonKey(name: 'totalOPR')
  final double OPR;
  @override
  @JsonKey(name: 'autoOPR')
  final double Auto;
  @override
  @JsonKey(name: 'teleopOPR')
  final double Teleop;
  @override
  @JsonKey(name: 'towerOPR')
  final double Tower;

  @override
  String toString() {
    return 'Stats2026(Team: $Team, Rank: $Rank, OPR: $OPR, Auto: $Auto, Teleop: $Teleop, Tower: $Tower)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Stats2026Impl &&
            (identical(other.Team, Team) || other.Team == Team) &&
            (identical(other.Rank, Rank) || other.Rank == Rank) &&
            (identical(other.OPR, OPR) || other.OPR == OPR) &&
            (identical(other.Auto, Auto) || other.Auto == Auto) &&
            (identical(other.Teleop, Teleop) || other.Teleop == Teleop) &&
            (identical(other.Tower, Tower) || other.Tower == Tower));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, Team, Rank, OPR, Auto, Teleop, Tower);

  /// Create a copy of Stats2026
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Stats2026ImplCopyWith<_$Stats2026Impl> get copyWith =>
      __$$Stats2026ImplCopyWithImpl<_$Stats2026Impl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Stats2026ImplToJson(
      this,
    );
  }
}

abstract class _Stats2026 implements Stats2026 {
  const factory _Stats2026(
      {required final int Team,
      final int Rank,
      @JsonKey(name: 'totalOPR') final double OPR,
      @JsonKey(name: 'autoOPR') final double Auto,
      @JsonKey(name: 'teleopOPR') final double Teleop,
      @JsonKey(name: 'towerOPR') final double Tower}) = _$Stats2026Impl;

  factory _Stats2026.fromJson(Map<String, dynamic> json) =
      _$Stats2026Impl.fromJson;

  @override
  int get Team;
  @override
  int get Rank;
  @override
  @JsonKey(name: 'totalOPR')
  double get OPR;
  @override
  @JsonKey(name: 'autoOPR')
  double get Auto;
  @override
  @JsonKey(name: 'teleopOPR')
  double get Teleop;
  @override
  @JsonKey(name: 'towerOPR')
  double get Tower;

  /// Create a copy of Stats2026
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Stats2026ImplCopyWith<_$Stats2026Impl> get copyWith =>
      throw _privateConstructorUsedError;
}
