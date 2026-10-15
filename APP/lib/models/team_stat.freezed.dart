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
  @JsonKey(name: 'totalOPR')
  double get OPR => throw _privateConstructorUsedError;
  @JsonKey(name: 'autoOPR')
  double get Auto => throw _privateConstructorUsedError;
  @JsonKey(name: 'teleopOPR')
  double get Teleop => throw _privateConstructorUsedError;
  @JsonKey(name: 'towerOPR')
  double get Tower => throw _privateConstructorUsedError;
  double? get AverageAutoFuel => throw _privateConstructorUsedError;
  double? get AverageTeleopFuel => throw _privateConstructorUsedError;
  double? get AverageTotalFuel => throw _privateConstructorUsedError;
  double get DeathRate => throw _privateConstructorUsedError;
  double get DefenseRate => throw _privateConstructorUsedError;
  int get DefenseCount => throw _privateConstructorUsedError;
  int get MatchesPlayed => throw _privateConstructorUsedError;
  int get ScoutEntries => throw _privateConstructorUsedError;
  int get ScoutedMatches => throw _privateConstructorUsedError;

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
      @JsonKey(name: 'totalOPR') double OPR,
      @JsonKey(name: 'autoOPR') double Auto,
      @JsonKey(name: 'teleopOPR') double Teleop,
      @JsonKey(name: 'towerOPR') double Tower,
      double? AverageAutoFuel,
      double? AverageTeleopFuel,
      double? AverageTotalFuel,
      double DeathRate,
      double DefenseRate,
      int DefenseCount,
      int MatchesPlayed,
      int ScoutEntries,
      int ScoutedMatches});
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
    Object? Tower = null,
    Object? AverageAutoFuel = freezed,
    Object? AverageTeleopFuel = freezed,
    Object? AverageTotalFuel = freezed,
    Object? DeathRate = null,
    Object? DefenseRate = null,
    Object? DefenseCount = null,
    Object? MatchesPlayed = null,
    Object? ScoutEntries = null,
    Object? ScoutedMatches = null,
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
      AverageAutoFuel: freezed == AverageAutoFuel
          ? _value.AverageAutoFuel
          : AverageAutoFuel // ignore: cast_nullable_to_non_nullable
              as double?,
      AverageTeleopFuel: freezed == AverageTeleopFuel
          ? _value.AverageTeleopFuel
          : AverageTeleopFuel // ignore: cast_nullable_to_non_nullable
              as double?,
      AverageTotalFuel: freezed == AverageTotalFuel
          ? _value.AverageTotalFuel
          : AverageTotalFuel // ignore: cast_nullable_to_non_nullable
              as double?,
      DeathRate: null == DeathRate
          ? _value.DeathRate
          : DeathRate // ignore: cast_nullable_to_non_nullable
              as double,
      DefenseRate: null == DefenseRate
          ? _value.DefenseRate
          : DefenseRate // ignore: cast_nullable_to_non_nullable
              as double,
      DefenseCount: null == DefenseCount
          ? _value.DefenseCount
          : DefenseCount // ignore: cast_nullable_to_non_nullable
              as int,
      MatchesPlayed: null == MatchesPlayed
          ? _value.MatchesPlayed
          : MatchesPlayed // ignore: cast_nullable_to_non_nullable
              as int,
      ScoutEntries: null == ScoutEntries
          ? _value.ScoutEntries
          : ScoutEntries // ignore: cast_nullable_to_non_nullable
              as int,
      ScoutedMatches: null == ScoutedMatches
          ? _value.ScoutedMatches
          : ScoutedMatches // ignore: cast_nullable_to_non_nullable
              as int,
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
      @JsonKey(name: 'totalOPR') double OPR,
      @JsonKey(name: 'autoOPR') double Auto,
      @JsonKey(name: 'teleopOPR') double Teleop,
      @JsonKey(name: 'towerOPR') double Tower,
      double? AverageAutoFuel,
      double? AverageTeleopFuel,
      double? AverageTotalFuel,
      double DeathRate,
      double DefenseRate,
      int DefenseCount,
      int MatchesPlayed,
      int ScoutEntries,
      int ScoutedMatches});
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
    Object? Tower = null,
    Object? AverageAutoFuel = freezed,
    Object? AverageTeleopFuel = freezed,
    Object? AverageTotalFuel = freezed,
    Object? DeathRate = null,
    Object? DefenseRate = null,
    Object? DefenseCount = null,
    Object? MatchesPlayed = null,
    Object? ScoutEntries = null,
    Object? ScoutedMatches = null,
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
      Tower: null == Tower
          ? _value.Tower
          : Tower // ignore: cast_nullable_to_non_nullable
              as double,
      AverageAutoFuel: freezed == AverageAutoFuel
          ? _value.AverageAutoFuel
          : AverageAutoFuel // ignore: cast_nullable_to_non_nullable
              as double?,
      AverageTeleopFuel: freezed == AverageTeleopFuel
          ? _value.AverageTeleopFuel
          : AverageTeleopFuel // ignore: cast_nullable_to_non_nullable
              as double?,
      AverageTotalFuel: freezed == AverageTotalFuel
          ? _value.AverageTotalFuel
          : AverageTotalFuel // ignore: cast_nullable_to_non_nullable
              as double?,
      DeathRate: null == DeathRate
          ? _value.DeathRate
          : DeathRate // ignore: cast_nullable_to_non_nullable
              as double,
      DefenseRate: null == DefenseRate
          ? _value.DefenseRate
          : DefenseRate // ignore: cast_nullable_to_non_nullable
              as double,
      DefenseCount: null == DefenseCount
          ? _value.DefenseCount
          : DefenseCount // ignore: cast_nullable_to_non_nullable
              as int,
      MatchesPlayed: null == MatchesPlayed
          ? _value.MatchesPlayed
          : MatchesPlayed // ignore: cast_nullable_to_non_nullable
              as int,
      ScoutEntries: null == ScoutEntries
          ? _value.ScoutEntries
          : ScoutEntries // ignore: cast_nullable_to_non_nullable
              as int,
      ScoutedMatches: null == ScoutedMatches
          ? _value.ScoutedMatches
          : ScoutedMatches // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamStatImpl extends _TeamStat {
  const _$TeamStatImpl(
      {required this.Team,
      this.Rank = 0,
      @JsonKey(name: 'totalOPR') this.OPR = 0.0,
      @JsonKey(name: 'autoOPR') this.Auto = 0.0,
      @JsonKey(name: 'teleopOPR') this.Teleop = 0.0,
      @JsonKey(name: 'towerOPR') this.Tower = 0.0,
      this.AverageAutoFuel,
      this.AverageTeleopFuel,
      this.AverageTotalFuel,
      this.DeathRate = 0.0,
      this.DefenseRate = 0.0,
      this.DefenseCount = 0,
      this.MatchesPlayed = 0,
      this.ScoutEntries = 0,
      this.ScoutedMatches = 0})
      : super._();

  factory _$TeamStatImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamStatImplFromJson(json);

  @override
  final int Team;
