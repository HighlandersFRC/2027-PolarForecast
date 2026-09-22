// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '2026Pitscouting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PitScouting2026 _$PitScouting2026FromJson(Map<String, dynamic> json) {
  return _PitScouting2026.fromJson(json);
}

/// @nodoc
mixin _$PitScouting2026 {
  String get event => throw _privateConstructorUsedError;
  int get team => throw _privateConstructorUsedError;
  Data get data => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  ScoutInfo get scoutInfo => throw _privateConstructorUsedError;

  /// Serializes this PitScouting2026 to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PitScouting2026
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PitScouting2026CopyWith<PitScouting2026> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PitScouting2026CopyWith<$Res> {
  factory $PitScouting2026CopyWith(
          PitScouting2026 value, $Res Function(PitScouting2026) then) =
      _$PitScouting2026CopyWithImpl<$Res, PitScouting2026>;
  @useResult
  $Res call(
      {String event,
      int team,
      Data data,
      String? groupId,
      ScoutInfo scoutInfo});

  $DataCopyWith<$Res> get data;
  $ScoutInfoCopyWith<$Res> get scoutInfo;
}

/// @nodoc
class _$PitScouting2026CopyWithImpl<$Res, $Val extends PitScouting2026>
    implements $PitScouting2026CopyWith<$Res> {
  _$PitScouting2026CopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PitScouting2026
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
    Object? team = null,
    Object? data = null,
    Object? groupId = freezed,
    Object? scoutInfo = null,
  }) {
    return _then(_value.copyWith(
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as String,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as int,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Data,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      scoutInfo: null == scoutInfo
          ? _value.scoutInfo
          : scoutInfo // ignore: cast_nullable_to_non_nullable
              as ScoutInfo,
    ) as $Val);
  }

  /// Create a copy of PitScouting2026
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataCopyWith<$Res> get data {
    return $DataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }

  /// Create a copy of PitScouting2026
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoutInfoCopyWith<$Res> get scoutInfo {
    return $ScoutInfoCopyWith<$Res>(_value.scoutInfo, (value) {
      return _then(_value.copyWith(scoutInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PitScouting2026ImplCopyWith<$Res>
    implements $PitScouting2026CopyWith<$Res> {
  factory _$$PitScouting2026ImplCopyWith(_$PitScouting2026Impl value,
          $Res Function(_$PitScouting2026Impl) then) =
      __$$PitScouting2026ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String event,
      int team,
      Data data,
      String? groupId,
      ScoutInfo scoutInfo});

  @override
  $DataCopyWith<$Res> get data;
  @override
  $ScoutInfoCopyWith<$Res> get scoutInfo;
}

/// @nodoc
class __$$PitScouting2026ImplCopyWithImpl<$Res>
    extends _$PitScouting2026CopyWithImpl<$Res, _$PitScouting2026Impl>
    implements _$$PitScouting2026ImplCopyWith<$Res> {
  __$$PitScouting2026ImplCopyWithImpl(
      _$PitScouting2026Impl _value, $Res Function(_$PitScouting2026Impl) _then)
      : super(_value, _then);

  /// Create a copy of PitScouting2026
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
    Object? team = null,
    Object? data = null,
    Object? groupId = freezed,
    Object? scoutInfo = null,
  }) {
    return _then(_$PitScouting2026Impl(
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as String,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as int,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Data,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      scoutInfo: null == scoutInfo
          ? _value.scoutInfo
          : scoutInfo // ignore: cast_nullable_to_non_nullable
              as ScoutInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PitScouting2026Impl implements _PitScouting2026 {
  const _$PitScouting2026Impl(
      {required this.event,
      required this.team,
      required this.data,
      this.groupId,
      required this.scoutInfo});

  factory _$PitScouting2026Impl.fromJson(Map<String, dynamic> json) =>
      _$$PitScouting2026ImplFromJson(json);

  @override
  final String event;
  @override
  final int team;
  @override
  final Data data;
  @override
  final String? groupId;
  @override
  final ScoutInfo scoutInfo;

  @override
  String toString() {
    return 'PitScouting2026(event: $event, team: $team, data: $data, groupId: $groupId, scoutInfo: $scoutInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PitScouting2026Impl &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.team, team) || other.team == team) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.scoutInfo, scoutInfo) ||
                other.scoutInfo == scoutInfo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, event, team, data, groupId, scoutInfo);

  /// Create a copy of PitScouting2026
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PitScouting2026ImplCopyWith<_$PitScouting2026Impl> get copyWith =>
      __$$PitScouting2026ImplCopyWithImpl<_$PitScouting2026Impl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PitScouting2026ImplToJson(
      this,
    );
  }
}

abstract class _PitScouting2026 implements PitScouting2026 {
  const factory _PitScouting2026(
      {required final String event,
      required final int team,
      required final Data data,
      final String? groupId,
      required final ScoutInfo scoutInfo}) = _$PitScouting2026Impl;

  factory _PitScouting2026.fromJson(Map<String, dynamic> json) =
      _$PitScouting2026Impl.fromJson;

  @override
  String get event;
  @override
  int get team;
  @override
  Data get data;
  @override
  String? get groupId;
  @override
  ScoutInfo get scoutInfo;

  /// Create a copy of PitScouting2026
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PitScouting2026ImplCopyWith<_$PitScouting2026Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

Data _$DataFromJson(Map<String, dynamic> json) {
  return _Data.fromJson(json);
}

/// @nodoc
mixin _$Data {
  bool get trench => throw _privateConstructorUsedError;
  bool get bump => throw _privateConstructorUsedError;
  String get shooter_type => throw _privateConstructorUsedError;
  String get climb => throw _privateConstructorUsedError;
  double get bps => throw _privateConstructorUsedError; // DATA VALIDATION
  Auto get autos => throw _privateConstructorUsedError;
  int get driver_events => throw _privateConstructorUsedError;
  String get favorite_robot_part => throw _privateConstructorUsedError;
  String get drive_train => throw _privateConstructorUsedError;
  String get comments => throw _privateConstructorUsedError;

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataCopyWith<Data> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataCopyWith<$Res> {
  factory $DataCopyWith(Data value, $Res Function(Data) then) =
      _$DataCopyWithImpl<$Res, Data>;
  @useResult
  $Res call(
      {bool trench,
      bool bump,
      String shooter_type,
      String climb,
      double bps,
      Auto autos,
      int driver_events,
      String favorite_robot_part,
      String drive_train,
      String comments});

  $AutoCopyWith<$Res> get autos;
}

/// @nodoc
class _$DataCopyWithImpl<$Res, $Val extends Data>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trench = null,
    Object? bump = null,
    Object? shooter_type = null,
    Object? climb = null,
    Object? bps = null,
    Object? autos = null,
    Object? driver_events = null,
    Object? favorite_robot_part = null,
    Object? drive_train = null,
    Object? comments = null,
  }) {
    return _then(_value.copyWith(
      trench: null == trench
          ? _value.trench
          : trench // ignore: cast_nullable_to_non_nullable
              as bool,
      bump: null == bump
          ? _value.bump
          : bump // ignore: cast_nullable_to_non_nullable
              as bool,
      shooter_type: null == shooter_type
          ? _value.shooter_type
          : shooter_type // ignore: cast_nullable_to_non_nullable
              as String,
      climb: null == climb
          ? _value.climb
          : climb // ignore: cast_nullable_to_non_nullable
              as String,
      bps: null == bps
          ? _value.bps
          : bps // ignore: cast_nullable_to_non_nullable
              as double,
      autos: null == autos
          ? _value.autos
          : autos // ignore: cast_nullable_to_non_nullable
              as Auto,
      driver_events: null == driver_events
          ? _value.driver_events
          : driver_events // ignore: cast_nullable_to_non_nullable
              as int,
      favorite_robot_part: null == favorite_robot_part
          ? _value.favorite_robot_part
          : favorite_robot_part // ignore: cast_nullable_to_non_nullable
              as String,
      drive_train: null == drive_train
          ? _value.drive_train
          : drive_train // ignore: cast_nullable_to_non_nullable
              as String,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AutoCopyWith<$Res> get autos {
    return $AutoCopyWith<$Res>(_value.autos, (value) {
      return _then(_value.copyWith(autos: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DataImplCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$$DataImplCopyWith(
          _$DataImpl value, $Res Function(_$DataImpl) then) =
      __$$DataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool trench,
      bool bump,
      String shooter_type,
      String climb,
      double bps,
      Auto autos,
      int driver_events,
      String favorite_robot_part,
      String drive_train,
      String comments});

  @override
  $AutoCopyWith<$Res> get autos;
}

/// @nodoc
class __$$DataImplCopyWithImpl<$Res>
    extends _$DataCopyWithImpl<$Res, _$DataImpl>
    implements _$$DataImplCopyWith<$Res> {
  __$$DataImplCopyWithImpl(_$DataImpl _value, $Res Function(_$DataImpl) _then)
      : super(_value, _then);

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trench = null,
    Object? bump = null,
    Object? shooter_type = null,
    Object? climb = null,
    Object? bps = null,
    Object? autos = null,
    Object? driver_events = null,
    Object? favorite_robot_part = null,
    Object? drive_train = null,
    Object? comments = null,
  }) {
    return _then(_$DataImpl(
      trench: null == trench
          ? _value.trench
          : trench // ignore: cast_nullable_to_non_nullable
              as bool,
      bump: null == bump
          ? _value.bump
          : bump // ignore: cast_nullable_to_non_nullable
              as bool,
      shooter_type: null == shooter_type
          ? _value.shooter_type
          : shooter_type // ignore: cast_nullable_to_non_nullable
              as String,
      climb: null == climb
          ? _value.climb
          : climb // ignore: cast_nullable_to_non_nullable
              as String,
      bps: null == bps
          ? _value.bps
          : bps // ignore: cast_nullable_to_non_nullable
              as double,
      autos: null == autos
          ? _value.autos
          : autos // ignore: cast_nullable_to_non_nullable
              as Auto,
      driver_events: null == driver_events
          ? _value.driver_events
          : driver_events // ignore: cast_nullable_to_non_nullable
              as int,
      favorite_robot_part: null == favorite_robot_part
          ? _value.favorite_robot_part
          : favorite_robot_part // ignore: cast_nullable_to_non_nullable
              as String,
      drive_train: null == drive_train
          ? _value.drive_train
          : drive_train // ignore: cast_nullable_to_non_nullable
              as String,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DataImpl implements _Data {
  const _$DataImpl(
      {required this.trench,
      required this.bump,
      required this.shooter_type,
      required this.climb,
      required this.bps,
      required this.autos,
      required this.driver_events,
      required this.favorite_robot_part,
      required this.drive_train,
      required this.comments});

  factory _$DataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataImplFromJson(json);

  @override
  final bool trench;
  @override
  final bool bump;
  @override
  final String shooter_type;
  @override
  final String climb;
  @override
  final double bps;
// DATA VALIDATION
  @override
  final Auto autos;
  @override
  final int driver_events;
  @override
  final String favorite_robot_part;
  @override
  final String drive_train;
  @override
  final String comments;

  @override
  String toString() {
    return 'Data(trench: $trench, bump: $bump, shooter_type: $shooter_type, climb: $climb, bps: $bps, autos: $autos, driver_events: $driver_events, favorite_robot_part: $favorite_robot_part, drive_train: $drive_train, comments: $comments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
            (identical(other.trench, trench) || other.trench == trench) &&
            (identical(other.bump, bump) || other.bump == bump) &&
            (identical(other.shooter_type, shooter_type) ||
                other.shooter_type == shooter_type) &&
            (identical(other.climb, climb) || other.climb == climb) &&
            (identical(other.bps, bps) || other.bps == bps) &&
            (identical(other.autos, autos) || other.autos == autos) &&
            (identical(other.driver_events, driver_events) ||
                other.driver_events == driver_events) &&
            (identical(other.favorite_robot_part, favorite_robot_part) ||
                other.favorite_robot_part == favorite_robot_part) &&
            (identical(other.drive_train, drive_train) ||
                other.drive_train == drive_train) &&
            (identical(other.comments, comments) ||
                other.comments == comments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      trench,
      bump,
      shooter_type,
      climb,
      bps,
      autos,
      driver_events,
      favorite_robot_part,
      drive_train,
      comments);

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      __$$DataImplCopyWithImpl<_$DataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DataImplToJson(
      this,
    );
  }
}

abstract class _Data implements Data {
  const factory _Data(
      {required final bool trench,
      required final bool bump,
      required final String shooter_type,
      required final String climb,
      required final double bps,
      required final Auto autos,
      required final int driver_events,
      required final String favorite_robot_part,
      required final String drive_train,
      required final String comments}) = _$DataImpl;

  factory _Data.fromJson(Map<String, dynamic> json) = _$DataImpl.fromJson;

  @override
  bool get trench;
  @override
  bool get bump;
  @override
  String get shooter_type;
  @override
  String get climb;
  @override
  double get bps; // DATA VALIDATION
  @override
  Auto get autos;
  @override
  int get driver_events;
  @override
  String get favorite_robot_part;
  @override
  String get drive_train;
  @override
  String get comments;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AutoPathPit _$AutoPathPitFromJson(Map<String, dynamic> json) {
  return _AutoPathPit.fromJson(json);
}

/// @nodoc
mixin _$AutoPathPit {
  List<PitAutoRoutine> get auto_paths => throw _privateConstructorUsedError;

  /// Serializes this AutoPathPit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AutoPathPit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AutoPathPitCopyWith<AutoPathPit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AutoPathPitCopyWith<$Res> {
  factory $AutoPathPitCopyWith(
          AutoPathPit value, $Res Function(AutoPathPit) then) =
      _$AutoPathPitCopyWithImpl<$Res, AutoPathPit>;
  @useResult
  $Res call({List<PitAutoRoutine> auto_paths});
}

/// @nodoc
class _$AutoPathPitCopyWithImpl<$Res, $Val extends AutoPathPit>
    implements $AutoPathPitCopyWith<$Res> {
  _$AutoPathPitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AutoPathPit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? auto_paths = null,
  }) {
    return _then(_value.copyWith(
      auto_paths: null == auto_paths
          ? _value.auto_paths
          : auto_paths // ignore: cast_nullable_to_non_nullable
              as List<PitAutoRoutine>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AutoPathPitImplCopyWith<$Res>
    implements $AutoPathPitCopyWith<$Res> {
  factory _$$AutoPathPitImplCopyWith(
          _$AutoPathPitImpl value, $Res Function(_$AutoPathPitImpl) then) =
      __$$AutoPathPitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PitAutoRoutine> auto_paths});
}

/// @nodoc
class __$$AutoPathPitImplCopyWithImpl<$Res>
    extends _$AutoPathPitCopyWithImpl<$Res, _$AutoPathPitImpl>
    implements _$$AutoPathPitImplCopyWith<$Res> {
  __$$AutoPathPitImplCopyWithImpl(
      _$AutoPathPitImpl _value, $Res Function(_$AutoPathPitImpl) _then)
      : super(_value, _then);

  /// Create a copy of AutoPathPit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? auto_paths = null,
  }) {
    return _then(_$AutoPathPitImpl(
      auto_paths: null == auto_paths
          ? _value._auto_paths
          : auto_paths // ignore: cast_nullable_to_non_nullable
              as List<PitAutoRoutine>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AutoPathPitImpl implements _AutoPathPit {
  const _$AutoPathPitImpl(
      {final List<PitAutoRoutine> auto_paths = const <PitAutoRoutine>[]})
      : _auto_paths = auto_paths;

  factory _$AutoPathPitImpl.fromJson(Map<String, dynamic> json) =>
      _$$AutoPathPitImplFromJson(json);

  final List<PitAutoRoutine> _auto_paths;
  @override
  @JsonKey()
  List<PitAutoRoutine> get auto_paths {
    if (_auto_paths is EqualUnmodifiableListView) return _auto_paths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_auto_paths);
  }

  @override
  String toString() {
    return 'AutoPathPit(auto_paths: $auto_paths)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AutoPathPitImpl &&
            const DeepCollectionEquality()
                .equals(other._auto_paths, _auto_paths));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_auto_paths));

  /// Create a copy of AutoPathPit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AutoPathPitImplCopyWith<_$AutoPathPitImpl> get copyWith =>
      __$$AutoPathPitImplCopyWithImpl<_$AutoPathPitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AutoPathPitImplToJson(
      this,
    );
  }
}

abstract class _AutoPathPit implements AutoPathPit {
  const factory _AutoPathPit({final List<PitAutoRoutine> auto_paths}) =
      _$AutoPathPitImpl;

  factory _AutoPathPit.fromJson(Map<String, dynamic> json) =
      _$AutoPathPitImpl.fromJson;

  @override
  List<PitAutoRoutine> get auto_paths;

  /// Create a copy of AutoPathPit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AutoPathPitImplCopyWith<_$AutoPathPitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PitAutoRoutine _$PitAutoRoutineFromJson(Map<String, dynamic> json) {
  return _PitAutoRoutine.fromJson(json);
}

/// @nodoc
mixin _$PitAutoRoutine {
  String get name => throw _privateConstructorUsedError;
  List<String> get path => throw _privateConstructorUsedError;

  /// Serializes this PitAutoRoutine to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PitAutoRoutine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PitAutoRoutineCopyWith<PitAutoRoutine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PitAutoRoutineCopyWith<$Res> {
  factory $PitAutoRoutineCopyWith(
          PitAutoRoutine value, $Res Function(PitAutoRoutine) then) =
      _$PitAutoRoutineCopyWithImpl<$Res, PitAutoRoutine>;
  @useResult
  $Res call({String name, List<String> path});
}

/// @nodoc
class _$PitAutoRoutineCopyWithImpl<$Res, $Val extends PitAutoRoutine>
    implements $PitAutoRoutineCopyWith<$Res> {
  _$PitAutoRoutineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PitAutoRoutine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PitAutoRoutineImplCopyWith<$Res>
    implements $PitAutoRoutineCopyWith<$Res> {
  factory _$$PitAutoRoutineImplCopyWith(_$PitAutoRoutineImpl value,
          $Res Function(_$PitAutoRoutineImpl) then) =
      __$$PitAutoRoutineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, List<String> path});
}

/// @nodoc
class __$$PitAutoRoutineImplCopyWithImpl<$Res>
    extends _$PitAutoRoutineCopyWithImpl<$Res, _$PitAutoRoutineImpl>
    implements _$$PitAutoRoutineImplCopyWith<$Res> {
  __$$PitAutoRoutineImplCopyWithImpl(
      _$PitAutoRoutineImpl _value, $Res Function(_$PitAutoRoutineImpl) _then)
      : super(_value, _then);

  /// Create a copy of PitAutoRoutine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
  }) {
    return _then(_$PitAutoRoutineImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value._path
          : path // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PitAutoRoutineImpl implements _PitAutoRoutine {
  const _$PitAutoRoutineImpl(
      {required this.name, final List<String> path = const <String>[]})
      : _path = path;

  factory _$PitAutoRoutineImpl.fromJson(Map<String, dynamic> json) =>
      _$$PitAutoRoutineImplFromJson(json);

  @override
  final String name;
  final List<String> _path;
  @override
  @JsonKey()
  List<String> get path {
    if (_path is EqualUnmodifiableListView) return _path;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_path);
  }

  @override
  String toString() {
    return 'PitAutoRoutine(name: $name, path: $path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PitAutoRoutineImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._path, _path));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, const DeepCollectionEquality().hash(_path));

  /// Create a copy of PitAutoRoutine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PitAutoRoutineImplCopyWith<_$PitAutoRoutineImpl> get copyWith =>
      __$$PitAutoRoutineImplCopyWithImpl<_$PitAutoRoutineImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PitAutoRoutineImplToJson(
      this,
    );
  }
}

abstract class _PitAutoRoutine implements PitAutoRoutine {
  const factory _PitAutoRoutine(
      {required final String name,
      final List<String> path}) = _$PitAutoRoutineImpl;

  factory _PitAutoRoutine.fromJson(Map<String, dynamic> json) =
      _$PitAutoRoutineImpl.fromJson;

  @override
  String get name;
  @override
  List<String> get path;

  /// Create a copy of PitAutoRoutine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PitAutoRoutineImplCopyWith<_$PitAutoRoutineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Auto _$AutoFromJson(Map<String, dynamic> json) {
  return _Auto.fromJson(json);
}

/// @nodoc
mixin _$Auto {
  AutoPathPit get autos => throw _privateConstructorUsedError;

  /// Serializes this Auto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Auto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AutoCopyWith<Auto> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AutoCopyWith<$Res> {
  factory $AutoCopyWith(Auto value, $Res Function(Auto) then) =
      _$AutoCopyWithImpl<$Res, Auto>;
  @useResult
  $Res call({AutoPathPit autos});

  $AutoPathPitCopyWith<$Res> get autos;
}

/// @nodoc
class _$AutoCopyWithImpl<$Res, $Val extends Auto>
    implements $AutoCopyWith<$Res> {
  _$AutoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Auto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? autos = null,
  }) {
    return _then(_value.copyWith(
      autos: null == autos
          ? _value.autos
          : autos // ignore: cast_nullable_to_non_nullable
              as AutoPathPit,
    ) as $Val);
  }

  /// Create a copy of Auto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AutoPathPitCopyWith<$Res> get autos {
    return $AutoPathPitCopyWith<$Res>(_value.autos, (value) {
      return _then(_value.copyWith(autos: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AutoImplCopyWith<$Res> implements $AutoCopyWith<$Res> {
  factory _$$AutoImplCopyWith(
          _$AutoImpl value, $Res Function(_$AutoImpl) then) =
      __$$AutoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({AutoPathPit autos});

  @override
  $AutoPathPitCopyWith<$Res> get autos;
}

/// @nodoc
class __$$AutoImplCopyWithImpl<$Res>
    extends _$AutoCopyWithImpl<$Res, _$AutoImpl>
    implements _$$AutoImplCopyWith<$Res> {
  __$$AutoImplCopyWithImpl(_$AutoImpl _value, $Res Function(_$AutoImpl) _then)
      : super(_value, _then);

  /// Create a copy of Auto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? autos = null,
  }) {
    return _then(_$AutoImpl(
      autos: null == autos
          ? _value.autos
          : autos // ignore: cast_nullable_to_non_nullable
              as AutoPathPit,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AutoImpl implements _Auto {
  const _$AutoImpl({required this.autos});

  factory _$AutoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AutoImplFromJson(json);

  @override
  final AutoPathPit autos;

  @override
  String toString() {
    return 'Auto(autos: $autos)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AutoImpl &&
            (identical(other.autos, autos) || other.autos == autos));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, autos);

  /// Create a copy of Auto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AutoImplCopyWith<_$AutoImpl> get copyWith =>
      __$$AutoImplCopyWithImpl<_$AutoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AutoImplToJson(
      this,
    );
  }
}

abstract class _Auto implements Auto {
  const factory _Auto({required final AutoPathPit autos}) = _$AutoImpl;

  factory _Auto.fromJson(Map<String, dynamic> json) = _$AutoImpl.fromJson;

  @override
  AutoPathPit get autos;

  /// Create a copy of Auto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AutoImplCopyWith<_$AutoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
