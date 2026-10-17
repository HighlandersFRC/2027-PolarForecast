import 'dart:async';
import 'dart:convert';

import 'package:app/APIService.dart';
import 'package:app/models/2026Matchscouting.dart';
import 'package:app/models/auto_route.dart';
import 'package:app/models/scouting_capture.dart';
import 'package:app/services/scouting_local_store.dart';
import 'package:app/services/scouting_delivery.dart';
import 'package:app/services/scouting_json_export.dart';
import 'package:app/widgets/live_collection_page.dart';
import 'package:app/widgets/auto_field_map.dart';
import 'package:app/widgets/scouting_history_sheet.dart';
import 'package:flutter/services.dart';
import 'package:app/models/scout_info.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchScouting extends StatefulWidget {
  final String event;
  final VoidCallback? onSubmitted;

  const MatchScouting({super.key, required this.event, this.onSubmitted});

  @override
  State<MatchScouting> createState() => _MatchScoutingState();
}

enum StationMode {
  red1,
  red2,
  red3,
  blue1,
  blue2,
  blue3,
}

class _MatchScoutingState extends State<MatchScouting> {
  static const int _maxAutoFuel = 300;
  static const int _maxTeleopFuel = 1000;
  String get eventCode => widget.event;

  final _formKey = GlobalKey<FormState>();
  int _activePhase = 0;
  void _jumpToPhase(int phase) {
    FocusScope.of(context).unfocus();
    setState(() => _activePhase = phase);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  final _matchController = TextEditingController();
  final _commentsController = TextEditingController();
  final _scrollController = ScrollController();
  final _manualTeamController = TextEditingController();
  final _capture = ScoutingCapture();
  final _local = ScoutingLocalStore();
  String? _scope;
  String _reportId = DateTime.now().microsecondsSinceEpoch.toString();
  String _backupStatus = 'Preparing device backup…';
  bool _restoring = false;
  bool _loadingDraft = true;
  bool _unconfirmed = false;
  String? _cloudConfirmedId;
  int _savedRevision = -1;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _capture.addListener(_captureChanged);
    for (final controller in [
      _matchController,
      _commentsController,
      _manualTeamController
    ]) {
      controller.addListener(_scheduleBackup);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    final scope = jsonEncode([eventCode, auth.groupId, auth.username]);
    if (_scope == scope) return;
    _scope = scope;
    _restoreDraft(scope);
  }

  void _captureChanged() {
    if (!mounted || _restoring) return;
    if (_savedRevision == _capture.revision) return;
    setState(() {
      _autoPath = _capture.autoPath;
      _autoFuel = _capture.fuel(CapturePhase.auto);
      _teleopFuel = _capture.fuel(CapturePhase.teleop);
      _defense = _capture.defense;
      _died = _capture.disabled;
    });
    if (_savedRevision != _capture.revision) {
      _savedRevision = _capture.revision;
      _scheduleBackup();
    }
  }

  Map<String, dynamic> get _draft => {
        'id': _reportId,
        'match': _matchController.text,
        'manualTeam': _manualTeamController.text,
        'station': _selectedMode.name,
        'comments': _commentsController.text,
        'red': _redTeams,
        'blue': _blueTeams,
        'capture': _capture.toJson(),
        'unconfirmed': _unconfirmed,
        'cloudConfirmed': _cloudConfirmedId == _reportId,
      };

  void _scheduleBackup() {
    if (_restoring || _loadingDraft || _scope == null) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 200), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (_scope == null) return;
    try {
      await _local.saveDraft(_scope!, _draft);
      if (mounted) setState(() => _backupStatus = 'Draft saved on this device');
    } catch (_) {
      if (mounted)
        setState(() => _backupStatus =
            'Device backup unavailable. Export a copy before leaving.');
    }
  }

