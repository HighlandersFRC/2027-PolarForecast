// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_up.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FollowUp _$FollowUpFromJson(Map<String, dynamic> json) {
  return _FollowUp.fromJson(json);
}

/// @nodoc
mixin _$FollowUp {
  String get event => throw _privateConstructorUsedError;
  String get match => throw _privateConstructorUsedError;
  int get team => throw _privateConstructorUsedError;
  @JsonKey(name: 'scout_info')
  ScoutInfo get scoutInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'groupID')
  String get groupId => throw _privateConstructorUsedError;
  FollowUpData get data => throw _privateConstructorUsedError;

  /// Serializes this FollowUp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowUp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowUpCopyWith<FollowUp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowUpCopyWith<$Res> {
  factory $FollowUpCopyWith(FollowUp value, $Res Function(FollowUp) then) =
      _$FollowUpCopyWithImpl<$Res, FollowUp>;
  @useResult
  $Res call(
      {String event,
      String match,
      int team,
      @JsonKey(name: 'scout_info') ScoutInfo scoutInfo,
      @JsonKey(name: 'groupID') String groupId,
      FollowUpData data});

  $ScoutInfoCopyWith<$Res> get scoutInfo;
  $FollowUpDataCopyWith<$Res> get data;
}

/// @nodoc
class _$FollowUpCopyWithImpl<$Res, $Val extends FollowUp>
    implements $FollowUpCopyWith<$Res> {
  _$FollowUpCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowUp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
    Object? match = null,
    Object? team = null,
    Object? scoutInfo = null,
    Object? groupId = null,
    Object? data = null,
  }) {
    return _then(_value.copyWith(
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as String,
      match: null == match
          ? _value.match
          : match // ignore: cast_nullable_to_non_nullable
              as String,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as int,
      scoutInfo: null == scoutInfo
          ? _value.scoutInfo
          : scoutInfo // ignore: cast_nullable_to_non_nullable
              as ScoutInfo,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as FollowUpData,
    ) as $Val);
  }

  /// Create a copy of FollowUp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoutInfoCopyWith<$Res> get scoutInfo {
    return $ScoutInfoCopyWith<$Res>(_value.scoutInfo, (value) {
      return _then(_value.copyWith(scoutInfo: value) as $Val);
    });
  }

  /// Create a copy of FollowUp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FollowUpDataCopyWith<$Res> get data {
    return $FollowUpDataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FollowUpImplCopyWith<$Res>
    implements $FollowUpCopyWith<$Res> {
  factory _$$FollowUpImplCopyWith(
          _$FollowUpImpl value, $Res Function(_$FollowUpImpl) then) =
      __$$FollowUpImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String event,
      String match,
      int team,
      @JsonKey(name: 'scout_info') ScoutInfo scoutInfo,
      @JsonKey(name: 'groupID') String groupId,
      FollowUpData data});

  @override
  $ScoutInfoCopyWith<$Res> get scoutInfo;
  @override
  $FollowUpDataCopyWith<$Res> get data;
}

