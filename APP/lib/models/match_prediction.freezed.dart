// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_prediction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MatchPrediction _$MatchPredictionFromJson(Map<String, dynamic> json) {
  return _MatchPrediction.fromJson(json);
}

/// @nodoc
mixin _$MatchPrediction {
  String get key => throw _privateConstructorUsedError;
  double get red_score => throw _privateConstructorUsedError;
  double get blue_score => throw _privateConstructorUsedError;
  List<int> get red_teams => throw _privateConstructorUsedError;
  List<int> get blue_teams => throw _privateConstructorUsedError;
  double get confidence_percentage => throw _privateConstructorUsedError;
  String get confidence_label => throw _privateConstructorUsedError;
  double get red_win_probability => throw _privateConstructorUsedError;
  double get blue_win_probability => throw _privateConstructorUsedError;

  /// Serializes this MatchPrediction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchPrediction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchPredictionCopyWith<MatchPrediction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchPredictionCopyWith<$Res> {
  factory $MatchPredictionCopyWith(
          MatchPrediction value, $Res Function(MatchPrediction) then) =
      _$MatchPredictionCopyWithImpl<$Res, MatchPrediction>;
  @useResult
  $Res call(
      {String key,
      double red_score,
      double blue_score,
      List<int> red_teams,
      List<int> blue_teams,
      double confidence_percentage,
      String confidence_label,
      double red_win_probability,
      double blue_win_probability});
}

