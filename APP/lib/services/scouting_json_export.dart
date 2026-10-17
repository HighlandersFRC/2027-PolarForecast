import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'scouting_local_store.dart';

Future<void> downloadScoutingJson(
    String name, Map<String, dynamic> document) async {
  await FileSaver.instance.saveFile(
    name: name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_'),
    bytes: Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(document))),
    fileExtension: 'json',
    mimeType: MimeType.json,
  );
}

Future<void> downloadScoutReportJson(LocalScoutReport entry) =>
    downloadScoutingJson(
      'polarforecast_${entry.report['event']}_match-${entry.report['match']}_team-${entry.report['team']}_${entry.id}',
      {'format': 'polarforecast.match-scouting.v1', ...entry.toJson()},
    );
