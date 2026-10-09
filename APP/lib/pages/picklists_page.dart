import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:app/APIService.dart';
import 'package:app/models/picklist.dart';
import 'package:app/models/team_stat.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PicklistsPage extends StatefulWidget {
  final String eventCode;
  final String groupId;
  final String username;

  const PicklistsPage({
    super.key,
    required this.eventCode,
    required this.groupId,
    required this.username,
  });

  @override
  State<PicklistsPage> createState() => _PicklistsPageState();
}

class _PicklistsPageState extends State<PicklistsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _highlightedTeam;
  Timer? _highlightTimer;
  final APIService _api = APIService();
  final Map<String, Timer> _saveTimers = {};
  final Set<String> _savingIds = {};
  final Map<int, Future<Map<String, dynamic>>> _teamIdentities = {};
  final Map<int, Color> _teamColors = {};

  List<PicklistData> _picklists = [];
  Map<int, TeamStat> _statsByTeam = {};
  Set<int> _officialTeams = {};
  String? _selectedId;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  bool _connectingSocket = false;
  bool _socketConnected = false;
  bool _loading = true;
  bool _creating = false;
  bool _exporting = false;
  String? _error;

  String get _eventKey => RegExp(r'^\d{4}').hasMatch(widget.eventCode)
      ? widget.eventCode
      : '2026${widget.eventCode}';

  PicklistData? get _selected {
    for (final picklist in _picklists) {
      if (picklist.id == _selectedId) return picklist;
    }
    return _picklists.isEmpty ? null : _picklists.first;
  }

  @override
  void initState() {
    super.initState();
    if (widget.groupId.isEmpty || widget.username.isEmpty) {
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant PicklistsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId ||
        oldWidget.username != widget.username) {
      for (final timer in _saveTimers.values) {
        timer.cancel();
      }
      _saveTimers.clear();
      _reconnectTimer?.cancel();
      _socketSubscription?.cancel();
      _channel?.sink.close();
      _channel = null;
      _socketSubscription = null;
      _socketConnected = false;
      if (widget.groupId.isNotEmpty && widget.username.isNotEmpty) {
        _load();
      } else {
        setState(() {
          _picklists = [];
          _selectedId = null;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    for (final timer in _saveTimers.values) {
      timer.cancel();
    }
    _reconnectTimer?.cancel();
    _socketSubscription?.cancel();
    _channel?.sink.close();
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _api.fetchPicklists(
          groupId: widget.groupId,
          event: _eventKey,
          username: widget.username,
        ),
        _api.fetchRawStatsByEvent(_eventKey, username: widget.username),
        _api.fetchTeamsPerEvent(_eventKey),
      ]);
      final rawPicklists = results[0] as List<Map<String, dynamic>>;
      final stats = results[1];
      final rawTeams = results[2];
      final officialTeams =
          rawTeams.map(_parseTeamNumber).whereType<int>().toSet();

      if (!mounted) return;
      setState(() {
        _statsByTeam = {for (final stat in stats) stat.Team: stat};
        _officialTeams = officialTeams;
        _applyPicklists(rawPicklists, notify: false);
        _loading = false;
      });
      _connectSocket();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  static int? _parseTeamNumber(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(
      value.toString().trim().toLowerCase().replaceFirst(RegExp(r'^frc'), ''),
    );
  }

  void _applyPicklists(
    List<Map<String, dynamic>> rawPicklists, {
    bool notify = true,
  }) {
    final picklists = rawPicklists.map(PicklistData.fromJson).where((picklist) {
      return picklist.id.isNotEmpty;
    }).toList();

    for (final picklist in picklists) {
      picklist.teams = picklist.teams
          .where((entry) => _officialTeams.contains(entry.team))
          .toList();
    }

    final nextSelected = picklists.any((item) => item.id == _selectedId)
        ? _selectedId
        : (picklists.isEmpty ? null : picklists.first.id);

    void apply() {
      _picklists = picklists;
      _selectedId = nextSelected;
      _error = null;
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  Future<void> _connectSocket() async {
    if (!mounted || _connectingSocket || _socketConnected) return;
    _connectingSocket = true;
    _reconnectTimer?.cancel();
    try {
      final channel = WebSocketChannel.connect(
        _api.picklistWebSocketUri(
          groupId: widget.groupId,
          event: _eventKey,
          username: widget.username,
        ),
      );
      await channel.ready;
      if (!mounted) {
        channel.sink.close();
        return;
      }
      _channel = channel;
      setState(() => _socketConnected = true);
      _socketSubscription = channel.stream.listen(
        _handleSocketMessage,
        onError: (_) => _handleSocketClosed(),
        onDone: _handleSocketClosed,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _connectingSocket = false;
    }
  }

  void _handleSocketMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message.toString());
      if (decoded is! Map ||
          decoded['type'] != 'picklists_snapshot' ||
          decoded['picklists'] is! List) {
        return;
      }
      final rows = (decoded['picklists'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _applyPicklists(rows);
    } catch (_) {
      // A malformed live message should not replace the last valid snapshot.
    }
  }

  void _handleSocketClosed() {
    _channel = null;
    _socketSubscription = null;
    if (mounted) setState(() => _socketConnected = false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _connectSocket);
  }

  void _scheduleSave(PicklistData picklist) {
    _saveTimers[picklist.id]?.cancel();
    _saveTimers[picklist.id] = Timer(
      const Duration(milliseconds: 350),
      () => _savePicklist(picklist.id),
    );
  }

  Future<void> _savePicklist(String id) async {
    final picklist = _picklists.where((item) => item.id == id).firstOrNull;
    if (picklist == null) return;
    if (mounted) setState(() => _savingIds.add(id));
    try {
      await _api.updatePicklist(
        groupId: widget.groupId,
        event: _eventKey,
        picklistId: id,
        username: widget.username,
        name: picklist.name,
        sortBy: picklist.sortBy,
        teams: picklist.teams.map((entry) => entry.toJson()).toList(),
      );
      if (mounted) setState(() => _error = null);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _savingIds.remove(id));
    }
  }

  void _sortPicklist(PicklistData picklist, String sortBy) {
    setState(() {
      picklist.sortBy = sortBy;
      if (sortBy != 'manual') {
        picklist.teams.sort((a, b) => _compareTeams(a.team, b.team, sortBy));
      }
    });
    _scheduleSave(picklist);
  }

  int _compareTeams(int a, int b, String sortBy) {
    final aStats = _statsByTeam[a];
    final bStats = _statsByTeam[b];
    switch (sortBy) {
      case 'rank':
        final aRank = aStats?.Rank ?? 0;
        final bRank = bStats?.Rank ?? 0;
        if (aRank <= 0 && bRank > 0) return 1;
        if (aRank > 0 && bRank <= 0) return -1;
        final comparison = aRank.compareTo(bRank);
        return comparison == 0 ? a.compareTo(b) : comparison;
      case 'opr':
        final comparison = (bStats?.OPR ?? double.negativeInfinity)
            .compareTo(aStats?.OPR ?? double.negativeInfinity);
        return comparison == 0 ? a.compareTo(b) : comparison;
      case 'defense':
        final comparison =
            (bStats?.DefenseRate ?? 0).compareTo(aStats?.DefenseRate ?? 0);
        if (comparison != 0) return comparison;
        final countComparison =
            (bStats?.DefenseCount ?? 0).compareTo(aStats?.DefenseCount ?? 0);
        return countComparison == 0 ? a.compareTo(b) : countComparison;
      case 'team':
      default:
        return a.compareTo(b);
    }
  }

  void _moveTeam(PicklistData picklist, int index, int offset) {
    final destination = index + offset;
    if (destination < 0 || destination >= picklist.teams.length) return;
    setState(() {
      final entry = picklist.teams.removeAt(index);
      picklist.teams.insert(destination, entry);
      picklist.sortBy = 'manual';
      _highlightedTeam = entry.team;
    });
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _highlightedTeam = null);
    });
    _scheduleSave(picklist);
  }

  Future<void> _createPicklist() async {
    final request = await showDialog<_CreatePicklistRequest>(
      context: context,
      builder: (context) => const _CreatePicklistDialog(),
    );
    if (request == null || !mounted) return;
    setState(() => _creating = true);
    try {
      final json = await _api.createPicklist(
        groupId: widget.groupId,
        event: _eventKey,
        username: widget.username,
        name: request.name,
        sortBy: request.sortBy,
      );
      final created = PicklistData.fromJson(json);
      if (!mounted) return;
      setState(() {
        _picklists = [
          ..._picklists.where((item) => item.id != created.id),
          created,
        ];
        _selectedId = created.id;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _renamePicklist(PicklistData picklist) async {
    final controller = TextEditingController(text: picklist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename picklist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Picklist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => picklist.name = name);
    _scheduleSave(picklist);
  }

  Future<void> _deletePicklist(PicklistData picklist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${picklist.name}?'),
        content: const Text(
          'This removes the shared list for everyone in your scouting group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.deletePicklist(
        groupId: widget.groupId,
        event: _eventKey,
        picklistId: picklist.id,
        username: widget.username,
      );
      if (!mounted) return;
      setState(() {
        _picklists.removeWhere((item) => item.id == picklist.id);
        _selectedId = _picklists.isEmpty ? null : _picklists.first.id;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _editNote(PicklistData picklist, PicklistEntry entry) async {
    final controller = TextEditingController(text: entry.note);
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(children: [
          const Text('Edit Comments'),
          const SizedBox(height: 6),
          Text('For Team ${entry.team}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
        content: SizedBox(
            width: 380,
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 500,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Add notes, strategy, or observations...',
              ),
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || !mounted) return;
    setState(() => entry.note = note);
    _scheduleSave(picklist);
  }

  Future<void> _openTeamImages(int team, int picklistPosition) async {
    final images = _loadTeamImages(team);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text('Team $team images',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 8),
                Text('Picklist #$picklistPosition',
                    style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 16),
                Flexible(
                    child: FutureBuilder<List<Map<String, String>>>(
                  future: images,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && !snapshot.hasError) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final media =
                        snapshot.data ?? const <Map<String, String>>[];
                    if (media.isEmpty)
                      return const Center(
                          child: Text(
                              'No team images available for this season.'));
                    return GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10),
                      itemCount: media.length,
                      itemBuilder: (context, index) {
                        final url = media[index]['url']!;
                        return InkWell(
                          onTap: () => showDialog<void>(
                              context: dialogContext,
                              builder: (_) => Dialog(
                                  backgroundColor: Colors.black87,
                                  child: Stack(children: [
                                    InteractiveViewer(
                                        child: Center(
                                            child: Image.network(url,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                        Icons.broken_image)))),
                                    Positioned(
                                        right: 8,
                                        top: 8,
                                        child: IconButton(
                                            tooltip: 'Close image',
                                            onPressed: () =>
                                                Navigator.pop(dialogContext),
                                            icon: const Icon(Icons.close))),
                                  ]))),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                      child:
                                          Icon(Icons.broken_image_outlined)))),
                        );
                      },
                    );
                  },
                )),
              ],
            )),
      )),
    );
  }

  Future<List<Map<String, String>>> _loadTeamImages(int team) async {
    final results = await Future.wait([
      _api.fetchTeamImages(team, year: int.parse(_eventKey.substring(0, 4))),
      _api
          .fetchRobotImages(
            groupId: widget.groupId,
            event: _eventKey,
            team: team,
            username: widget.username,
          )
          .catchError((_) => <Map<String, String>>[]),
    ]);
    return [...results[0], ...results[1]];
  }

  String _escapeCsv(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  Future<void> _exportCsv(PicklistData picklist) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final rows = <List<Object?>>[
        [
          'Position',
          'Team',
          'Tier',
          'Notes',
          'Rank',
          'OPR',
          'AutoFuel',
          'TeleopFuel',
          'AutoFuelOPR',
          'TeleopFuelOPR',
          'Auto',
          'Teleop',
          'Endgame',
          'Climb',
          'DefenseRate',
          'DefenseCount',
          'DeathRate',
        ],
        for (var index = 0; index < picklist.teams.length; index++)
          () {
            final entry = picklist.teams[index];
            final stats = _statsByTeam[entry.team];
            return <Object?>[
              index + 1,
              entry.team,
              entry.tier,
              entry.note,
              stats?.Rank,
              stats?.OPR,
              stats?.AverageAutoFuel,
              stats?.AverageTeleopFuel,
              stats?.AutoFuelOPR,
              stats?.TeleopFuelOPR,
              stats?.Auto,
              stats?.Teleop,
              stats?.Endgame,
              stats?.Climb,
              stats?.DefenseRate,
              stats?.DefenseCount,
              stats?.DeathRate,
            ];
          }(),
      ];
      final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
      final safeName = picklist.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await FileSaver.instance.saveFile(
        name: '${_eventKey}_$safeName',
        bytes: Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not export CSV: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatStat(double? value, {bool percent = false}) {
    if (value == null || !value.isFinite) return '—';
    return percent ? '${(value * 100).round()}%' : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDeep,
      endDrawer: _buildPicklistDrawer(),
      appBar: PolarForecastAppBar(
          extraText:
              'Picklist for ${_eventKey.toUpperCase()} | Picklist: ${selected?.name ?? 'None'}'),
      floatingActionButton: _PicklistMenuButton(
        onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
      ),
      body: Stack(children: [
        Padding(
          padding:
              EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 8 : 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.background, AppColors.backgroundDeep],
                ),
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 700 ? 6 : 8),
              child: Column(children: [
                Expanded(child: _buildBody()),
              ]),
            ),
          ),
        ),
        const Positioned.fill(child: _PicklistSnow()),
      ]),
    );
  }

  Widget _buildBody() {
    if (widget.groupId.isEmpty || widget.username.isEmpty) {
      return const _PicklistEmptyState(
        icon: Icons.login_rounded,
        title: 'Login and group required',
        message: 'Join a scouting group before opening shared picklists.',
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _picklists.isEmpty) {
      return _PicklistEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load picklists',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    final picklist = _selected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Column(
        children: [
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          Expanded(
            child: picklist == null
                ? _PicklistEmptyState(
                    icon: Icons.playlist_add_rounded,
                    title: 'No picklists yet',
                    message:
                        'Create a list and choose how its initial order is sorted.',
                    actionLabel: 'Create picklist',
                    onAction: _createPicklist,
                  )
                : _buildTeamList(picklist),
          ),
        ],
      ),
    );
  }

  Widget _buildPicklistDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BlackGlassSurface(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(34)),
        blur: 40,
        opacity: 0.9,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Icon(Icons.list_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Picklists',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800))),
                  IconButton(
                      tooltip: 'Close picklists',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      for (final item in _picklists)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            selected: item.id == _selected?.id,
                            leading:
                                const Icon(Icons.format_list_numbered_rounded),
                            title: Text(item.name),
                            subtitle: Text('${item.teams.length} teams'),
                            trailing: item.id == _selected?.id
                                ? PopupMenuButton<String>(
                                    tooltip: 'Picklist actions',
                                    onSelected: (action) {
                                      Navigator.pop(context);
                                      if (action == 'rename')
                                        _renamePicklist(item);
                                      if (action == 'export') _exportCsv(item);
                                      if (action == 'delete')
                                        _deletePicklist(item);
                                      if (action.startsWith('sort:')) {
                                        _sortPicklist(
                                            item, action.substring(5));
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      ...picklistSortLabels.entries
                                          .where(
                                              (entry) => entry.key != 'manual')
                                          .map((entry) => PopupMenuItem(
                                                value: 'sort:${entry.key}',
                                                child: Text(
                                                    'Sort by ${entry.value}'),
                                              )),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                          value: 'rename',
                                          child: ListTile(
                                              leading:
                                                  Icon(Icons.edit_outlined),
                                              title: Text('Rename'))),
                                      const PopupMenuItem(
                                          value: 'export',
                                          child: ListTile(
                                              leading:
                                                  Icon(Icons.download_outlined),
                                              title: Text('Export as CSV'))),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                              leading: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.redAccent),
                                              title: Text('Delete'))),
                                    ],
                                  )
                                : null,
                            onTap: () {
                              setState(() => _selectedId = item.id);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      if (_picklists.isEmpty)
                        const Text('Create your first picklist to get started.',
                            style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    backgroundColor:
                        AppColors.glassBlue.withValues(alpha: 0.12),
                    minimumSize: const Size(0, 48),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _creating
                      ? null
                      : () {
                          Navigator.pop(context);
                          _createPicklist();
                        },
                  icon: const Icon(Icons.add),
                  label: Text(_creating ? 'Creating…' : 'New picklist'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamList(PicklistData picklist) {
    if (picklist.teams.isEmpty) {
      return const _PicklistEmptyState(
        icon: Icons.groups_outlined,
        title: 'No official event teams',
        message: 'The event roster is empty or has not been cached yet.',
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      buildDefaultDragHandles: false,
      itemCount: picklist.teams.length,
      onReorderItem: (oldIndex, newIndex) =>
          _moveTeam(picklist, oldIndex, newIndex - oldIndex),
      itemBuilder: (context, index) {
        final entry = picklist.teams[index];
        final stats = _statsByTeam[entry.team];
        final highlighted = _highlightedTeam == entry.team;
        final rank = stats?.Rank ?? 0;
        final rankColor = switch (rank) {
          1 => const Color(0xFFFFD781),
          2 => const Color(0xFFD8E6F2),
          3 => const Color(0xFFD8A47B),
          _ => AppColors.primary,
        };
        final identity = _PicklistTeamIdentity(
          team: entry.team,
          onAvatarTap: () => _openTeamImages(entry.team, index + 1),
          onColor: (color) {
            if (color != null && _teamColors[entry.team] != color && mounted) {
              setState(() => _teamColors[entry.team] = color);
            }
          },
          identity: _teamIdentities.putIfAbsent(
              entry.team,
              () => _api.fetchTeamIdentity(entry.team,
                  year: int.parse(_eventKey.substring(0, 4)))),
        );
        return AnimatedContainer(
          key: ValueKey('${picklist.id}-${entry.team}'),
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                        color: AppColors.glassBlue.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: 2)
                  ]
                : null,
          ),
          child: BlackGlassSurface(
            borderRadius: BorderRadius.circular(24),
            blur: 0,
            opacity: 0.9,
            tint: _teamColors[entry.team],
            highlighted: highlighted,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final controls = _buildMoveControls(picklist, index, compact);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 42,
                          child: Column(children: [
                            Text('#${index + 1}',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 5),
                            Tooltip(
                              message: 'Competition rank',
                              child: Column(children: [
                                Icon(Icons.emoji_events_outlined,
                                    size: 18, color: rankColor),
                                Text(rank > 0 ? '#$rank' : '—',
                                    style: TextStyle(
                                        fontSize: 11, color: rankColor)),
                              ]),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.drag_handle_rounded,
                                          size: 22,
                                          color: AppColors.textMuted))),
                            ),
                          ])),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pushNamed(context,
                                '/event/$_eventKey/${entry.team}/team'),
                            child: identity,
                          ),
                          const SizedBox(height: 6),
                          if (stats == null)
                            const Text('No current stats',
                                style: TextStyle(color: AppColors.textMuted))
                          else
                            Wrap(spacing: 6, runSpacing: 4, children: [
                              _StatPill(
                                  label: 'OPR',
                                  value: _formatStat(stats.OPR),
                                  color: Colors.purpleAccent),
                              _StatPill(
                                  label: 'Auto',
                                  value: _formatStat(stats.Auto),
                                  color: Colors.greenAccent),
                              _StatPill(
                                  label: 'Teleop',
                                  value: _formatStat(stats.Teleop),
                                  color: Colors.orangeAccent),
                              if (!compact)
                                _StatPill(
                                    label: 'Endgame',
                                    value: _formatStat(stats.Endgame),
                                    color: const Color(0xFFFFD781)),
                              if (!compact)
                                _StatPill(
                                    label: 'Death',
                                    value: _formatStat(stats.DeathRate,
                                        percent: true),
                                    color: Colors.redAccent),
                              if (!compact)
                                _StatPill(
                                    label: 'Def',
                                    value: _formatStat(stats.DefenseRate,
                                        percent: true),
                                    color: Colors.brown.shade200),
                            ]),
                        ],
                      )),
                      if (!compact) ...[
                        const SizedBox(width: 16),
                        controls,
                      ],
                      PopupMenuButton<String>(
                        tooltip: 'Set team tier',
                        onSelected: (value) {
                          setState(() => entry.tier = value);
                          _scheduleSave(picklist);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: '', child: Text('No tier')),
                          PopupMenuItem(value: 'A', child: Text('A tier')),
                          PopupMenuItem(value: 'B', child: Text('B tier')),
                          PopupMenuItem(value: 'C', child: Text('C tier')),
                          PopupMenuItem(
                              value: 'Do not pick', child: Text('Do not pick')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                            entry.note.isEmpty ? 'No comments.' : entry.note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.text.withValues(alpha: 0.85),
                                fontStyle: entry.note.isEmpty
                                    ? FontStyle.normal
                                    : FontStyle.italic)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit comments',
                      onPressed: () => _editNote(picklist, entry),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                    ),
                  ]),
                  if (entry.tier.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          entry.tier == 'Do not pick'
                              ? entry.tier
                              : '${entry.tier} tier',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: entry.tier == 'Do not pick'
                                  ? const Color(0xFFFFA4B1)
                                  : AppColors.aqua)),
                    ),
                  if (compact) ...[
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: controls),
                  ],
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildMoveControls(PicklistData picklist, int index, bool compact) {
    final first = index == 0;
    final last = index == picklist.teams.length - 1;
    final up = _moveButton(Icons.keyboard_arrow_up_rounded, 'Move up 1',
        first ? null : () => _moveTeam(picklist, index, -1));
    final down = _moveButton(Icons.keyboard_arrow_down_rounded, 'Move down 1',
        last ? null : () => _moveTeam(picklist, index, 1));
    final top = _moveButton(Icons.vertical_align_top_rounded, 'Move to top',
        first ? null : () => _moveTeam(picklist, index, -index),
        color: Colors.greenAccent);
    final bottom = _moveButton(
        Icons.vertical_align_bottom_rounded,
        'Move to bottom',
        last
            ? null
            : () =>
                _moveTeam(picklist, index, picklist.teams.length - 1 - index),
        color: Colors.orangeAccent);
    if (compact) {
      return Row(children: [
        Expanded(child: up),
        const SizedBox(width: 6),
        Expanded(child: down),
        const SizedBox(width: 6),
        Expanded(child: top),
        const SizedBox(width: 6),
        Expanded(child: bottom),
      ]);
    }
    return SizedBox(
        width: 92,
        child: Column(children: [
          Row(children: [
            Expanded(child: up),
            const SizedBox(width: 4),
            Expanded(child: down)
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: top),
            const SizedBox(width: 4),
            Expanded(child: bottom)
          ]),
        ]));
  }

  Widget _moveButton(IconData icon, String tooltip, VoidCallback? onPressed,
      {Color color = AppColors.text}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null ? 0.3 : 1,
      child: Tooltip(
        message: tooltip,
        child: BlackGlassSurface(
          borderRadius: BorderRadius.circular(100),
          blur: 3.6,
          opacity: 0.75,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PicklistMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PicklistMenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Open Picklist Panel',
        child: BlackGlassSurface(
          borderRadius: BorderRadius.circular(100),
          blur: 3.6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onPressed,
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.menu_rounded, color: AppColors.text),
                )),
          ),
        ),
      );
}