/// @nodoc
class __$$FollowUpImplCopyWithImpl<$Res>
    extends _$FollowUpCopyWithImpl<$Res, _$FollowUpImpl>
    implements _$$FollowUpImplCopyWith<$Res> {
  __$$FollowUpImplCopyWithImpl(
      _$FollowUpImpl _value, $Res Function(_$FollowUpImpl) _then)
      : super(_value, _then);

  /// Create a copy of FollowUp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
    Object? match = null,
    Object? team = null,
    Object? scoutInfo = null,
    Object? groupId = null,
    Object? data = null,
  }) {
    return _then(_$FollowUpImpl(
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as String,
      match: null == match
          ? _value.match
          : match // ignore: cast_nullable_to_non_nullable
              as String,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as int,
      scoutInfo: null == scoutInfo
          ? _value.scoutInfo
          : scoutInfo // ignore: cast_nullable_to_non_nullable
              as ScoutInfo,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as FollowUpData,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowUpImpl implements _FollowUp {
  const _$FollowUpImpl(
      {required this.event,
      required this.match,
      required this.team,
      @JsonKey(name: 'scout_info') required this.scoutInfo,
      @JsonKey(name: 'groupID') required this.groupId,
      required this.data});

  factory _$FollowUpImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowUpImplFromJson(json);

  @override
  final String event;
  @override
  final String match;
  @override
  final int team;
  @override
  @JsonKey(name: 'scout_info')
  final ScoutInfo scoutInfo;
  @override
  @JsonKey(name: 'groupID')
  final String groupId;
  @override
  final FollowUpData data;

  @override
  String toString() {
    return 'FollowUp(event: $event, match: $match, team: $team, scoutInfo: $scoutInfo, groupId: $groupId, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowUpImpl &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.match, match) || other.match == match) &&
            (identical(other.team, team) || other.team == team) &&
            (identical(other.scoutInfo, scoutInfo) ||
                other.scoutInfo == scoutInfo) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, event, match, team, scoutInfo, groupId, data);

  /// Create a copy of FollowUp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowUpImplCopyWith<_$FollowUpImpl> get copyWith =>
      __$$FollowUpImplCopyWithImpl<_$FollowUpImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowUpImplToJson(
      this,
    );
  }
}

abstract class _FollowUp implements FollowUp {
  const factory _FollowUp(
      {required final String event,
      required final String match,
      required final int team,
      @JsonKey(name: 'scout_info') required final ScoutInfo scoutInfo,
      @JsonKey(name: 'groupID') required final String groupId,
      required final FollowUpData data}) = _$FollowUpImpl;

  factory _FollowUp.fromJson(Map<String, dynamic> json) =
      _$FollowUpImpl.fromJson;

  @override
  String get event;
  @override
  String get match;
  @override
  int get team;
  @override
  @JsonKey(name: 'scout_info')
  ScoutInfo get scoutInfo;
  @override
  @JsonKey(name: 'groupID')
  String get groupId;
  @override
  FollowUpData get data;

  /// Create a copy of FollowUp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowUpImplCopyWith<_$FollowUpImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FollowUpData _$FollowUpDataFromJson(Map<String, dynamic> json) {
  return _FollowUpData.fromJson(json);
}

/// @nodoc
mixin _$FollowUpData {
  String get severity => throw _privateConstructorUsedError;
  String get comments => throw _privateConstructorUsedError;

  /// Serializes this FollowUpData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowUpData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowUpDataCopyWith<FollowUpData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowUpDataCopyWith<$Res> {
  factory $FollowUpDataCopyWith(
          FollowUpData value, $Res Function(FollowUpData) then) =
      _$FollowUpDataCopyWithImpl<$Res, FollowUpData>;
  @useResult
  $Res call({String severity, String comments});
}

/// @nodoc
class _$FollowUpDataCopyWithImpl<$Res, $Val extends FollowUpData>
    implements $FollowUpDataCopyWith<$Res> {
  _$FollowUpDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowUpData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? severity = null,
    Object? comments = null,
  }) {
    return _then(_value.copyWith(
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FollowUpDataImplCopyWith<$Res>
    implements $FollowUpDataCopyWith<$Res> {
  factory _$$FollowUpDataImplCopyWith(
          _$FollowUpDataImpl value, $Res Function(_$FollowUpDataImpl) then) =
      __$$FollowUpDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String severity, String comments});
}

/// @nodoc
class __$$FollowUpDataImplCopyWithImpl<$Res>
    extends _$FollowUpDataCopyWithImpl<$Res, _$FollowUpDataImpl>
    implements _$$FollowUpDataImplCopyWith<$Res> {
  __$$FollowUpDataImplCopyWithImpl(
      _$FollowUpDataImpl _value, $Res Function(_$FollowUpDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of FollowUpData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? severity = null,
    Object? comments = null,
  }) {
    return _then(_$FollowUpDataImpl(
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
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
class _$FollowUpDataImpl implements _FollowUpData {
  const _$FollowUpDataImpl({required this.severity, required this.comments});

  factory _$FollowUpDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowUpDataImplFromJson(json);

  @override
  final String severity;
  @override
  final String comments;

  @override
  String toString() {
    return 'FollowUpData(severity: $severity, comments: $comments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowUpDataImpl &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.comments, comments) ||
                other.comments == comments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, severity, comments);

  /// Create a copy of FollowUpData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowUpDataImplCopyWith<_$FollowUpDataImpl> get copyWith =>
      __$$FollowUpDataImplCopyWithImpl<_$FollowUpDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowUpDataImplToJson(
      this,
    );
  }
}

abstract class _FollowUpData implements FollowUpData {
  const factory _FollowUpData(
      {required final String severity,
      required final String comments}) = _$FollowUpDataImpl;

  factory _FollowUpData.fromJson(Map<String, dynamic> json) =
      _$FollowUpDataImpl.fromJson;

  @override
  String get severity;
  @override
  String get comments;

  /// Create a copy of FollowUpData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowUpDataImplCopyWith<_$FollowUpDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FollowUpIncident _$FollowUpIncidentFromJson(Map<String, dynamic> json) {
  return _FollowUpIncident.fromJson(json);
}

/// @nodoc
mixin _$FollowUpIncident {
  @JsonKey(name: 'incident_id')
  String get incidentId => throw _privateConstructorUsedError;
  String get event => throw _privateConstructorUsedError;
  int get team => throw _privateConstructorUsedError;
  String get match => throw _privateConstructorUsedError;
  @JsonKey(name: 'match_key')
  String get matchKey => throw _privateConstructorUsedError;
  bool get resolved => throw _privateConstructorUsedError;
  @JsonKey(name: 'report_count')
  int get reportCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'death_reports')
  List<DeathReport> get deathReports => throw _privateConstructorUsedError;
  FollowUpResolution? get followup => throw _privateConstructorUsedError;

  /// Serializes this FollowUpIncident to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowUpIncident
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowUpIncidentCopyWith<FollowUpIncident> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowUpIncidentCopyWith<$Res> {
  factory $FollowUpIncidentCopyWith(
          FollowUpIncident value, $Res Function(FollowUpIncident) then) =
      _$FollowUpIncidentCopyWithImpl<$Res, FollowUpIncident>;
  @useResult
  $Res call(
      {@JsonKey(name: 'incident_id') String incidentId,
      String event,
      int team,
      String match,
      @JsonKey(name: 'match_key') String matchKey,
      bool resolved,
      @JsonKey(name: 'report_count') int reportCount,
      @JsonKey(name: 'death_reports') List<DeathReport> deathReports,
      FollowUpResolution? followup});

  $FollowUpResolutionCopyWith<$Res>? get followup;
}

/// @nodoc
class _$FollowUpIncidentCopyWithImpl<$Res, $Val extends FollowUpIncident>
    implements $FollowUpIncidentCopyWith<$Res> {
  _$FollowUpIncidentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowUpIncident
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? incidentId = null,
    Object? event = null,
    Object? team = null,
    Object? match = null,
    Object? matchKey = null,
    Object? resolved = null,
    Object? reportCount = null,
    Object? deathReports = null,
    Object? followup = freezed,
  }) {
    return _then(_value.copyWith(
      incidentId: null == incidentId
          ? _value.incidentId
          : incidentId // ignore: cast_nullable_to_non_nullable
              as String,
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as String,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as int,
      match: null == match
          ? _value.match
          : match // ignore: cast_nullable_to_non_nullable
              as String,
      matchKey: null == matchKey
          ? _value.matchKey
          : matchKey // ignore: cast_nullable_to_non_nullable
              as String,
      resolved: null == resolved
          ? _value.resolved
          : resolved // ignore: cast_nullable_to_non_nullable
              as bool,
      reportCount: null == reportCount
          ? _value.reportCount
          : reportCount // ignore: cast_nullable_to_non_nullable
              as int,
      deathReports: null == deathReports
          ? _value.deathReports
          : deathReports // ignore: cast_nullable_to_non_nullable
              as List<DeathReport>,
      followup: freezed == followup
          ? _value.followup
          : followup // ignore: cast_nullable_to_non_nullable
              as FollowUpResolution?,
    ) as $Val);
  }

  /// Create a copy of FollowUpIncident
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FollowUpResolutionCopyWith<$Res>? get followup {
    if (_value.followup == null) {
      return null;
    }

    return $FollowUpResolutionCopyWith<$Res>(_value.followup!, (value) {
      return _then(_value.copyWith(followup: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FollowUpIncidentImplCopyWith<$Res>
    implements $FollowUpIncidentCopyWith<$Res> {
  factory _$$FollowUpIncidentImplCopyWith(_$FollowUpIncidentImpl value,
          $Res Function(_$FollowUpIncidentImpl) then) =
      __$$FollowUpIncidentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'incident_id') String incidentId,
      String event,
      int team,
      String match,
      @JsonKey(name: 'match_key') String matchKey,
      bool resolved,
      @JsonKey(name: 'report_count') int reportCount,
      @JsonKey(name: 'death_reports') List<DeathReport> deathReports,
      FollowUpResolution? followup});

  @override
  $FollowUpResolutionCopyWith<$Res>? get followup;
}

/// @nodoc
class __$$FollowUpIncidentImplCopyWithImpl<$Res>
    extends _$FollowUpIncidentCopyWithImpl<$Res, _$FollowUpIncidentImpl>
    implements _$$FollowUpIncidentImplCopyWith<$Res> {
  __$$FollowUpIncidentImplCopyWithImpl(_$FollowUpIncidentImpl _value,
      $Res Function(_$FollowUpIncidentImpl) _then)
      : super(_value, _then);

  /// Create a copy of FollowUpIncident
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? incidentId = null,
    Object? event = null,
    Object? team = null,
    Object? match = null,
    Object? matchKey = null,
    Object? resolved = null,
    Object? reportCount = null,
    Object? deathReports = null,
    Object? followup = freezed,
  }) {
    return _then(_$FollowUpIncidentImpl(
      incidentId: null == incidentId
          ? _value.incidentId
          : incidentId // ignore: cast_nullable_to_non_nullable
              as String,
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as String,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as int,
      match: null == match
          ? _value.match
          : match // ignore: cast_nullable_to_non_nullable
              as String,
      matchKey: null == matchKey
          ? _value.matchKey
          : matchKey // ignore: cast_nullable_to_non_nullable
              as String,
      resolved: null == resolved
          ? _value.resolved
          : resolved // ignore: cast_nullable_to_non_nullable
              as bool,
      reportCount: null == reportCount
          ? _value.reportCount
          : reportCount // ignore: cast_nullable_to_non_nullable
              as int,
      deathReports: null == deathReports
          ? _value._deathReports
          : deathReports // ignore: cast_nullable_to_non_nullable
              as List<DeathReport>,
      followup: freezed == followup
          ? _value.followup
          : followup // ignore: cast_nullable_to_non_nullable
              as FollowUpResolution?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowUpIncidentImpl implements _FollowUpIncident {
  const _$FollowUpIncidentImpl(
      {@JsonKey(name: 'incident_id') required this.incidentId,
      required this.event,
      required this.team,
      required this.match,
      @JsonKey(name: 'match_key') required this.matchKey,
      required this.resolved,
      @JsonKey(name: 'report_count') required this.reportCount,
      @JsonKey(name: 'death_reports')
      final List<DeathReport> deathReports = const <DeathReport>[],
      this.followup})
      : _deathReports = deathReports;

  factory _$FollowUpIncidentImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowUpIncidentImplFromJson(json);

  @override
  @JsonKey(name: 'incident_id')
  final String incidentId;
  @override
  final String event;
  @override
  final int team;
  @override
  final String match;
  @override
  @JsonKey(name: 'match_key')
  final String matchKey;
  @override
  final bool resolved;
  @override
  @JsonKey(name: 'report_count')
  final int reportCount;
  final List<DeathReport> _deathReports;
  @override
  @JsonKey(name: 'death_reports')
  List<DeathReport> get deathReports {
    if (_deathReports is EqualUnmodifiableListView) return _deathReports;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deathReports);
  }

  @override
  final FollowUpResolution? followup;

  @override
  String toString() {
    return 'FollowUpIncident(incidentId: $incidentId, event: $event, team: $team, match: $match, matchKey: $matchKey, resolved: $resolved, reportCount: $reportCount, deathReports: $deathReports, followup: $followup)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowUpIncidentImpl &&
            (identical(other.incidentId, incidentId) ||
                other.incidentId == incidentId) &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.team, team) || other.team == team) &&
            (identical(other.match, match) || other.match == match) &&
            (identical(other.matchKey, matchKey) ||
                other.matchKey == matchKey) &&
            (identical(other.resolved, resolved) ||
                other.resolved == resolved) &&
            (identical(other.reportCount, reportCount) ||
                other.reportCount == reportCount) &&
            const DeepCollectionEquality()
                .equals(other._deathReports, _deathReports) &&
            (identical(other.followup, followup) ||
                other.followup == followup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      incidentId,
      event,
      team,
      match,
      matchKey,
      resolved,
      reportCount,
      const DeepCollectionEquality().hash(_deathReports),
      followup);

  /// Create a copy of FollowUpIncident
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowUpIncidentImplCopyWith<_$FollowUpIncidentImpl> get copyWith =>
      __$$FollowUpIncidentImplCopyWithImpl<_$FollowUpIncidentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowUpIncidentImplToJson(
      this,
    );
  }
}

abstract class _FollowUpIncident implements FollowUpIncident {
  const factory _FollowUpIncident(
      {@JsonKey(name: 'incident_id') required final String incidentId,
      required final String event,
      required final int team,
      required final String match,
      @JsonKey(name: 'match_key') required final String matchKey,
      required final bool resolved,
      @JsonKey(name: 'report_count') required final int reportCount,
      @JsonKey(name: 'death_reports') final List<DeathReport> deathReports,
      final FollowUpResolution? followup}) = _$FollowUpIncidentImpl;

  factory _FollowUpIncident.fromJson(Map<String, dynamic> json) =
      _$FollowUpIncidentImpl.fromJson;

  @override
  @JsonKey(name: 'incident_id')
  String get incidentId;
  @override
  String get event;
  @override
  int get team;
  @override
  String get match;
  @override
  @JsonKey(name: 'match_key')
  String get matchKey;
  @override
  bool get resolved;
  @override
  @JsonKey(name: 'report_count')
  int get reportCount;
  @override
  @JsonKey(name: 'death_reports')
  List<DeathReport> get deathReports;
  @override
  FollowUpResolution? get followup;

  /// Create a copy of FollowUpIncident
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowUpIncidentImplCopyWith<_$FollowUpIncidentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeathReport _$DeathReportFromJson(Map<String, dynamic> json) {
  return _DeathReport.fromJson(json);
}

/// @nodoc
mixin _$DeathReport {
  String get comments => throw _privateConstructorUsedError;
  @JsonKey(name: 'scout_name')
  String get scoutName => throw _privateConstructorUsedError;
  @JsonKey(name: 'scout_username')
  String get scoutUsername => throw _privateConstructorUsedError;
  @JsonKey(name: 'submitted_at')
  String? get submittedAt => throw _privateConstructorUsedError;

  /// Serializes this DeathReport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeathReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeathReportCopyWith<DeathReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeathReportCopyWith<$Res> {
  factory $DeathReportCopyWith(
          DeathReport value, $Res Function(DeathReport) then) =
      _$DeathReportCopyWithImpl<$Res, DeathReport>;
  @useResult
  $Res call(
      {String comments,
      @JsonKey(name: 'scout_name') String scoutName,
      @JsonKey(name: 'scout_username') String scoutUsername,
      @JsonKey(name: 'submitted_at') String? submittedAt});
}

/// @nodoc
class _$DeathReportCopyWithImpl<$Res, $Val extends DeathReport>
    implements $DeathReportCopyWith<$Res> {
  _$DeathReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeathReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? comments = null,
    Object? scoutName = null,
    Object? scoutUsername = null,
    Object? submittedAt = freezed,
  }) {
    return _then(_value.copyWith(
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
      scoutName: null == scoutName
          ? _value.scoutName
          : scoutName // ignore: cast_nullable_to_non_nullable
              as String,
      scoutUsername: null == scoutUsername
          ? _value.scoutUsername
          : scoutUsername // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeathReportImplCopyWith<$Res>
    implements $DeathReportCopyWith<$Res> {
  factory _$$DeathReportImplCopyWith(
          _$DeathReportImpl value, $Res Function(_$DeathReportImpl) then) =
      __$$DeathReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String comments,
      @JsonKey(name: 'scout_name') String scoutName,
      @JsonKey(name: 'scout_username') String scoutUsername,
      @JsonKey(name: 'submitted_at') String? submittedAt});
}

/// @nodoc
class __$$DeathReportImplCopyWithImpl<$Res>
    extends _$DeathReportCopyWithImpl<$Res, _$DeathReportImpl>
    implements _$$DeathReportImplCopyWith<$Res> {
  __$$DeathReportImplCopyWithImpl(
      _$DeathReportImpl _value, $Res Function(_$DeathReportImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeathReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? comments = null,
    Object? scoutName = null,
    Object? scoutUsername = null,
    Object? submittedAt = freezed,
  }) {
    return _then(_$DeathReportImpl(
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
      scoutName: null == scoutName
          ? _value.scoutName
          : scoutName // ignore: cast_nullable_to_non_nullable
              as String,
      scoutUsername: null == scoutUsername
          ? _value.scoutUsername
          : scoutUsername // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeathReportImpl implements _DeathReport {
  const _$DeathReportImpl(
      {this.comments = '',
      @JsonKey(name: 'scout_name') this.scoutName = 'Unknown',
      @JsonKey(name: 'scout_username') this.scoutUsername = '',
      @JsonKey(name: 'submitted_at') this.submittedAt});

  factory _$DeathReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeathReportImplFromJson(json);

  @override
  @JsonKey()
  final String comments;
  @override
  @JsonKey(name: 'scout_name')
  final String scoutName;
  @override
  @JsonKey(name: 'scout_username')
  final String scoutUsername;
  @override
  @JsonKey(name: 'submitted_at')
  final String? submittedAt;

  @override
  String toString() {
    return 'DeathReport(comments: $comments, scoutName: $scoutName, scoutUsername: $scoutUsername, submittedAt: $submittedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeathReportImpl &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.scoutName, scoutName) ||
                other.scoutName == scoutName) &&
            (identical(other.scoutUsername, scoutUsername) ||
                other.scoutUsername == scoutUsername) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, comments, scoutName, scoutUsername, submittedAt);

  /// Create a copy of DeathReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeathReportImplCopyWith<_$DeathReportImpl> get copyWith =>
      __$$DeathReportImplCopyWithImpl<_$DeathReportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeathReportImplToJson(
      this,
    );
  }
}

abstract class _DeathReport implements DeathReport {
  const factory _DeathReport(
          {final String comments,
          @JsonKey(name: 'scout_name') final String scoutName,
          @JsonKey(name: 'scout_username') final String scoutUsername,
          @JsonKey(name: 'submitted_at') final String? submittedAt}) =
      _$DeathReportImpl;

  factory _DeathReport.fromJson(Map<String, dynamic> json) =
      _$DeathReportImpl.fromJson;

  @override
  String get comments;
  @override
  @JsonKey(name: 'scout_name')
  String get scoutName;
  @override
  @JsonKey(name: 'scout_username')
  String get scoutUsername;
  @override
  @JsonKey(name: 'submitted_at')
  String? get submittedAt;

  /// Create a copy of DeathReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeathReportImplCopyWith<_$DeathReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FollowUpResolution _$FollowUpResolutionFromJson(Map<String, dynamic> json) {
  return _FollowUpResolution.fromJson(json);
}

/// @nodoc
mixin _$FollowUpResolution {
  String get severity => throw _privateConstructorUsedError;
  String get comments => throw _privateConstructorUsedError;
  @JsonKey(name: 'scout_name')
  String get scoutName => throw _privateConstructorUsedError;
  @JsonKey(name: 'submitted_at')
  String? get submittedAt => throw _privateConstructorUsedError;

  /// Serializes this FollowUpResolution to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowUpResolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowUpResolutionCopyWith<FollowUpResolution> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowUpResolutionCopyWith<$Res> {
  factory $FollowUpResolutionCopyWith(
          FollowUpResolution value, $Res Function(FollowUpResolution) then) =
      _$FollowUpResolutionCopyWithImpl<$Res, FollowUpResolution>;
  @useResult
  $Res call(
      {String severity,
      String comments,
      @JsonKey(name: 'scout_name') String scoutName,
      @JsonKey(name: 'submitted_at') String? submittedAt});
}

/// @nodoc
class _$FollowUpResolutionCopyWithImpl<$Res, $Val extends FollowUpResolution>
    implements $FollowUpResolutionCopyWith<$Res> {
  _$FollowUpResolutionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowUpResolution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? severity = null,
    Object? comments = null,
    Object? scoutName = null,
    Object? submittedAt = freezed,
  }) {
    return _then(_value.copyWith(
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
      scoutName: null == scoutName
          ? _value.scoutName
          : scoutName // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FollowUpResolutionImplCopyWith<$Res>
    implements $FollowUpResolutionCopyWith<$Res> {
  factory _$$FollowUpResolutionImplCopyWith(_$FollowUpResolutionImpl value,
          $Res Function(_$FollowUpResolutionImpl) then) =
      __$$FollowUpResolutionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String severity,
      String comments,
      @JsonKey(name: 'scout_name') String scoutName,
      @JsonKey(name: 'submitted_at') String? submittedAt});
}

/// @nodoc
class __$$FollowUpResolutionImplCopyWithImpl<$Res>
    extends _$FollowUpResolutionCopyWithImpl<$Res, _$FollowUpResolutionImpl>
    implements _$$FollowUpResolutionImplCopyWith<$Res> {
  __$$FollowUpResolutionImplCopyWithImpl(_$FollowUpResolutionImpl _value,
      $Res Function(_$FollowUpResolutionImpl) _then)
      : super(_value, _then);

  /// Create a copy of FollowUpResolution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? severity = null,
    Object? comments = null,
    Object? scoutName = null,
    Object? submittedAt = freezed,
  }) {
    return _then(_$FollowUpResolutionImpl(
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
      scoutName: null == scoutName
          ? _value.scoutName
          : scoutName // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowUpResolutionImpl implements _FollowUpResolution {
  const _$FollowUpResolutionImpl(
      {this.severity = '',
      this.comments = '',
      @JsonKey(name: 'scout_name') this.scoutName = 'Unknown',
      @JsonKey(name: 'submitted_at') this.submittedAt});

  factory _$FollowUpResolutionImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowUpResolutionImplFromJson(json);

  @override
  @JsonKey()
  final String severity;
  @override
  @JsonKey()
  final String comments;
  @override
  @JsonKey(name: 'scout_name')
  final String scoutName;
  @override
  @JsonKey(name: 'submitted_at')
  final String? submittedAt;

  @override
  String toString() {
    return 'FollowUpResolution(severity: $severity, comments: $comments, scoutName: $scoutName, submittedAt: $submittedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowUpResolutionImpl &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.scoutName, scoutName) ||
                other.scoutName == scoutName) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, severity, comments, scoutName, submittedAt);

  /// Create a copy of FollowUpResolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowUpResolutionImplCopyWith<_$FollowUpResolutionImpl> get copyWith =>
      __$$FollowUpResolutionImplCopyWithImpl<_$FollowUpResolutionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowUpResolutionImplToJson(
      this,
    );
  }
}

abstract class _FollowUpResolution implements FollowUpResolution {
  const factory _FollowUpResolution(
          {final String severity,
          final String comments,
          @JsonKey(name: 'scout_name') final String scoutName,
          @JsonKey(name: 'submitted_at') final String? submittedAt}) =
      _$FollowUpResolutionImpl;

  factory _FollowUpResolution.fromJson(Map<String, dynamic> json) =
      _$FollowUpResolutionImpl.fromJson;

  @override
  String get severity;
  @override
  String get comments;
  @override
  @JsonKey(name: 'scout_name')
  String get scoutName;
  @override
  @JsonKey(name: 'submitted_at')
  String? get submittedAt;

  /// Create a copy of FollowUpResolution
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowUpResolutionImplCopyWith<_$FollowUpResolutionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