  Future<void> _restoreDraft(String scope) async {
    try {
      final draft = await _local.readDraft(scope);
      if (!mounted || _scope != scope) return;
      if (draft != null) {
        final id = draft['id'] as String;
        final mode = StationMode.values.byName(draft['station'] as String);
        final match = draft['match'] as String;
        final manual = draft['manualTeam'] as String? ?? '';
        final comments = draft['comments'] as String;
        final red = List<String>.from(draft['red'] as List);
        final blue = List<String>.from(draft['blue'] as List);
        _restoring = true;
        _capture.restore(Map<String, dynamic>.from(draft['capture'] as Map));
        _reportId = id;
        _selectedMode = mode;
        _matchController.text = match;
        _manualTeamController.text = manual;
        _commentsController.text = comments;
        _redTeams = red;
        _blueTeams = blue;
        _unconfirmed = draft['unconfirmed'] == true;
        _cloudConfirmedId = draft['cloudConfirmed'] == true ? id : null;
      }
      _backupStatus = draft == null
          ? 'Device backup ready'
          : 'Restored draft from this device';
    } catch (_) {
      _backupStatus =
          'Could not restore device backup. Saved reports are available in history.';
    } finally {
      _restoring = false;
      if (mounted && _scope == scope) {
        setState(() => _loadingDraft = false);
        _captureChanged();
      }
    }
  }

