// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EventData _$EventDataFromJson(Map<String, dynamic> json) {
  return _EventData.fromJson(json);
}

/// @nodoc
mixin _$EventData {
  List<TeamStat> get stats => throw _privateConstructorUsedError;
  List<MatchPrediction> get predictions => throw _privateConstructorUsedError;

  /// Serializes this EventData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventDataCopyWith<EventData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventDataCopyWith<$Res> {
  factory $EventDataCopyWith(EventData value, $Res Function(EventData) then) =
      _$EventDataCopyWithImpl<$Res, EventData>;
  @useResult
  $Res call({List<TeamStat> stats, List<MatchPrediction> predictions});
}

/// @nodoc
class _$EventDataCopyWithImpl<$Res, $Val extends EventData>
    implements $EventDataCopyWith<$Res> {
  _$EventDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stats = null,
    Object? predictions = null,
  }) {
    return _then(_value.copyWith(
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as List<TeamStat>,
      predictions: null == predictions
          ? _value.predictions
          : predictions // ignore: cast_nullable_to_non_nullable
              as List<MatchPrediction>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EventDataImplCopyWith<$Res>
    implements $EventDataCopyWith<$Res> {
  factory _$$EventDataImplCopyWith(
          _$EventDataImpl value, $Res Function(_$EventDataImpl) then) =
      __$$EventDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<TeamStat> stats, List<MatchPrediction> predictions});
}

/// @nodoc
class __$$EventDataImplCopyWithImpl<$Res>
    extends _$EventDataCopyWithImpl<$Res, _$EventDataImpl>
    implements _$$EventDataImplCopyWith<$Res> {
  __$$EventDataImplCopyWithImpl(
      _$EventDataImpl _value, $Res Function(_$EventDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stats = null,
    Object? predictions = null,
  }) {
    return _then(_$EventDataImpl(
      stats: null == stats
          ? _value._stats
          : stats // ignore: cast_nullable_to_non_nullable
              as List<TeamStat>,
      predictions: null == predictions
          ? _value._predictions
          : predictions // ignore: cast_nullable_to_non_nullable
              as List<MatchPrediction>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventDataImpl implements _EventData {
  const _$EventDataImpl(
      {required final List<TeamStat> stats,
      required final List<MatchPrediction> predictions})
      : _stats = stats,
        _predictions = predictions;

  factory _$EventDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventDataImplFromJson(json);

  final List<TeamStat> _stats;
  @override
  List<TeamStat> get stats {
    if (_stats is EqualUnmodifiableListView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stats);
  }

  final List<MatchPrediction> _predictions;
  @override
  List<MatchPrediction> get predictions {
    if (_predictions is EqualUnmodifiableListView) return _predictions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_predictions);
  }

  @override
  String toString() {
    return 'EventData(stats: $stats, predictions: $predictions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventDataImpl &&
            const DeepCollectionEquality().equals(other._stats, _stats) &&
            const DeepCollectionEquality()
                .equals(other._predictions, _predictions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_stats),
      const DeepCollectionEquality().hash(_predictions));

  /// Create a copy of EventData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventDataImplCopyWith<_$EventDataImpl> get copyWith =>
      __$$EventDataImplCopyWithImpl<_$EventDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventDataImplToJson(
      this,
    );
  }
}

abstract class _EventData implements EventData {
  const factory _EventData(
      {required final List<TeamStat> stats,
      required final List<MatchPrediction> predictions}) = _$EventDataImpl;

  factory _EventData.fromJson(Map<String, dynamic> json) =
      _$EventDataImpl.fromJson;

  @override
  List<TeamStat> get stats;
  @override
  List<MatchPrediction> get predictions;

  /// Create a copy of EventData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventDataImplCopyWith<_$EventDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
