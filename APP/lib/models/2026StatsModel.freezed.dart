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
  double get OPR => throw _privateConstructorUsedError;
  double get Auto => throw _privateConstructorUsedError;
  double get Teleop => throw _privateConstructorUsedError;
  double get Endgame => throw _privateConstructorUsedError;
  double get Climb => throw _privateConstructorUsedError;
  List<TeamMatchHistory> get MatchHistory => throw _privateConstructorUsedError;

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
      double OPR,
      double Auto,
      double Teleop,
      double Endgame,
      double Climb,
      List<TeamMatchHistory> MatchHistory});
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
    Object? Endgame = null,
    Object? Climb = null,
    Object? MatchHistory = null,
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
      Endgame: null == Endgame
          ? _value.Endgame
          : Endgame // ignore: cast_nullable_to_non_nullable
              as double,
      Climb: null == Climb
          ? _value.Climb
          : Climb // ignore: cast_nullable_to_non_nullable
              as double,
      MatchHistory: null == MatchHistory
          ? _value.MatchHistory
          : MatchHistory // ignore: cast_nullable_to_non_nullable
              as List<TeamMatchHistory>,
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
      double OPR,
      double Auto,
      double Teleop,
      double Endgame,
      double Climb,
      List<TeamMatchHistory> MatchHistory});
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
    Object? Endgame = null,
    Object? Climb = null,
    Object? MatchHistory = null,
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
      Endgame: null == Endgame
          ? _value.Endgame
          : Endgame // ignore: cast_nullable_to_non_nullable
              as double,
      Climb: null == Climb
          ? _value.Climb
          : Climb // ignore: cast_nullable_to_non_nullable
              as double,
      MatchHistory: null == MatchHistory
          ? _value._MatchHistory
          : MatchHistory // ignore: cast_nullable_to_non_nullable
              as List<TeamMatchHistory>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Stats2026Impl implements _Stats2026 {
  const _$Stats2026Impl(
      {required this.Team,
      required this.Rank,
      required this.OPR,
      required this.Auto,
      required this.Teleop,
      required this.Endgame,
      required this.Climb,
      final List<TeamMatchHistory> MatchHistory = const <TeamMatchHistory>[]})
      : _MatchHistory = MatchHistory;

  factory _$Stats2026Impl.fromJson(Map<String, dynamic> json) =>
      _$$Stats2026ImplFromJson(json);

  @override
  final int Team;
  @override
  final int Rank;
  @override
  final double OPR;
  @override
  final double Auto;
  @override
  final double Teleop;
  @override
  final double Endgame;
  @override
  final double Climb;
  final List<TeamMatchHistory> _MatchHistory;
  @override
  @JsonKey()
  List<TeamMatchHistory> get MatchHistory {
    if (_MatchHistory is EqualUnmodifiableListView) return _MatchHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_MatchHistory);
  }

  @override
  String toString() {
    return 'Stats2026(Team: $Team, Rank: $Rank, OPR: $OPR, Auto: $Auto, Teleop: $Teleop, Endgame: $Endgame, Climb: $Climb, MatchHistory: $MatchHistory)';
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
            (identical(other.Endgame, Endgame) || other.Endgame == Endgame) &&
            (identical(other.Climb, Climb) || other.Climb == Climb) &&
            const DeepCollectionEquality()
                .equals(other._MatchHistory, _MatchHistory));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, Team, Rank, OPR, Auto, Teleop,
      Endgame, Climb, const DeepCollectionEquality().hash(_MatchHistory));

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
      required final int Rank,
      required final double OPR,
      required final double Auto,
      required final double Teleop,
      required final double Endgame,
      required final double Climb,
      final List<TeamMatchHistory> MatchHistory}) = _$Stats2026Impl;

  factory _Stats2026.fromJson(Map<String, dynamic> json) =
      _$Stats2026Impl.fromJson;

  @override
  int get Team;
  @override
  int get Rank;
  @override
  double get OPR;
  @override
  double get Auto;
  @override
  double get Teleop;
  @override
  double get Endgame;
  @override
  double get Climb;
  @override
  List<TeamMatchHistory> get MatchHistory;

  /// Create a copy of Stats2026
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Stats2026ImplCopyWith<_$Stats2026Impl> get copyWith =>
      throw _privateConstructorUsedError;
}
