import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/services/scouting_local_store.dart';
import 'package:app/services/scouting_delivery.dart';
import 'package:app/services/scouting_json_export.dart';
import 'matte_theme.dart';

Future<bool?> confirmScoutingRetry(BuildContext context) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check before retrying'),
        content: const Text(
            'The previous upload may have reached the server. Check this team and match in scouting reports first. Retry only if the report is missing, to avoid a duplicate.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Go back')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Report is missing · retry'))
        ],
      ),
    );

Future<void> showScoutingHistory(
  BuildContext context, {
  required ScoutingLocalStore store,
  required String scope,
  required Future<void> Function(LocalScoutReport) onUpload,
  Future<void> Function(LocalScoutReport)? onDownloadJson,
}) =>
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        builder: (_) => _ScoutingHistory(
            store: store,
            scope: scope,
            onUpload: onUpload,
            downloadJson: onDownloadJson ?? downloadScoutReportJson));

class _ScoutingHistory extends StatefulWidget {
  final ScoutingLocalStore store;
  final String scope;
  final Future<void> Function(LocalScoutReport) downloadJson;
  final Future<void> Function(LocalScoutReport) onUpload;
  const _ScoutingHistory(
      {required this.store,
      required this.scope,
      required this.onUpload,
      required this.downloadJson});
  @override
  State<_ScoutingHistory> createState() => _ScoutingHistoryState();
}

class _ScoutingHistoryState extends State<_ScoutingHistory> {
  List<LocalScoutReport>? _entries;
  String? _error;
  String? _uploading;
  final _confirmed = <String>{};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await widget.store.history(widget.scope);
      if (mounted)
        setState(() {
          _entries = entries;
          _error = null;
        });
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Device history could not be read. Keep the current draft open and export it.');
    }
  }

  Future<void> _upload(LocalScoutReport entry) async {
    if (_uploading != null || entry.status == LocalReportStatus.uploaded)
      return;
    if (entry.status != LocalReportStatus.saved &&
        await confirmScoutingRetry(context) != true) return;
    if (!mounted) return;
    setState(() => _uploading = entry.id);
    try {
      final result = await ScoutingDelivery(
              store: widget.store,
              upload: (_) => widget.onUpload(entry),
              downloadJson: widget.downloadJson)
          .submit(widget.scope, entry);
      if (result.uploaded) _confirmed.add(entry.id);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not complete upload. Your device report is retained.')));
    } finally {
      await _load();
      if (mounted) setState(() => _uploading = null);
    }
  }

  String _status(LocalReportStatus status) => switch (status) {
        LocalReportStatus.saved => 'Saved on device · ready to upload',
        LocalReportStatus.uploaded => 'Upload confirmed',
        LocalReportStatus.uploading ||
        LocalReportStatus.unconfirmed =>
          'Upload unconfirmed · check server before retry',
      };
  Future<void> _copy(LocalScoutReport entry) async {
    await Clipboard.setData(ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(entry.toJson())));
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Report and observation timeline copied as JSON.')));
  }

  Future<void> _download(LocalScoutReport entry) async {
    try {
      await widget.downloadJson(entry);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report JSON download started.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'JSON download failed. Your device copy is retained. You can use Copy JSON.')));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: _uploading == null,
      child: SafeArea(
          child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
              child: Row(children: [
                const Expanded(
                    child: Text('Device report history',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800))),
                IconButton(
                    tooltip: 'Close history',
                    onPressed: _uploading == null
                        ? () => Navigator.pop(context)
                        : null,
                    icon: const Icon(Icons.close_rounded))
              ])),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                  'Reports and detailed timelines are stored in this browser on this device. Clearing site data removes them. Upload saved reports when connected.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          if (_uploading != null) const LinearProgressIndicator(),
          Expanded(
              child: _entries == null
                  ? (_error == null
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox())
                  : _entries!.isEmpty
                      ? const Center(
                          child: Text(
                              'No saved reports for this event and account.'))
                      : ListView.builder(
                          itemCount: _entries!.length,
                          itemBuilder: (context, i) {
                            final entry = _entries![i];
                            final status = _confirmed.contains(entry.id)
                                ? LocalReportStatus.uploaded
                                : entry.status;
                            final data = entry.report['data'] as Map;
                            return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 10),
                                child: MattePanel(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Team ${entry.report['team']} · Match ${entry.report['match']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          Text(_status(status),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: status ==
                                                          LocalReportStatus
                                                              .uploaded
                                                      ? AppColors.secondary
                                                      : const Color(
                                                          0xFFFFD28A))),
                                          const SizedBox(height: 6),
                                          Text(
                                              'Auto ${(data['autoScouting'] as Map)['fuel_scored']} · Teleop ${(data['teleopScouting'] as Map)['fuel_scored']} fuel',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          Wrap(spacing: 8, children: [
                                            TextButton.icon(
                                                onPressed: () =>
                                                    _download(entry),
                                                icon: const Icon(
                                                    Icons.download_rounded,
                                                    size: 18),
                                                label: const Text(
                                                    'Download JSON')),
                                            TextButton.icon(
                                                onPressed: () => _copy(entry),
                                                icon: const Icon(
                                                    Icons.copy_rounded,
                                                    size: 16),
                                                label: const Text('Copy JSON')),
                                            if (status !=
                                                LocalReportStatus.uploaded)
                                              FilledButton.tonalIcon(
                                                  onPressed: _uploading == null
                                                      ? () => _upload(entry)
                                                      : null,
                                                  icon: const Icon(
                                                      Icons
                                                          .cloud_upload_outlined,
                                                      size: 18),
                                                  label: Text(status ==
                                                          LocalReportStatus
                                                              .saved
                                                      ? 'Upload'
                                                      : 'Check & retry')),
                                          ]),
                                        ])));
                          })),
        ]),
      )));
}