class _PicklistSnow extends StatefulWidget {
  const _PicklistSnow();

  @override
  State<_PicklistSnow> createState() => _PicklistSnowState();
}

class _PicklistSnowState extends State<_PicklistSnow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _animation.stop();
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
            child: RepaintBoundary(
          child: CustomPaint(painter: _PicklistSnowPainter(_animation)),
        )),
      );
}

class _PicklistSnowPainter extends CustomPainter {
  final Animation<double> animation;

  _PicklistSnowPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(26);
    final paint = Paint();
    for (var i = 0; i < 100; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final speed = 1 + random.nextInt(3);
      final radius = 0.8 + random.nextDouble() * 1.8;
      final drift = math.sin((animation.value + x) * math.pi * 2) * 18;
      paint.color = AppColors.primary
          .withValues(alpha: 0.10 + random.nextDouble() * 0.22);
      canvas.drawCircle(
          Offset(
            x * size.width + drift,
            ((y + animation.value * speed) % 1) * (size.height + 8) - 4,
          ),
          radius,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PicklistSnowPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _PicklistTeamIdentity extends StatefulWidget {
  final int team;
  final Future<Map<String, dynamic>> identity;
  final VoidCallback onAvatarTap;
  final ValueChanged<Color?> onColor;

  const _PicklistTeamIdentity({
    required this.team,
    required this.identity,
    required this.onAvatarTap,
    required this.onColor,
  });

  @override
  State<_PicklistTeamIdentity> createState() => _PicklistTeamIdentityState();
}

class _PicklistTeamIdentityState extends State<_PicklistTeamIdentity> {
  bool _paletteRequested = false;

  Future<void> _readPalette(Uint8List image) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(image),
        size: const Size(40, 40),
        maximumColorCount: 4,
      );
      if (mounted) {
        widget.onColor(
            palette.dominantColor?.color ?? palette.vibrantColor?.color);
      }
    } catch (_) {
      // A logo is optional; the team number and name remain available.
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: widget.identity,
        builder: (context, snapshot) {
          final name = snapshot.data?['name']?.toString().trim() ?? '';
          Uint8List? avatar;
          try {
            final encoded = snapshot.data?['avatar'];
            if (encoded is String && encoded.isNotEmpty) {
              avatar = base64Decode(encoded);
            }
          } on FormatException {
            // Ignore malformed avatar data.
          }
          if (avatar != null && !_paletteRequested) {
            _paletteRequested = true;
            _readPalette(avatar);
          }
          const fallback = Icon(Icons.smart_toy_outlined,
              color: AppColors.textMuted, size: 25);
          return Row(children: [
            InkWell(
              onTap: widget.onAvatarTap,
              borderRadius: BorderRadius.circular(8),
              child: Tooltip(
                message: 'View team images',
                child: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: avatar == null
                      ? fallback
                      : Image.memory(avatar,
                          fit: BoxFit.contain,
                          semanticLabel: 'Team ${widget.team} logo',
                          errorBuilder: (_, __, ___) => fallback),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              name.isEmpty ? '${widget.team}' : '${widget.team} | $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text),
            )),
          ]);
        },
      );
}

class _CreatePicklistRequest {
  final String name;
  final String sortBy;