  Future<void> _openLive() async {
    if (!_formKey.currentState!.validate() || selectedTeam == null) {
      _jumpToPhase(0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a match and confirm the team first.')));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => LiveCollectionPage(
            capture: _capture,
            team: selectedTeam!,
            match: _matchController.text,
            blue: _isBlueAlliance,
            backupStatus: () => _backupStatus)));
    if (!mounted) return;
    _jumpToPhase(_capture.phase == CapturePhase.review
        ? 3
        : _capture.phase == CapturePhase.teleop
            ? 2
            : 1);
    await _saveDraft();
  }

  Future<void> _history() async {
    if (_scope == null) return;
    await showScoutingHistory(context, store: _local, scope: _scope!,
        onUpload: (entry) async {
      final api = APIService();
      try {
        await api
            .submitMatchScouting(MatchScouting2026.fromJson(entry.report))
            .timeout(const Duration(seconds: 20));
        if (entry.id == _reportId) {
          _cloudConfirmedId = entry.id;
          _unconfirmed = false;
          if (mounted) await _saveDraft();
        }
        if (mounted) widget.onSubmitted?.call();
      } finally {
        api.dispose();
      }
    });
    if (!mounted) return;
    var confirmed = _cloudConfirmedId == _reportId;
    try {
      confirmed = confirmed ||
          (await _local.history(_scope!)).any((entry) =>
              entry.id == _reportId &&
              entry.status == LocalReportStatus.uploaded);
    } catch (_) {
      /* Cloud confirmation remains valid if device storage failed. */
    }
    if (mounted && confirmed)
      await _advanceToNextMatch((int.tryParse(_matchController.text) ?? 0) + 1);
  }

  Future<void> _exportDraft() async {
    try {
      await downloadScoutingJson(
          'polarforecast_${eventCode}_draft_$_reportId', {
        'format': 'polarforecast.scouting-draft.v1',
        'event': eventCode,
        ..._draft,
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft JSON download started.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                const Text('Could not download JSON. The draft is still open.'),
            action: SnackBarAction(
                label: 'Copy JSON',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(
                      text: const JsonEncoder.withIndent('  ')
                          .convert({'event': eventCode, ..._draft})));
                })));
    }
  }

  Future<void> _downloadReport(LocalScoutReport entry) async {
    try {
      await downloadScoutReportJson(LocalScoutReport(
          id: entry.id,
          report: entry.report,
          recording: entry.recording,
          status: LocalReportStatus.unconfirmed,
          savedAt: entry.savedAt));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report JSON download started.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'JSON download failed. Keep this draft open and try again.')));
    }
  }

  Future<void> _advanceToNextMatch(int nextMatch) async {
    _draftTimer?.cancel();
    try {
      await _local.clearDraft(_scope!);
    } catch (_) {/* Saving the next draft can replace the previous one. */}
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _resetForm(nextMatch));
    await _saveDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _scrollController.jumpTo(0);
    });
    if (mounted) unawaited(_loadTeams());
  }

  Future<void> _clearCurrentDraft() async {
    final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Clear the current draft?'),
              content: const Text(
                  'This clears unsaved observations so you can correct the match or team. Reports already saved in device history stay there.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep draft')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear draft'))
              ],
            ));
    if (clear != true || !mounted) return;
    setState(() => _resetForm(int.tryParse(_matchController.text) ?? 1));
    await _saveDraft();
    await _loadTeams();
  }

  int _teamsRequestId = 0;
  Timer? _teamLookupTimer;

  bool _loadingTeams = false;
  bool _submitting = false;

  List<String> _redTeams = [];
  List<String> _blueTeams = [];

  StationMode _selectedMode = StationMode.red1;

  int _autoFuel = 0;
  int _teleopFuel = 0;
  bool _died = false;
  bool _defense = false;

  // --------------------------
  // AUTO FIELD DATA
  // --------------------------
  //
  // Every field button tap adds a string to this list.
  List<String> _autoPath = [];

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_loadingDraft && _scope != null)
      _local.saveDraft(_scope!, _draft).catchError((Object _) {});
    _capture.removeListener(_captureChanged);
    _capture.dispose();
    _manualTeamController.dispose();
    _teamLookupTimer?.cancel();
    _matchController.dispose();
    _commentsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isRedAlliance =>
      _selectedMode == StationMode.red1 ||
      _selectedMode == StationMode.red2 ||
      _selectedMode == StationMode.red3;

  bool get _isBlueAlliance =>
      _selectedMode == StationMode.blue1 ||
      _selectedMode == StationMode.blue2 ||
      _selectedMode == StationMode.blue3;

  Color get _primaryColor {
    if (_isRedAlliance) return Colors.red;
    if (_isBlueAlliance) return Colors.blue;
    return Colors.purple;
  }

  Color _chipColor(StationMode mode, bool selected) {
    if (!selected) return AppColors.surfaceSoft;

    switch (mode) {
      case StationMode.red1:
      case StationMode.red2:
      case StationMode.red3:
        return Colors.red;
      case StationMode.blue1:
      case StationMode.blue2:
      case StationMode.blue3:
        return Colors.blue;
    }
  }

  // --------------------------
  // TEAM LOADING
  // --------------------------

  void _scheduleTeamLookup() {
    _teamLookupTimer?.cancel();
    ++_teamsRequestId;
    final match = int.tryParse(_matchController.text.trim());
    setState(() {
      _redTeams.clear();
      _blueTeams.clear();
      _loadingTeams = match != null && match > 0;
    });
    if (_loadingTeams) {
      _teamLookupTimer = Timer(const Duration(milliseconds: 300), _loadTeams);
    }
  }

  Future<void> _loadTeams() async {
    _teamLookupTimer?.cancel();
    final requestId = ++_teamsRequestId;
    final match = int.tryParse(_matchController.text.trim());

    setState(() {
      _redTeams.clear();
      _blueTeams.clear();
      _loadingTeams = match != null && match > 0;
    });

    if (!_loadingTeams) return;

    final api = APIService();
    try {
      final alliances = await Future.wait([
        api.fetchTeamsPerAllianceRed(eventCode, match!),
        api.fetchTeamsPerAllianceBlue(eventCode, match),
      ]).timeout(const Duration(seconds: 15));

      if (!mounted || requestId != _teamsRequestId) return;

      setState(() {
        _redTeams = List<String>.from(alliances[0]);
        _blueTeams = List<String>.from(alliances[1]);
        _loadingTeams = false;
      });
      _scheduleBackup();
    } catch (e) {
      if (!mounted || requestId != _teamsRequestId) return;
      setState(() => _loadingTeams = false);
      debugPrint(e.toString());
    } finally {
      api.dispose();
    }
  }

  // --------------------------
  // TEAM RESOLUTION
  // --------------------------

  int? get selectedTeam {
    final manual = int.tryParse(_manualTeamController.text.trim());
    if (manual != null && manual > 0) return manual;
    List<String> source;

    switch (_selectedMode) {
      case StationMode.red1:
        source = _redTeams.length > 0 ? [_redTeams[0]] : [];
        break;
      case StationMode.red2:
        source = _redTeams.length > 1 ? [_redTeams[1]] : [];
        break;
      case StationMode.red3:
        source = _redTeams.length > 2 ? [_redTeams[2]] : [];
        break;
      case StationMode.blue1:
        source = _blueTeams.length > 0 ? [_blueTeams[0]] : [];
        break;
      case StationMode.blue2:
        source = _blueTeams.length > 1 ? [_blueTeams[1]] : [];
        break;
      case StationMode.blue3:
        source = _blueTeams.length > 2 ? [_blueTeams[2]] : [];
        break;
    }

    if (source.isEmpty) return null;
    return int.tryParse(source.first.replaceAll("frc", ""));
  }

  String? _teamLabel(List<String> teams, int index) {
    if (teams.length <= index) return null;
    return teams[index].replaceAll("frc", "");
  }

  // --------------------------
  // RESET
  // --------------------------

  void _resetForm(int nextMatch) {
    _teamLookupTimer?.cancel();
    ++_teamsRequestId;
    _reportId = DateTime.now().microsecondsSinceEpoch.toString();
    _unconfirmed = false;
    _cloudConfirmedId = null;
    _capture.reset();
    _manualTeamController.clear();
    _activePhase = 0;
    _matchController.text = nextMatch.toString();
    _commentsController.clear();

    _redTeams.clear();
    _blueTeams.clear();

    _autoPath = [];

    _autoFuel = 0;
    _teleopFuel = 0;
    _died = false;
    _defense = false;
  }

  // --------------------------
  // SUBMIT
  // --------------------------

  Future<void> _submit() async {
    if (_submitting || _loadingDraft) return;
    if (!_formKey.currentState!.validate()) {
      _jumpToPhase(0);
      return;
    }

    final match = int.parse(_matchController.text.trim());
    final team = selectedTeam;

    final autoError = _validateAutoPath();
    if (autoError != null) {
      _jumpToPhase(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(autoError)),
      );
      return;
    }

    if (_autoFuel > _maxAutoFuel || _teleopFuel > _maxTeleopFuel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fuel count is above the allowed maximum.'),
        ),
      );
      return;
    }

    if (team == null) {
      _jumpToPhase(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid station")),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      LocalScoutReport? previous;
      try {
        previous = (await _local.history(_scope!))
            .where((entry) => entry.id == _reportId)
            .firstOrNull;
      } catch (_) {/* Device storage must not block the cloud attempt. */}
      if (!mounted) return;
      final alreadyUploaded = _cloudConfirmedId == _reportId ||
          previous?.status == LocalReportStatus.uploaded;
      final needsCheck = _unconfirmed ||
          previous?.status == LocalReportStatus.uploading ||
          previous?.status == LocalReportStatus.unconfirmed;
      if (!alreadyUploaded && needsCheck) {
        final retry = await confirmScoutingRetry(context);
        if (retry != true || !mounted) return;
      }
      _capture.finish();
      final auth = context.read<AuthService>();

      final report = MatchScouting2026(
        groupId: auth.groupId,
        event: eventCode,
        match: match.toString(),
        team: team,
        data: Data(
          autoPath: AutoPath(path: _autoPath),
          autoScouting: AutoScouting(
            fuel_scored: _autoFuel,
          ),
          teleopScouting: TeleopScouting(
            fuel_scored: _teleopFuel,
          ),
          misc: Misc(
            defense: _defense,
            died: _died,
            comments: _commentsController.text.trim(),
          ),
        ),
        scoutInfo: ScoutInfo(
          userId: auth.username ?? "",
          firstName: auth.firstName ?? "",
          username: auth.username ?? "",
          team: auth.team?.toString() ?? "",
        ),
      );

      final entry = LocalScoutReport(
          id: _reportId,
          report: report.toJson(),
          recording: _capture.toJson(),
          status: alreadyUploaded
              ? LocalReportStatus.uploaded
              : LocalReportStatus.saved,
          savedAt: DateTime.now());
      _unconfirmed = !alreadyUploaded;
      await _saveDraft();
      final api = APIService();
      late final ScoutingDeliveryResult result;
      try {
        result = await ScoutingDelivery(
                store: _local,
                upload: (payload) => api
                    .submitMatchScouting(MatchScouting2026.fromJson(payload)),
                downloadJson: downloadScoutReportJson)
            .submit(_scope!, entry);
      } finally {
        api.dispose();
      }
      if (!mounted) return;
      _unconfirmed = !result.uploaded;
      if (result.uploaded) {
        _cloudConfirmedId = _reportId;
        widget.onSubmitted?.call();
      }
      await _saveDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          duration: const Duration(seconds: 8),
          action: !result.completed
              ? SnackBarAction(
                  label: 'Download JSON',
                  onPressed: () => _downloadReport(entry))
              : null));
      if (result.completed) await _advanceToNextMatch(match + 1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Could not complete submission: $e. Your draft remains open.'),
          action:
              SnackBarAction(label: 'Download JSON', onPressed: _exportDraft)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // --------------------------
  // UI HELPERS
  // --------------------------

  Widget buildCounterCard({
    required String title,
    required int value,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
    required VoidCallback onAddFive,
    required VoidCallback onRemoveFive,
    required Color accentColor,
    required int maximum,
    required String periodLabel,
  }) {
    return MattePanel(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(18),
      tint: accentColor,
      child: Column(
        children: [
          Text(
            '$title  •  $periodLabel',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$value",
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Maximum $maximum',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCounterButton(
                  label: "-5",
                  icon: Icons.keyboard_double_arrow_down_rounded,
                  onPressed: onRemoveFive,
                  backgroundColor: const Color(0x66FF5C68),
                  foregroundColor: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCounterButton(
                  label: "-1",
                  icon: Icons.remove_rounded,
                  onPressed: onRemove,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCounterButton(
                  label: "+1",
                  icon: Icons.add_rounded,
                  onPressed: value >= maximum ? null : onAdd,
                  backgroundColor: accentColor.withValues(alpha: 0.78),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCounterButton(
                  label: "+5",
                  icon: Icons.keyboard_double_arrow_up_rounded,
                  onPressed: value >= maximum ? null : onAddFive,
                  backgroundColor: accentColor.withValues(alpha: 0.78),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return SizedBox(
      height: 74,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 10,
          ),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          side: BorderSide(
            color: foregroundColor.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateAutoPath() => _autoPath.isEmpty && _autoFuel > 0
      ? 'Choose where the robot shoots its preload.'
      : AutoRoute.validate(_autoPath);

  Widget _buildAutoField({bool showMap = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (showMap) ...[
          AutoFieldMap(
              path: _autoPath,
              blue: _isBlueAlliance,
              enabled: false,
              keyPrefix: 'preview'),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
            onPressed: _submitting ? null : _openLive,
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text(_capture.started
                ? 'Open live recorder'
                : 'Open field recorder'),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(60))),
        const SizedBox(height: 12),
        Text(
            _autoPath.isEmpty
                ? 'Record crossings, intakes, and shooting bursts as they happen.'
                : _autoPath.map(AutoRoute.label).join(' → '),
            style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
        TextButton.icon(
            onPressed: () => showCaptureTimeline(context, _capture),
            icon: const Icon(Icons.history_rounded),
            label: Text(
                '${_capture.actions.length} observations · timeline & undo')),
      ]);

  Widget _buildSectionCard({required Widget child}) => MattePanel(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        child: child,
      );

  Widget _buildSelectedTeamCard() {
    final team = selectedTeam;

    return _buildSectionCard(
      child: _loadingTeams && selectedTeam == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team == null ? "No team selected" : "Team $team",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Red: ${_redTeams.map((e) => e.replaceAll("frc", "")).join(", ")}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  "Blue: ${_blueTeams.map((e) => e.replaceAll("frc", "")).join(", ")}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
    );
  }

  // --------------------------
  // BUILD
  // --------------------------
  Widget _buildScoutingSection({
    required String title,
    required String description,
    required IconData icon,
    required Widget child,
    Color? accentColor,
  }) {
    final color = accentColor ?? _primaryColor;

    return MattePanel(
      tint: color,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.18),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildScoutingToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: value
          ? activeColor.withValues(alpha: 0.11)
          : Colors.white.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value
                  ? activeColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: value
                      ? activeColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: value ? activeColor : Colors.white54,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: value ? Colors.white : Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                activeThumbColor: activeColor,
                activeTrackColor: activeColor.withValues(alpha: 0.35),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fuelCounter(bool auto) {
    final maximum = auto ? _maxAutoFuel : _maxTeleopFuel;
    void count(int delta) {
      HapticFeedback.selectionClick();
      _capture.correctFuel(
          auto ? CapturePhase.auto : CapturePhase.teleop, delta);
    }

    return buildCounterCard(
      title: auto ? 'Auto fuel' : 'Teleop fuel',
      value: auto ? _autoFuel : _teleopFuel,
      accentColor: auto ? const Color(0xFFFFD28A) : AppColors.secondary,
      maximum: maximum,
      periodLabel: auto ? 'AUTO' : 'TELEOP',
      onAdd: () => count(1),
      onRemove: () => count(-1),
      onAddFive: () => count(5),
      onRemoveFive: () => count(-5),
    );
  }

  Future<void> _selectStation(StationMode mode) async {
    if (mode == _selectedMode) return;
    if (_autoPath.isNotEmpty ||
        _capture.phase != CapturePhase.setup ||
        _autoFuel > 0 ||
        _teleopFuel > 0 ||
        _commentsController.text.isNotEmpty ||
        _died ||
        _defense) {
      final clear = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Switch robots?'),
                content: const Text(
                    'Clear this draft before scouting a different station so the two robots’ data stays separate.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep scouting')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear and switch'))
                ],
              ));
      if (clear != true || !mounted) return;
    }
    setState(() {
      _selectedMode = mode;
      _capture.reset();
      _reportId = DateTime.now().microsecondsSinceEpoch.toString();
      _unconfirmed = false;
      _cloudConfirmedId = null;
      _manualTeamController.clear();
      _autoPath = [];
      _autoFuel = 0;
      _teleopFuel = 0;
      _commentsController.clear();
      _died = false;
      _defense = false;
    });
    _scheduleBackup();
  }

  Widget _preMatch() => _buildScoutingSection(
        title: 'Confirm your robot',
        description: 'Check the match and station before the robot moves.',
        icon: Icons.assignment_outlined,
        accentColor: AppColors.secondary,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
              controller: _matchController,
              enabled: !_submitting &&
                  _capture.phase == CapturePhase.setup &&
                  _capture.actions.isEmpty,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                  labelText: 'Match number',
                  prefixIcon: Icon(Icons.sports_score_rounded)),
              onChanged: (_) => _scheduleTeamLookup(),
              validator: (value) => (int.tryParse(value?.trim() ?? '') ?? 0) < 1
                  ? 'Enter a valid match number'
                  : null),
          const SizedBox(height: 16),
          LayoutBuilder(
              builder: (context, constraints) =>
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < StationMode.values.length; i++)
                      SizedBox(
                          width: (constraints.maxWidth - 16) / 3,
                          child: ChoiceChip(
                            selected: _selectedMode == StationMode.values[i],
                            selectedColor:
                                _chipColor(StationMode.values[i], true)
                                    .withValues(alpha: 0.32),
                            showCheckmark: false,
                            label: Column(children: [
                              Text('${i < 3 ? 'Red' : 'Blue'} ${i % 3 + 1}',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                  _teamLabel(i < 3 ? _redTeams : _blueTeams,
                                          i % 3) ??
                                      '—',
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800))
                            ]),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 4),
                            onSelected: _submitting
                                ? null
                                : (_) => _selectStation(StationMode.values[i]),
                          )),
                  ])),
          const SizedBox(height: 12),
          TextFormField(
              controller: _manualTeamController,
              enabled: !_submitting &&
                  _capture.phase == CapturePhase.setup &&
                  _capture.actions.isEmpty,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Team override (optional)',
                  helperText:
                      'Use when the schedule is unavailable. Check the bumper number.',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.numbers_rounded)),
              onChanged: (_) => setState(() {}),
              validator: (value) => value != null &&
                      value.isNotEmpty &&
                      (int.tryParse(value) ?? 0) < 1
                  ? 'Enter a valid team number'
                  : null),
          const SizedBox(height: 12),
          _buildSelectedTeamCard(),
          const SizedBox(height: 12),
          _buildAutoField(),
          if (_loadingTeams)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator()),
        ]),
      );

  Widget _review() => _buildScoutingSection(
        title: 'Review the match',
        description: 'Finish observations, then submit once.',
        icon: Icons.fact_check_outlined,
        accentColor: AppColors.primary,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: Text('Auto fuel $_autoFuel')),
            Chip(label: Text('Teleop fuel $_teleopFuel')),
            Chip(label: Text('${_autoPath.length} auto actions')),
          ]),
          const SizedBox(height: 12),
          _buildScoutingToggle(
              title: 'Robot disabled',
              subtitle: 'Stopped functioning during the match.',
              icon: Icons.power_settings_new_rounded,
              value: _died,
              activeColor: const Color(0xFFFF929E),
              onChanged: (value) => _capture.flag(CaptureKind.disabled, value)),
          const SizedBox(height: 10),
          _buildScoutingToggle(
              title: 'Played defense',
              subtitle: 'Actively defended another robot.',
              icon: Icons.shield_outlined,
              value: _defense,
              activeColor: const Color(0xFFFFD28A),
              onChanged: (value) => _capture.flag(CaptureKind.defense, value)),
          const SizedBox(height: 16),
          TextFormField(
              controller: _commentsController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                  labelText: 'Comments',
                  hintText: 'Driver skill, breakdowns, defense, or strategy…',
                  alignLabelWithHint: true)),
          const SizedBox(height: 12),
          TextButton.icon(
              onPressed: () => showCaptureTimeline(context, _capture),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Review observation timeline')),
          const Text(
              'Submit uploads to the cloud. If the upload is not confirmed, a JSON backup downloads automatically.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    const phases = ['Pre-match', 'Auto', 'Teleop', 'Review'];
    if (_loadingDraft) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              border: Border(
                  bottom:
                      BorderSide(color: _primaryColor.withValues(alpha: 0.4)))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.visibility_outlined, size: 20, color: _primaryColor),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      selectedTeam == null
                          ? 'Match scouting'
                          : 'Team $selectedTeam · Match ${_matchController.text}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16))),
              Text('${_autoFuel + _teleopFuel} fuel',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
              PopupMenuButton<String>(
                  enabled: !_submitting,
                  tooltip: 'Device backups',
                  onSelected: (value) {
                    if (value == 'history') _history();
                    if (value == 'export') _exportDraft();
                    if (value == 'clear') _clearCurrentDraft();
                  },
                  itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'history',
                            child: Text('Saved reports & upload')),
                        PopupMenuItem(
                            value: 'export',
                            child: Text('Download draft JSON')),
                        PopupMenuItem(
                            value: 'clear', child: Text('Clear current draft')),
                      ]),
            ]),
            Text(_backupStatus,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (var i = 0; i < phases.length; i++)
                    Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${i + 1}  ${phases[i]}'),
                          selected: i == _activePhase,
                          onSelected:
                              _submitting ? null : (_) => _jumpToPhase(i),
                        )),
                ])),
          ]),
        ),
        Expanded(
            child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(12),
          child: Form(
              key: _formKey,
              child: Column(children: [
                Visibility(
                    visible: _activePhase == 0,
                    maintainState: true,
                    child: _preMatch()),
                Visibility(
                    visible: _activePhase == 1,
                    maintainState: true,
                    child: _buildScoutingSection(
                        title: 'Autonomous',
                        description:
                            'Capture the route and count the fuel you observe.',
                        icon: Icons.route_rounded,
                        accentColor: const Color(0xFFFFD28A),
                        child: Column(children: [
                          _buildAutoField(showMap: true),
                          const SizedBox(height: 16),
                          _fuelCounter(true)
                        ]))),
                Visibility(
                    visible: _activePhase == 2,
                    maintainState: true,
                    child: _buildScoutingSection(
                        title: 'Teleop',
                        description:
                            'Keep your eyes on the robot. Use +1 or +5 as fuel scores.',
                        icon: Icons.sports_esports_rounded,
                        accentColor: AppColors.secondary,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildAutoField(),
                              const SizedBox(height: 12),
                              _fuelCounter(false)
                            ]))),
                Visibility(
                    visible: _activePhase == 3,
                    maintainState: true,
                    child: _review()),
              ])),
        )),
      ]),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: AppColors.surface,
            child: Row(children: [
              if (_activePhase > 0) ...[
                OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => _jumpToPhase(_activePhase - 1),
                    child: const Icon(Icons.arrow_back_rounded)),
                const SizedBox(width: 8)
              ],
              Expanded(
                  child: FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : _activePhase == 3
                        ? () => _submit()
                        : () => _jumpToPhase(_activePhase + 1),
                icon: Icon(
                    _activePhase == 3
                        ? Icons.send_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18),
                label: Text(_submitting
                    ? 'Submitting…'
                    : _activePhase == 3
                        ? 'Upload match report'
                        : 'Continue to ${phases[_activePhase + 1]}'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              )),
            ]),
          )),
    );
  }
}
