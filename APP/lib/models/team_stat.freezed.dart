// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_stat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TeamStat _$TeamStatFromJson(Map<String, dynamic> json) {
  return _TeamStat.fromJson(json);
}

/// @nodoc
mixin _$TeamStat {
  int get Team =>
      throw _privateConstructorUsedError; // A team may temporarily have no rank before rankings exist.
  int get Rank => throw _privateConstructorUsedError;
  double get OPR => throw _privateConstructorUsedError;
  double get Auto => throw _privateConstructorUsedError;
  double get Teleop => throw _privateConstructorUsedError;
  double get Endgame => throw _privateConstructorUsedError;
  double get Climb => throw _privateConstructorUsedError;
  List<TeamMatchHistory> get MatchHistory => throw _privateConstructorUsedError;

  /// Serializes this TeamStat to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamStatCopyWith<TeamStat> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamStatCopyWith<$Res> {
  factory $TeamStatCopyWith(TeamStat value, $Res Function(TeamStat) then) =
      _$TeamStatCopyWithImpl<$Res, TeamStat>;
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
class _$TeamStatCopyWithImpl<$Res, $Val extends TeamStat>
    implements $TeamStatCopyWith<$Res> {
  _$TeamStatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamStat
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
abstract class _$$TeamStatImplCopyWith<$Res>
    implements $TeamStatCopyWith<$Res> {
  factory _$$TeamStatImplCopyWith(
          _$TeamStatImpl value, $Res Function(_$TeamStatImpl) then) =
      __$$TeamStatImplCopyWithImpl<$Res>;
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
class __$$TeamStatImplCopyWithImpl<$Res>
    extends _$TeamStatCopyWithImpl<$Res, _$TeamStatImpl>
    implements _$$TeamStatImplCopyWith<$Res> {
  __$$TeamStatImplCopyWithImpl(
      _$TeamStatImpl _value, $Res Function(_$TeamStatImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamStat
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
    return _then(_$TeamStatImpl(
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
class _$TeamStatImpl extends _TeamStat {
  const _$TeamStatImpl(
      {required this.Team,
      this.Rank = 0,
      this.OPR = 0.0,
      this.Auto = 0.0,
      this.Teleop = 0.0,
      this.Endgame = 0.0,
      this.Climb = 0.0,
      final List<TeamMatchHistory> MatchHistory = const <TeamMatchHistory>[]})
      : _MatchHistory = MatchHistory,
        super._();

  factory _$TeamStatImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamStatImplFromJson(json);

  @override
  final int Team;
// A team may temporarily have no rank before rankings exist.
  @override
  @JsonKey()
  final int Rank;
  @override
  @JsonKey()
  final double OPR;
  @override
  @JsonKey()
  final double Auto;
  @override
  @JsonKey()
  final double Teleop;
  @override
  @JsonKey()
  final double Endgame;
  @override
  @JsonKey()
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
    return 'TeamStat(Team: $Team, Rank: $Rank, OPR: $OPR, Auto: $Auto, Teleop: $Teleop, Endgame: $Endgame, Climb: $Climb, MatchHistory: $MatchHistory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamStatImpl &&
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

  /// Create a copy of TeamStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamStatImplCopyWith<_$TeamStatImpl> get copyWith =>
      __$$TeamStatImplCopyWithImpl<_$TeamStatImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamStatImplToJson(
      this,
    );
  }
}

abstract class _TeamStat extends TeamStat {
  const factory _TeamStat(
      {required final int Team,
      final int Rank,
      final double OPR,
      final double Auto,
      final double Teleop,
      final double Endgame,
      final double Climb,
      final List<TeamMatchHistory> MatchHistory}) = _$TeamStatImpl;
  const _TeamStat._() : super._();

  factory _TeamStat.fromJson(Map<String, dynamic> json) =
      _$TeamStatImpl.fromJson;

  @override
  int get Team; // A team may temporarily have no rank before rankings exist.
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

  /// Create a copy of TeamStat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamStatImplCopyWith<_$TeamStatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TeamMatchHistory _$TeamMatchHistoryFromJson(Map<String, dynamic> json) {
  return _TeamMatchHistory.fromJson(json);
}

/// @nodoc
mixin _$TeamMatchHistory {
  String get Match => throw _privateConstructorUsedError;
  String? get CompLevel => throw _privateConstructorUsedError;
  int get SetNumber => throw _privateConstructorUsedError;
  int get MatchNumber => throw _privateConstructorUsedError;
  int? get ActualTime => throw _privateConstructorUsedError;
  int get MatchesPlayed => throw _privateConstructorUsedError;
  double get OPR => throw _privateConstructorUsedError;

  /// Serializes this TeamMatchHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamMatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamMatchHistoryCopyWith<TeamMatchHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamMatchHistoryCopyWith<$Res> {
  factory $TeamMatchHistoryCopyWith(
          TeamMatchHistory value, $Res Function(TeamMatchHistory) then) =
      _$TeamMatchHistoryCopyWithImpl<$Res, TeamMatchHistory>;
  @useResult
  $Res call(
      {String Match,
      String? CompLevel,
      int SetNumber,
      int MatchNumber,
      int? ActualTime,
      int MatchesPlayed,
      double OPR});
}

/// @nodoc
class _$TeamMatchHistoryCopyWithImpl<$Res, $Val extends TeamMatchHistory>
    implements $TeamMatchHistoryCopyWith<$Res> {
  _$TeamMatchHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamMatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? Match = null,
    Object? CompLevel = freezed,
    Object? SetNumber = null,
    Object? MatchNumber = null,
    Object? ActualTime = freezed,
    Object? MatchesPlayed = null,
    Object? OPR = null,
  }) {
    return _then(_value.copyWith(
      Match: null == Match
          ? _value.Match
          : Match // ignore: cast_nullable_to_non_nullable
              as String,
      CompLevel: freezed == CompLevel
          ? _value.CompLevel
          : CompLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      SetNumber: null == SetNumber
          ? _value.SetNumber
          : SetNumber // ignore: cast_nullable_to_non_nullable
              as int,
      MatchNumber: null == MatchNumber
          ? _value.MatchNumber
          : MatchNumber // ignore: cast_nullable_to_non_nullable
              as int,
      ActualTime: freezed == ActualTime
          ? _value.ActualTime
          : ActualTime // ignore: cast_nullable_to_non_nullable
              as int?,
      MatchesPlayed: null == MatchesPlayed
          ? _value.MatchesPlayed
          : MatchesPlayed // ignore: cast_nullable_to_non_nullable
              as int,
      OPR: null == OPR
          ? _value.OPR
          : OPR // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeamMatchHistoryImplCopyWith<$Res>
    implements $TeamMatchHistoryCopyWith<$Res> {
  factory _$$TeamMatchHistoryImplCopyWith(_$TeamMatchHistoryImpl value,
          $Res Function(_$TeamMatchHistoryImpl) then) =
      __$$TeamMatchHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String Match,
      String? CompLevel,
      int SetNumber,
      int MatchNumber,
      int? ActualTime,
      int MatchesPlayed,
      double OPR});
}

/// @nodoc
class __$$TeamMatchHistoryImplCopyWithImpl<$Res>
    extends _$TeamMatchHistoryCopyWithImpl<$Res, _$TeamMatchHistoryImpl>
    implements _$$TeamMatchHistoryImplCopyWith<$Res> {
  __$$TeamMatchHistoryImplCopyWithImpl(_$TeamMatchHistoryImpl _value,
      $Res Function(_$TeamMatchHistoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamMatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? Match = null,
    Object? CompLevel = freezed,
    Object? SetNumber = null,
    Object? MatchNumber = null,
    Object? ActualTime = freezed,
    Object? MatchesPlayed = null,
    Object? OPR = null,
  }) {
    return _then(_$TeamMatchHistoryImpl(
      Match: null == Match
          ? _value.Match
          : Match // ignore: cast_nullable_to_non_nullable
              as String,
      CompLevel: freezed == CompLevel
          ? _value.CompLevel
          : CompLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      SetNumber: null == SetNumber
          ? _value.SetNumber
          : SetNumber // ignore: cast_nullable_to_non_nullable
              as int,
      MatchNumber: null == MatchNumber
          ? _value.MatchNumber
          : MatchNumber // ignore: cast_nullable_to_non_nullable
              as int,
      ActualTime: freezed == ActualTime
          ? _value.ActualTime
          : ActualTime // ignore: cast_nullable_to_non_nullable
              as int?,
      MatchesPlayed: null == MatchesPlayed
          ? _value.MatchesPlayed
          : MatchesPlayed // ignore: cast_nullable_to_non_nullable
              as int,
      OPR: null == OPR
          ? _value.OPR
          : OPR // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamMatchHistoryImpl implements _TeamMatchHistory {
  const _$TeamMatchHistoryImpl(
      {required this.Match,
      this.CompLevel,
      this.SetNumber = 0,
      this.MatchNumber = 0,
      this.ActualTime,
      this.MatchesPlayed = 0,
      this.OPR = 0.0});

  factory _$TeamMatchHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamMatchHistoryImplFromJson(json);

  @override
  final String Match;
  @override
  final String? CompLevel;
  @override
  @JsonKey()
  final int SetNumber;
  @override
  @JsonKey()
  final int MatchNumber;
  @override
  final int? ActualTime;
  @override
  @JsonKey()
  final int MatchesPlayed;
  @override
  @JsonKey()
  final double OPR;

  @override
  String toString() {
    return 'TeamMatchHistory(Match: $Match, CompLevel: $CompLevel, SetNumber: $SetNumber, MatchNumber: $MatchNumber, ActualTime: $ActualTime, MatchesPlayed: $MatchesPlayed, OPR: $OPR)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamMatchHistoryImpl &&
            (identical(other.Match, Match) || other.Match == Match) &&
            (identical(other.CompLevel, CompLevel) ||
                other.CompLevel == CompLevel) &&
            (identical(other.SetNumber, SetNumber) ||
                other.SetNumber == SetNumber) &&
            (identical(other.MatchNumber, MatchNumber) ||
                other.MatchNumber == MatchNumber) &&
            (identical(other.ActualTime, ActualTime) ||
                other.ActualTime == ActualTime) &&
            (identical(other.MatchesPlayed, MatchesPlayed) ||
                other.MatchesPlayed == MatchesPlayed) &&
            (identical(other.OPR, OPR) || other.OPR == OPR));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, Match, CompLevel, SetNumber,
      MatchNumber, ActualTime, MatchesPlayed, OPR);

  /// Create a copy of TeamMatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamMatchHistoryImplCopyWith<_$TeamMatchHistoryImpl> get copyWith =>
      __$$TeamMatchHistoryImplCopyWithImpl<_$TeamMatchHistoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamMatchHistoryImplToJson(
      this,
    );
  }
}

abstract class _TeamMatchHistory implements TeamMatchHistory {
  const factory _TeamMatchHistory(
      {required final String Match,
      final String? CompLevel,
      final int SetNumber,
      final int MatchNumber,
      final int? ActualTime,
      final int MatchesPlayed,
      final double OPR}) = _$TeamMatchHistoryImpl;

  factory _TeamMatchHistory.fromJson(Map<String, dynamic> json) =
      _$TeamMatchHistoryImpl.fromJson;

  @override
  String get Match;
  @override
  String? get CompLevel;
  @override
  int get SetNumber;
  @override
  int get MatchNumber;
  @override
  int? get ActualTime;
  @override
  int get MatchesPlayed;
  @override
  double get OPR;

  /// Create a copy of TeamMatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamMatchHistoryImplCopyWith<_$TeamMatchHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
