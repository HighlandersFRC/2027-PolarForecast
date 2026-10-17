import 'package:shared_preferences/shared_preferences.dart';

/// Device-local navigation history; no account or server changes.
abstract final class RecentEvents {
  static const _key = 'polarforecast.recent-events';

  static Future<List<String>> load() async {
    try {
      return (await SharedPreferences.getInstance()).getStringList(_key) ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> remember(String event) async {
    try {
      final recent = await load();
      await (await SharedPreferences.getInstance()).setStringList(_key,
          [event, ...recent.where((key) => key != event)].take(5).toList());
    } catch (_) {
      // Navigation works even when browser storage is unavailable.
    }
  }
}
