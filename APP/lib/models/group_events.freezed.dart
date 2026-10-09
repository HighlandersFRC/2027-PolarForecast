// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GroupEvents _$GroupEventsFromJson(Map<String, dynamic> json) {
  return _GroupEvents.fromJson(json);
}

/// @nodoc
mixin _$GroupEvents {
  List<String> get events => throw _privateConstructorUsedError;

  /// Serializes this GroupEvents to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupEvents
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupEventsCopyWith<GroupEvents> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupEventsCopyWith<$Res> {
  factory $GroupEventsCopyWith(
          GroupEvents value, $Res Function(GroupEvents) then) =
      _$GroupEventsCopyWithImpl<$Res, GroupEvents>;
  @useResult
  $Res call({List<String> events});
}

/// @nodoc
class _$GroupEventsCopyWithImpl<$Res, $Val extends GroupEvents>
    implements $GroupEventsCopyWith<$Res> {
  _$GroupEventsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupEvents
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? events = null,
  }) {
    return _then(_value.copyWith(
      events: null == events
          ? _value.events
          : events // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupEventsImplCopyWith<$Res>
    implements $GroupEventsCopyWith<$Res> {
  factory _$$GroupEventsImplCopyWith(
          _$GroupEventsImpl value, $Res Function(_$GroupEventsImpl) then) =
      __$$GroupEventsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> events});
}

/// @nodoc
class __$$GroupEventsImplCopyWithImpl<$Res>
    extends _$GroupEventsCopyWithImpl<$Res, _$GroupEventsImpl>
    implements _$$GroupEventsImplCopyWith<$Res> {
  __$$GroupEventsImplCopyWithImpl(
      _$GroupEventsImpl _value, $Res Function(_$GroupEventsImpl) _then)
      : super(_value, _then);

  /// Create a copy of GroupEvents
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? events = null,
  }) {
    return _then(_$GroupEventsImpl(
      events: null == events
          ? _value._events
          : events // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupEventsImpl implements _GroupEvents {
  const _$GroupEventsImpl({required final List<String> events})
      : _events = events;

  factory _$GroupEventsImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupEventsImplFromJson(json);

  final List<String> _events;
  @override
  List<String> get events {
    if (_events is EqualUnmodifiableListView) return _events;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_events);
  }

  @override
  String toString() {
    return 'GroupEvents(events: $events)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupEventsImpl &&
            const DeepCollectionEquality().equals(other._events, _events));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_events));

  /// Create a copy of GroupEvents
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupEventsImplCopyWith<_$GroupEventsImpl> get copyWith =>
      __$$GroupEventsImplCopyWithImpl<_$GroupEventsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupEventsImplToJson(
      this,
    );
  }
}

abstract class _GroupEvents implements GroupEvents {
  const factory _GroupEvents({required final List<String> events}) =
      _$GroupEventsImpl;

  factory _GroupEvents.fromJson(Map<String, dynamic> json) =
      _$GroupEventsImpl.fromJson;

  @override
  List<String> get events;

  /// Create a copy of GroupEvents
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupEventsImplCopyWith<_$GroupEventsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