/// @nodoc
class _$MatchPredictionCopyWithImpl<$Res, $Val extends MatchPrediction>
    implements $MatchPredictionCopyWith<$Res> {
  _$MatchPredictionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchPrediction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? red_score = null,
    Object? blue_score = null,
    Object? red_teams = null,
    Object? blue_teams = null,
    Object? confidence_percentage = null,
    Object? confidence_label = null,
    Object? red_win_probability = null,
    Object? blue_win_probability = null,
  }) {
    return _then(_value.copyWith(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      red_score: null == red_score
          ? _value.red_score
          : red_score // ignore: cast_nullable_to_non_nullable
              as double,
      blue_score: null == blue_score
          ? _value.blue_score
          : blue_score // ignore: cast_nullable_to_non_nullable
              as double,
      red_teams: null == red_teams
          ? _value.red_teams
          : red_teams // ignore: cast_nullable_to_non_nullable
              as List<int>,
      blue_teams: null == blue_teams
          ? _value.blue_teams
          : blue_teams // ignore: cast_nullable_to_non_nullable
              as List<int>,
      confidence_percentage: null == confidence_percentage
          ? _value.confidence_percentage
          : confidence_percentage // ignore: cast_nullable_to_non_nullable
              as double,
      confidence_label: null == confidence_label
          ? _value.confidence_label
          : confidence_label // ignore: cast_nullable_to_non_nullable
              as String,
      red_win_probability: null == red_win_probability
          ? _value.red_win_probability
          : red_win_probability // ignore: cast_nullable_to_non_nullable
              as double,
      blue_win_probability: null == blue_win_probability
          ? _value.blue_win_probability
          : blue_win_probability // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchPredictionImplCopyWith<$Res>
    implements $MatchPredictionCopyWith<$Res> {
  factory _$$MatchPredictionImplCopyWith(_$MatchPredictionImpl value,
          $Res Function(_$MatchPredictionImpl) then) =
      __$$MatchPredictionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String key,
      double red_score,
      double blue_score,
      List<int> red_teams,
      List<int> blue_teams,
      double confidence_percentage,
      String confidence_label,
      double red_win_probability,
      double blue_win_probability});
}

/// @nodoc
class __$$MatchPredictionImplCopyWithImpl<$Res>
    extends _$MatchPredictionCopyWithImpl<$Res, _$MatchPredictionImpl>
    implements _$$MatchPredictionImplCopyWith<$Res> {
  __$$MatchPredictionImplCopyWithImpl(
      _$MatchPredictionImpl _value, $Res Function(_$MatchPredictionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MatchPrediction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? red_score = null,
    Object? blue_score = null,
    Object? red_teams = null,
    Object? blue_teams = null,
    Object? confidence_percentage = null,
    Object? confidence_label = null,
    Object? red_win_probability = null,
    Object? blue_win_probability = null,
  }) {
    return _then(_$MatchPredictionImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      red_score: null == red_score
          ? _value.red_score
          : red_score // ignore: cast_nullable_to_non_nullable
              as double,
      blue_score: null == blue_score
          ? _value.blue_score
          : blue_score // ignore: cast_nullable_to_non_nullable
              as double,
      red_teams: null == red_teams
          ? _value._red_teams
          : red_teams // ignore: cast_nullable_to_non_nullable
              as List<int>,
      blue_teams: null == blue_teams
          ? _value._blue_teams
          : blue_teams // ignore: cast_nullable_to_non_nullable
              as List<int>,
      confidence_percentage: null == confidence_percentage
          ? _value.confidence_percentage
          : confidence_percentage // ignore: cast_nullable_to_non_nullable
              as double,
      confidence_label: null == confidence_label
          ? _value.confidence_label
          : confidence_label // ignore: cast_nullable_to_non_nullable
              as String,
      red_win_probability: null == red_win_probability
          ? _value.red_win_probability
          : red_win_probability // ignore: cast_nullable_to_non_nullable
              as double,
      blue_win_probability: null == blue_win_probability
          ? _value.blue_win_probability
          : blue_win_probability // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchPredictionImpl implements _MatchPrediction {
  const _$MatchPredictionImpl(
      {required this.key,
      required this.red_score,
      required this.blue_score,
      required final List<int> red_teams,
      required final List<int> blue_teams,
      required this.confidence_percentage,
      required this.confidence_label,
      required this.red_win_probability,
      required this.blue_win_probability})
      : _red_teams = red_teams,
        _blue_teams = blue_teams;

  factory _$MatchPredictionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchPredictionImplFromJson(json);

  @override
  final String key;
  @override
  final double red_score;
  @override
  final double blue_score;
  final List<int> _red_teams;
  @override
  List<int> get red_teams {
    if (_red_teams is EqualUnmodifiableListView) return _red_teams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_red_teams);
  }

  final List<int> _blue_teams;
  @override
  List<int> get blue_teams {
    if (_blue_teams is EqualUnmodifiableListView) return _blue_teams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_blue_teams);
  }

  @override
  final double confidence_percentage;
  @override
  final String confidence_label;
  @override
  final double red_win_probability;
  @override
  final double blue_win_probability;

  @override
  String toString() {
    return 'MatchPrediction(key: $key, red_score: $red_score, blue_score: $blue_score, red_teams: $red_teams, blue_teams: $blue_teams, confidence_percentage: $confidence_percentage, confidence_label: $confidence_label, red_win_probability: $red_win_probability, blue_win_probability: $blue_win_probability)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchPredictionImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.red_score, red_score) ||
                other.red_score == red_score) &&
            (identical(other.blue_score, blue_score) ||
                other.blue_score == blue_score) &&
            const DeepCollectionEquality()
                .equals(other._red_teams, _red_teams) &&
            const DeepCollectionEquality()
                .equals(other._blue_teams, _blue_teams) &&
            (identical(other.confidence_percentage, confidence_percentage) ||
                other.confidence_percentage == confidence_percentage) &&
            (identical(other.confidence_label, confidence_label) ||
                other.confidence_label == confidence_label) &&
            (identical(other.red_win_probability, red_win_probability) ||
                other.red_win_probability == red_win_probability) &&
            (identical(other.blue_win_probability, blue_win_probability) ||
                other.blue_win_probability == blue_win_probability));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      key,
      red_score,
      blue_score,
      const DeepCollectionEquality().hash(_red_teams),
      const DeepCollectionEquality().hash(_blue_teams),
      confidence_percentage,
      confidence_label,
      red_win_probability,
      blue_win_probability);

  /// Create a copy of MatchPrediction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchPredictionImplCopyWith<_$MatchPredictionImpl> get copyWith =>
      __$$MatchPredictionImplCopyWithImpl<_$MatchPredictionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchPredictionImplToJson(
      this,
    );
  }
}

abstract class _MatchPrediction implements MatchPrediction {
  const factory _MatchPrediction(
      {required final String key,
      required final double red_score,
      required final double blue_score,
      required final List<int> red_teams,
      required final List<int> blue_teams,
      required final double confidence_percentage,
      required final String confidence_label,
      required final double red_win_probability,
      required final double blue_win_probability}) = _$MatchPredictionImpl;

  factory _MatchPrediction.fromJson(Map<String, dynamic> json) =
      _$MatchPredictionImpl.fromJson;

  @override
  String get key;
  @override
  double get red_score;
  @override
  double get blue_score;
  @override
  List<int> get red_teams;
  @override
  List<int> get blue_teams;
  @override
  double get confidence_percentage;
  @override
  String get confidence_label;
  @override
  double get red_win_probability;
  @override
  double get blue_win_probability;

  /// Create a copy of MatchPrediction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchPredictionImplCopyWith<_$MatchPredictionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
