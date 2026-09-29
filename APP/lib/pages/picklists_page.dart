import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/APIService.dart';
import 'package:app/models/picklist.dart';
import 'package:app/models/team_stat.dart';
import 'package:app/widgets/DataSourceBanner.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
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
  final APIService _api = APIService();
  final Map<String, Timer> _saveTimers = {};
  final Set<String> _savingIds = {};

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
        title: Text('Team ${entry.team} notes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Strategy, compatibility, concerns…',
          ),
        ),
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
    return Scaffold(
      appBar: PolarForecastAppBar(
          extraText: '${_eventKey.toUpperCase()} Picklists'),
      body: Column(
        children: [
          const DataSourceBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _buildToolbar(picklist),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          const SizedBox(height: 14),
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

  Widget _buildToolbar(PicklistData? picklist) {
    return MattePanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('picklist-${picklist?.id}'),
                  initialValue: picklist?.id,
                  decoration: const InputDecoration(
                    labelText: 'Picklist',
                    prefixIcon: Icon(Icons.playlist_add_check_circle_rounded),
                  ),
                  items: _picklists
                      .map((item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedId = value),
                ),
              ),
              FilledButton.icon(
                onPressed: _creating ? null : _createPicklist,
                icon: const Icon(Icons.add_rounded),
                label: Text(_creating ? 'Creating' : 'New picklist'),
              ),
              if (picklist != null) ...[
                OutlinedButton.icon(
                  onPressed: () => _renamePicklist(picklist),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Rename'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportCsv(picklist),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(_exporting ? 'Exporting' : 'Export CSV'),
                ),
                IconButton(
                  tooltip: 'Delete picklist',
                  onPressed: () => _deletePicklist(picklist),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
          if (picklist != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('sort-${picklist.id}-${picklist.sortBy}'),
                    initialValue: picklist.sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sort list by',
                      prefixIcon: Icon(Icons.sort_rounded),
                    ),
                    items: picklistSortLabels.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) _sortPicklist(picklist, value);
                    },
                  ),
                ),
                _ConnectionChip(connected: _socketConnected),
                if (_savingIds.contains(picklist.id))
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 7),
                      Text('Saving', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
              ],
            ),
          ],
        ],
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
      buildDefaultDragHandles: false,
      itemCount: picklist.teams.length,
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final entry = picklist.teams.removeAt(oldIndex);
          picklist.teams.insert(newIndex, entry);
          picklist.sortBy = 'manual';
        });
        _scheduleSave(picklist);
      },
      itemBuilder: (context, index) {
        final entry = picklist.teams[index];
        final stats = _statsByTeam[entry.team];
        return Padding(
          key: ValueKey('${picklist.id}-${entry.team}'),
          padding: const EdgeInsets.only(bottom: 9),
          child: MattePanel(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_indicator_rounded,
                        color: Colors.white38),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4DA3FF).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF4DA3FF),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/event/$_eventKey/${entry.team}/team',
                        ),
                        child: Text(
                          'Team ${entry.team}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      if (stats == null)
                        const Text('No current stats',
                            style: TextStyle(color: Colors.white54))
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _StatPill(
                                label: 'Rank',
                                value: stats.Rank > 0 ? '${stats.Rank}' : '—'),
                            _StatPill(
                                label: 'OPR', value: _formatStat(stats.OPR)),
                            _StatPill(
                                label: 'Defense',
                                value: _formatStat(stats.DefenseRate,
                                    percent: true)),
                            _StatPill(
                                label: 'Auto Fuel',
                                value: _formatStat(stats.AverageAutoFuel)),
                            _StatPill(
                                label: 'Teleop Fuel',
                                value: _formatStat(stats.AverageTeleopFuel)),
                            _StatPill(
                                label: 'Auto', value: _formatStat(stats.Auto)),
                            _StatPill(
                                label: 'Teleop',
                                value: _formatStat(stats.Teleop)),
                            _StatPill(
                                label: 'Endgame',
                                value: _formatStat(stats.Endgame)),
                          ],
                        ),
                      if (entry.tier.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          entry.tier == 'Do not pick'
                              ? entry.tier
                              : '${entry.tier} tier',
                          style: TextStyle(
                            color: entry.tier == 'Do not pick'
                                ? Colors.redAccent
                                : const Color(0xFF4DA3FF),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      if (entry.note.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(entry.note,
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Move team up',
                      onPressed: index == 0
                          ? null
                          : () => _moveTeam(picklist, index, -1),
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    ),
                    IconButton(
                      tooltip: 'Move team down',
                      onPressed: index == picklist.teams.length - 1
                          ? null
                          : () => _moveTeam(picklist, index, 1),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: 'Team options',
                  onSelected: (value) {
                    if (value == 'note') {
                      _editNote(picklist, entry);
                    } else {
                      setState(() => entry.tier = value);
                      _scheduleSave(picklist);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: '', child: Text('No tier')),
                    PopupMenuItem(value: 'A', child: Text('A tier')),
                    PopupMenuItem(value: 'B', child: Text('B tier')),
                    PopupMenuItem(value: 'C', child: Text('C tier')),
                    PopupMenuItem(
                        value: 'Do not pick', child: Text('Do not pick')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'note', child: Text('Edit notes')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
      title: const Text('Create picklist'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Picklist name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sortBy,
              decoration: const InputDecoration(labelText: 'Initial sort'),
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

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: '$label ', style: const TextStyle(color: Colors.white38)),
          TextSpan(
            text: value,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w700),
          ),
        ]),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  final bool connected;

  const _ConnectionChip({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(connected ? Icons.sync_rounded : Icons.sync_problem_rounded,
              color: color, size: 16),
          const SizedBox(width: 6),
          Text(connected ? 'Live sync' : 'Reconnecting',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
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
