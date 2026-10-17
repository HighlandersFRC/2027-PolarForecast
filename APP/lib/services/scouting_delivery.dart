import 'dart:convert';
import 'scouting_local_store.dart';

class ScoutingDeliveryResult {
  final bool uploaded;
  final bool jsonDownloaded;
  final bool deviceSaved;
  final Object? uploadError;
  final Object? jsonError;
  const ScoutingDeliveryResult(
      {required this.uploaded,
      required this.deviceSaved,
      this.jsonDownloaded = false,
      this.uploadError,
      this.jsonError});
  bool get completed => uploaded || jsonDownloaded;
  String get message => uploaded
      ? 'Uploaded to the cloud.'
      : jsonDownloaded
          ? 'Cloud upload not confirmed. JSON backup download started.'
          : deviceSaved
              ? 'Upload and JSON download failed. Device copy retained; keep this draft open.'
              : 'Upload and JSON download failed. Keep this draft open and try Download JSON again.';
}

/// A storage failure must never prevent the cloud attempt, and a local status
/// failure after HTTP success must never trigger a duplicate upload or fallback.
class ScoutingDelivery {
  final ScoutingLocalStore store;
  final Future<void> Function(Map<String, dynamic>) upload;
  final Future<void> Function(LocalScoutReport) downloadJson;
  final Duration uploadTimeout;
  const ScoutingDelivery(
      {required this.store,
      required this.upload,
      required this.downloadJson,
      this.uploadTimeout = const Duration(seconds: 20)});

  Future<bool> _attempt(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ScoutingDeliveryResult> submit(
      String scope, LocalScoutReport entry) async {
    if (entry.status == LocalReportStatus.uploaded) {
      return const ScoutingDeliveryResult(uploaded: true, deviceSaved: true);
    }
    final snapshot = LocalScoutReport.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>);
    final saved = await _attempt(() => store.saveReport(scope, snapshot));
    if (saved)
      await _attempt(
          () => store.status(scope, entry.id, LocalReportStatus.uploading));
    Object? uploadError;
    try {
      await upload(snapshot.report).timeout(uploadTimeout);
    } catch (error) {
      uploadError = error;
    }
    if (uploadError == null) {
      if (saved)
        await _attempt(
            () => store.status(scope, entry.id, LocalReportStatus.uploaded));
      return ScoutingDeliveryResult(uploaded: true, deviceSaved: saved);
    }
    if (saved)
      await _attempt(
          () => store.status(scope, entry.id, LocalReportStatus.unconfirmed));
    final backup = LocalScoutReport(
        id: snapshot.id,
        report: snapshot.report,
        recording: snapshot.recording,
        status: LocalReportStatus.unconfirmed,
        savedAt: snapshot.savedAt);
    try {
      await downloadJson(backup);
      return ScoutingDeliveryResult(
          uploaded: false,
          deviceSaved: saved,
          jsonDownloaded: true,
          uploadError: uploadError);
    } catch (error) {
      return ScoutingDeliveryResult(
          uploaded: false,
          deviceSaved: saved,
          uploadError: uploadError,
          jsonError: error);
    }
  }
}
