import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_events.freezed.dart';
part 'group_events.g.dart';

@freezed
class GroupEvents with _$GroupEvents {
  const factory GroupEvents({
    required List<String> events,
  }) = _GroupEvents;

  factory GroupEvents.fromJson(Map<String, dynamic> json) =>
      _$GroupEventsFromJson(json);
}
