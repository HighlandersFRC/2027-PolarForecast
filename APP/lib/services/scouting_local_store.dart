import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum LocalReportStatus { saved, uploading, uploaded, unconfirmed }

class LocalScoutReport {
  final String id;
  final Map<String, dynamic> report;
  final Map<String, dynamic> recording;
  final LocalReportStatus status;
  final DateTime savedAt;
  const LocalScoutReport(
      {required this.id,
      required this.report,
      required this.recording,
      required this.status,
      required this.savedAt});
  Map<String, dynamic> toJson() => {
        'id': id,
        'report': report,
        'recording': recording,
        'status': status.name,
        'savedAt': savedAt.toUtc().toIso8601String()
      };
  factory LocalScoutReport.fromJson(Map<String, dynamic> json) =>
      LocalScoutReport(
          id: json['id'] as String,
          report: Map<String, dynamic>.from(json['report'] as Map),
          recording: Map<String, dynamic>.from(json['recording'] as Map),
          status: LocalReportStatus.values.byName(json['status'] as String),
          savedAt: DateTime.parse(json['savedAt'] as String));
}

/// Local only. No tokens, silent upload retries, or server schema changes.
/// Storage writes are serialized so an older autosave cannot resurrect a draft.
class ScoutingLocalStore {
  final Future<SharedPreferences> Function() preferences;
  ScoutingLocalStore({Future<SharedPreferences> Function()? preferences})
      : preferences = preferences ?? SharedPreferences.getInstance;
  static Future<void>? _writes;
  String _key(String scope, String kind) =>
      'polarforecast.scouting.v1.$kind.${Uri.encodeComponent(scope)}';

  Future<void> _write(Future<void> Function() action) {
    final next = (_writes ?? Future<void>.value()).then((_) => action());
    final settled = next.catchError((Object _) {});
    _writes = settled;
    settled.then((_) {
      if (identical(_writes, settled)) _writes = null;
    });
    return next;
  }

  Future<Map<String, dynamic>?> readDraft(String scope) async {
    if (_writes != null) await _writes;
    final raw = (await preferences()).getString(_key(scope, 'draft'));
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveDraft(String scope, Map<String, dynamic> draft) {
    final encoded = jsonEncode(draft);
    return _write(() async {
      if (!await (await preferences()).setString(_key(scope, 'draft'), encoded))
        throw StateError('Device could not save the draft');
    });
  }

  Future<void> clearDraft(String scope) => _write(() async {
        if (!await (await preferences()).remove(_key(scope, 'draft')))
          throw StateError('Device could not clear the draft');
      });

  Future<List<LocalScoutReport>> history(String scope) async {
    if (_writes != null) await _writes;
    return _history(await preferences(), scope);
  }

  List<LocalScoutReport> _history(SharedPreferences prefs, String scope) {
    final raw = prefs.getString(_key(scope, 'history'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((value) =>
            LocalScoutReport.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
  }

  Future<void> saveReport(String scope, LocalScoutReport entry) {
    // Snapshot before waiting on any prior write.
    final snapshot = LocalScoutReport.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>);
    return _write(() async {
      final prefs = await preferences();
      final entries = _history(prefs, scope);
      final previous = entries.where((e) => e.id == snapshot.id).firstOrNull;
      if (previous?.status == LocalReportStatus.uploaded) return;
      final saved = previous != null &&
              previous.status != LocalReportStatus.saved &&
              snapshot.status == LocalReportStatus.saved
          ? LocalScoutReport(
              id: snapshot.id,
              report: snapshot.report,
              recording: snapshot.recording,
              status: previous.status,
              savedAt: snapshot.savedAt)
          : snapshot;
      final next = [saved, ...entries.where((e) => e.id != snapshot.id)];
      if (!await prefs.setString(_key(scope, 'history'),
          jsonEncode(next.map((e) => e.toJson()).toList())))
        throw StateError('Device could not save the report');
    });
  }

  Future<void> status(String scope, String id, LocalReportStatus status) =>
      _write(() async {
        final prefs = await preferences();
        final entries = _history(prefs, scope);
        if (!entries.any((entry) => entry.id == id))
          throw StateError('Local report not found');
        final next = entries.map((entry) => entry.id == id
            ? LocalScoutReport(
                id: entry.id,
                report: entry.report,
                recording: entry.recording,
                status: status,
                savedAt: entry.savedAt)
            : entry);
        if (!await prefs.setString(_key(scope, 'history'),
            jsonEncode(next.map((entry) => entry.toJson()).toList())))
          throw StateError('Device could not update upload status');
      });
}