// A team may temporarily have no rank before rankings exist.
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
  final double? AverageAutoFuel;
  @override
  final double? AverageTeleopFuel;
  @override
  final double? AverageTotalFuel;
  @override
  @JsonKey()
  final double DeathRate;
  @override
  @JsonKey()
  final double DefenseRate;
  @override
  @JsonKey()
  final int DefenseCount;
  @override
  @JsonKey()
  final int MatchesPlayed;
  @override
  @JsonKey()
  final int ScoutEntries;
  @override
  @JsonKey()
  final int ScoutedMatches;

  @override
  String toString() {
    return 'TeamStat(Team: $Team, Rank: $Rank, OPR: $OPR, Auto: $Auto, Teleop: $Teleop, Tower: $Tower, AverageAutoFuel: $AverageAutoFuel, AverageTeleopFuel: $AverageTeleopFuel, AverageTotalFuel: $AverageTotalFuel, DeathRate: $DeathRate, DefenseRate: $DefenseRate, DefenseCount: $DefenseCount, MatchesPlayed: $MatchesPlayed, ScoutEntries: $ScoutEntries, ScoutedMatches: $ScoutedMatches)';
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
            (identical(other.Tower, Tower) || other.Tower == Tower) &&
            (identical(other.AverageAutoFuel, AverageAutoFuel) ||
                other.AverageAutoFuel == AverageAutoFuel) &&
            (identical(other.AverageTeleopFuel, AverageTeleopFuel) ||
                other.AverageTeleopFuel == AverageTeleopFuel) &&
            (identical(other.AverageTotalFuel, AverageTotalFuel) ||
                other.AverageTotalFuel == AverageTotalFuel) &&
            (identical(other.DeathRate, DeathRate) ||
                other.DeathRate == DeathRate) &&
            (identical(other.DefenseRate, DefenseRate) ||
                other.DefenseRate == DefenseRate) &&
            (identical(other.DefenseCount, DefenseCount) ||
                other.DefenseCount == DefenseCount) &&
            (identical(other.MatchesPlayed, MatchesPlayed) ||
                other.MatchesPlayed == MatchesPlayed) &&
            (identical(other.ScoutEntries, ScoutEntries) ||
                other.ScoutEntries == ScoutEntries) &&
            (identical(other.ScoutedMatches, ScoutedMatches) ||
                other.ScoutedMatches == ScoutedMatches));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      Team,
      Rank,
      OPR,
      Auto,
      Teleop,
      Tower,
      AverageAutoFuel,
      AverageTeleopFuel,
      AverageTotalFuel,
      DeathRate,
      DefenseRate,
      DefenseCount,
      MatchesPlayed,
      ScoutEntries,
      ScoutedMatches);

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
      @JsonKey(name: 'totalOPR') final double OPR,
      @JsonKey(name: 'autoOPR') final double Auto,
      @JsonKey(name: 'teleopOPR') final double Teleop,
      @JsonKey(name: 'towerOPR') final double Tower,
      final double? AverageAutoFuel,
      final double? AverageTeleopFuel,
      final double? AverageTotalFuel,
      final double DeathRate,
      final double DefenseRate,
      final int DefenseCount,
      final int MatchesPlayed,
      final int ScoutEntries,
      final int ScoutedMatches}) = _$TeamStatImpl;
  const _TeamStat._() : super._();

  factory _TeamStat.fromJson(Map<String, dynamic> json) =
      _$TeamStatImpl.fromJson;

  @override
  int get Team; // A team may temporarily have no rank before rankings exist.
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
  @override
  double? get AverageAutoFuel;
  @override
  double? get AverageTeleopFuel;
  @override
  double? get AverageTotalFuel;
  @override
  double get DeathRate;
  @override
  double get DefenseRate;
  @override
  int get DefenseCount;
  @override
  int get MatchesPlayed;
  @override
  int get ScoutEntries;
  @override
  int get ScoutedMatches;

  /// Create a copy of TeamStat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamStatImplCopyWith<_$TeamStatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