  const _CreatePicklistRequest(this.name, this.sortBy);
}

class _CreatePicklistDialog extends StatefulWidget {
  const _CreatePicklistDialog();

  @override
  State<_CreatePicklistDialog> createState() => _CreatePicklistDialogState();
}

class _CreatePicklistDialogState extends State<_CreatePicklistDialog> {
  final TextEditingController _controller = TextEditingController();
  String _sortBy = 'rank';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: const Row(children: [
        Icon(Icons.add_chart_rounded, color: AppColors.primary),
        SizedBox(width: 12),
        Text('Create Picklist'),
      ]),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Set up the details for your new picklist.',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(
                  labelText: 'Picklist Name',
                  prefixIcon: Icon(Icons.edit_note)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _sortBy,
              decoration: const InputDecoration(
                  labelText: 'Initial Sort Metric',
                  prefixIcon: Icon(Icons.sort_rounded)),
              items: picklistSortLabels.entries
                  .where((entry) => entry.key != 'manual')
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _sortBy = value ?? 'rank'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context, _CreatePicklistRequest(name, _sortBy));
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill(
      {required this.label,
      required this.value,
      this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label: ', style: TextStyle(color: color)),
          TextSpan(
            text: value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ]),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PicklistEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PicklistEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: MattePanel(
          padding: const EdgeInsets.all(28),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: Colors.white38),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
