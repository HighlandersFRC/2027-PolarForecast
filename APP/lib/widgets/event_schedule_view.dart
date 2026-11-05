import 'dart:convert';
import 'dart:typed_data';

import 'package:app/APIService.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

String buildEventScheduleCsv(
  List<Map<String, dynamic>> groups,
  List<Map<String, dynamic>> rows,
) {
  final records = <List<String>>[
    ['Date', 'Time', 'Group', 'Activity'],
  ];
  for (final row in rows) {
    final date = row['date'] as String;
    final time = row['time'] as String;
    final activities = row['activities'] as Map;
    final previousCount = records.length;
    for (final group in groups) {
      final activity = activities[group['id']] as String? ?? '';
      if (activity.trim().isNotEmpty) {
        records.add([
          date,
          time,
          _csvText(group['name'] as String),
          _csvText(activity),
        ]);
      }
    }
    if (records.length == previousCount) records.add([date, time, '', '']);
  }
  return const ListToCsvConverter().convert(records);
}

String _csvText(String value) {
  // Keep editable text from being interpreted as a spreadsheet formula.
  final formulaPrefix = RegExp(r'^[\s\uFEFF]*[=+@＝＋－＠-]');
  return formulaPrefix.hasMatch(value) ? "'$value" : value;
}

class EventScheduleView extends StatefulWidget {
  final String event;
  final String? eventStart;
  final String? eventEnd;
  final String rosterGroupId;
  final Future<String> Function() getAccessToken;
  final APIService api;

  const EventScheduleView(
      {super.key,
      required this.event,
      this.eventStart,
      this.eventEnd,
      required this.rosterGroupId,
      required this.getAccessToken,
      required this.api});

  @override
  State<EventScheduleView> createState() => _EventScheduleViewState();
}

class _EventScheduleViewState extends State<EventScheduleView> {
  Map<String, dynamic>? _schedule;
  Map<String, String> _members = {};
  String? _error;
  bool _busy = false;
  bool _exporting = false;
  bool _showAttendance = false;
  String? _selectedDate;
  String? _attendanceSlot;
  bool get _canEdit => _schedule?['can_edit'] == true;
  List<Map<String, dynamic>> get _groups => _maps(_schedule?['groups']);
  List<Map<String, dynamic>> get _rows => _maps(_schedule?['rows']);
  List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.eventSchedule(
            event: widget.event,
            rosterGroupId: widget.rosterGroupId,
            accessToken: await widget.getAccessToken()),
        widget.api.fetchGroupMembers(widget.rosterGroupId),
      ]);
      final roster = results[1] as Map<String, List<dynamic>>;
      final members = <String, String>{};
      for (final member in roster.values.expand((e) => e)) {
        final map = Map<String, dynamic>.from(member as Map);
        final username = (map['username'] ?? '').toString().trim();
        if (username.isEmpty) continue;
        final name = [
          map['firstName'] ?? map['first_name'],
          map['lastName'] ?? map['last_name']
        ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');
        members[username] = name.isEmpty ? username : '$name (@$username)';
      }
      if (!mounted) return;
      setState(() {
        _schedule = results[0];
        _members = members;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _schedule = null;
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveSchedule(
    Future<Map<String, dynamic>> Function(String, int) write, {
    String? selectDate,
  }) async {
    if (!_canEdit || _busy) return;
    setState(() => _busy = true);
    try {
      final saved = await write(
        await widget.getAccessToken(),
        _schedule!['revision'] as int,
      );
      if (mounted) {
        setState(() {
          _schedule = saved;
          if (selectDate != null) _selectedDate = selectDate;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.toString()),
            action: SnackBarAction(label: 'Refresh', onPressed: _load)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(
    List<Map<String, dynamic>> groups,
    List<Map<String, dynamic>> rows, {
    String? selectDate,
  }) =>
      _saveSchedule(
        (token, revision) => widget.api.eventSchedule(
          event: widget.event,
          rosterGroupId: widget.rosterGroupId,
          accessToken: token,
          changes: {'groups': groups, 'rows': rows, 'revision': revision},
        ),
        selectDate: selectDate,
      );

  Future<void> _editGroup([Map<String, dynamic>? existing]) async {
    final form = GlobalKey<FormState>();
    final name =
        TextEditingController(text: existing?['name'] as String? ?? '');
    final selected = Set<String>.from(existing?['members'] as List? ?? []);
    String? lead = existing?['lead'] as String?;
    final used = _groups
        .where((g) => g['id'] != existing?['id'])
        .expand((g) => (g['members'] as List).cast<String>())
        .toSet();
    final available = {
      if (existing == null ||
          existing['roster_group_id'] == widget.rosterGroupId)
        ..._members,
      for (final person in selected)
        person: _members[person] ?? '$person (left roster)'
    };
    final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: Text(existing == null
                      ? 'Add schedule group'
                      : 'Edit schedule group'),
                  content: SizedBox(
                      width: 440,
                      child: Form(
                          key: form,
                          child: SingleChildScrollView(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                TextFormField(
                                    controller: name,
                                    maxLength: 100,
                                    decoration: const InputDecoration(
                                        labelText: 'Group name'),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty)
                                        return 'Enter a group name';
                                      if (_groups.any((g) =>
                                          g['id'] != existing?['id'] &&
                                          (g['name'] as String).toLowerCase() ==
                                              value.trim().toLowerCase())) {
                                        return 'Choose a unique group name';
                                      }
                                      return null;
                                    }),
                                const Text(
                                    'Choose people from your group, then select one lead.'),
                                if (available.isEmpty)
                                  const Text(
                                      'No roster members available. Refresh and try again.'),
                                for (final person in available.entries)
                                  CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(person.value),
                                      subtitle: used.contains(person.key)
                                          ? const Text('Already assigned')
                                          : null,
                                      value: selected.contains(person.key),
                                      onChanged: used.contains(person.key)
                                          ? null
                                          : (value) => update(() {
                                                if (value == true) {
                                                  selected.add(person.key);
                                                } else {
                                                  selected.remove(person.key);
                                                  if (lead == person.key)
                                                    lead = null;
                                                }
                                              })),
                                DropdownButtonFormField<String>(
                                    key:
                                        ValueKey('${selected.join(',')}/$lead'),
                                    initialValue: lead,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Lead (required)'),
                                    items: selected
                                        .map((person) => DropdownMenuItem(
                                            value: person,
                                            child: Text(
                                                available[person] ?? person,
                                                overflow:
                                                    TextOverflow.ellipsis)))
                                        .toList(),
                                    onChanged: (value) =>
                                        update(() => lead = value),
                                    validator: (value) => value == null
                                        ? 'Select one lead'
                                        : null),
                              ])))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (!form.currentState!.validate()) return;
                          Navigator.pop(dialogContext, <String, dynamic>{
                            'id': existing?['id'] ?? _id(),
                            'name': name.text.trim(),
                            'roster_group_id': existing?['roster_group_id'] ??
                                widget.rosterGroupId,
                            'members': selected.toList(),
                            'lead': lead
                          });
                        },
                        child: const Text('Save group')),
                  ],
                )));
    // Dialog route animations can still reference the text controller.
    if (result != null && mounted) {
      await _save(
          [..._groups.where((g) => g['id'] != result['id']), result], _rows);
    }
  }

  Future<void> _editRow(String? selectedDate,
      {Map<String, dynamic>? existing}) async {
    final controllers = {
      for (final group in _groups)
        group['id'] as String: TextEditingController(
            text: (existing?['activities'] as Map?)?[group['id']] as String? ??
                '')
    };
    final initialDate = existing?['date'] as String? ?? selectedDate;
    var date =
        initialDate == null ? DateTime.now() : DateTime.parse(initialDate);
    var time = existing == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(
            hour: int.parse((existing['time'] as String).split(':')[0]),
            minute: int.parse((existing['time'] as String).split(':')[1]));
    String dateText() =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    String timeText() =>
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    String? error;
    final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: Text(
                      existing == null ? 'Add time slot' : 'Edit time slot'),
                  content: SizedBox(
                      width: 480,
                      child: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(dateText()),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                      context: context,
                                      initialDate: date,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100));
                                  if (picked != null && context.mounted)
                                    update(() => date = picked);
                                }),
                            OutlinedButton.icon(
                                icon: const Icon(Icons.schedule),
                                label: Text(time.format(context)),
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                      context: context, initialTime: time);
                                  if (picked != null && context.mounted)
                                    update(() => time = picked);
                                }),
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                    'Enter an activity for each group. Times use the event’s local time.')),
                            for (final group in _groups)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextField(
                                      controller: controllers[group['id']],
                                      maxLength: 500,
                                      decoration: InputDecoration(
                                          labelText: group['name'] as String,
                                          hintText:
                                              'e.g. Pit scouting, Lunch, Workshop'))),
                            if (error != null)
                              Text(error!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                          ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (_rows.any((row) =>
                              row['id'] != existing?['id'] &&
                              row['date'] == dateText() &&
                              row['time'] == timeText())) {
                            update(() => error =
                                'This time already exists. Edit that row instead.');
                            return;
                          }
                          Navigator.pop(dialogContext, <String, dynamic>{
                            'id': existing?['id'] ?? _id(),
                            'date': dateText(),
                            'time': timeText(),
                            'activities': {
                              for (final entry in controllers.entries)
                                entry.key: entry.value.text.trim()
                            }
                          });
                        },
                        child: const Text('Save time slot')),
                  ],
                )));
    if (result != null && mounted) {
      await _save(
        _groups,
        [..._rows.where((row) => row['id'] != result['id']), result],
        selectDate: result['date'] as String,
      );
    }
  }

  Future<void> _remove(
      {Map<String, dynamic>? group, Map<String, dynamic>? row}) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(group != null
                    ? 'Delete ${group['name']}?'
                    : 'Delete time slot?'),
                content: Text(group != null
                    ? 'This removes the group, its activities, and its attendance marks.'
                    : 'This removes the time slot, its activities, and its attendance marks.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'))
                ]));
    if (confirmed != true || !mounted) return;
    final rows = _maps(jsonDecode(jsonEncode(_rows)));
    if (group != null) {
      for (final row in rows) {
        (row['activities'] as Map).remove(group['id']);
      }
    }
    await _save(_groups.where((g) => g['id'] != group?['id']).toList(),
        rows.where((r) => r['id'] != row?['id']).toList());
  }

  void _markAttendance(
    Map<String, dynamic> row,
    Map<String, dynamic> group,
    String student,
    String status,
  ) {
    _saveSchedule(
      (token, revision) => widget.api.markScheduleAttendance(
        event: widget.event,
        rosterGroupId: widget.rosterGroupId,
        accessToken: token,
        revision: revision,
        rowId: row['id'] as String,
        groupId: group['id'] as String,
        student: student,
        status: status.isEmpty ? null : status,
      ),
    );
  }

  Future<void> _exportCsv() async {
    if (_exporting || _busy) return;
    setState(() => _exporting = true);
    try {
      final csv = buildEventScheduleCsv(_groups, _rows);
      final event = widget.event.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await FileSaver.instance.saveFile(
        name: '${event}_scouting_schedule',
        bytes: Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export the schedule. $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  List<String> _scheduleDates(List<Map<String, dynamic>> rows) {
    final dates = rows.map((row) => row['date'] as String).toSet();
    final start = DateTime.tryParse('${widget.eventStart}T00:00:00Z');
    final end = DateTime.tryParse('${widget.eventEnd}T00:00:00Z');
    final first = start ?? end;
    if (first != null) {
      final last = end != null && !end.isBefore(first) ? end : first;
      for (var day = first;
          !day.isAfter(last);
          day = day.add(const Duration(days: 1))) {
        dates.add(day.toIso8601String().split('T').first);
      }
    }
    return dates.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    if (_schedule == null) {
      return Center(
        child: _busy
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error ?? 'Schedule unavailable',
                      textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Try again')),
                ]),
              ),
      );
    }

    final theme = Theme.of(context);
    final groups = _groups;
    final rows = _rows;
    final dates = _scheduleDates(rows);
    final date =
        dates.contains(_selectedDate) ? _selectedDate : dates.firstOrNull;
    final dayRows = rows.where((row) => row['date'] == date).toList();
    final attendance = _canEdit && _showAttendance;
    final localizations = MaterialLocalizations.of(context);
    final spansYears = dates.isNotEmpty &&
        DateTime.parse(dates.first).year != DateTime.parse(dates.last).year;

    return Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                return CustomScrollView(
                  key: PageStorageKey(attendance ? 'attendance' : 'schedule'),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 32,
                        compact ? 16 : 28,
                        compact ? 16 : 32,
                        24,
                      ),
                      sliver: SliverMainAxisGroup(slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (attendance)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        setState(() => _showAttendance = false),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Scouting schedule'),
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      attendance
                                          ? 'Attendance'
                                          : 'Scouting schedule',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _busy ? null : _load,
                                    tooltip: 'Refresh schedule',
                                    icon: const Icon(Icons.refresh),
                                  ),
                                ],
                              ),
                              Text(
                                attendance
                                    ? 'Private to your roster’s admins and owners.'
                                    : 'Activities by group in the event’s local time.',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                              if (!attendance) ...[
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (_canEdit)
                                      FilledButton.icon(
                                        onPressed: _busy || groups.isEmpty
                                            ? null
                                            : () => _editRow(date),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add time slot'),
                                      ),
                                    if (_canEdit)
                                      OutlinedButton.icon(
                                        onPressed:
                                            _busy ? null : () => _editGroup(),
                                        icon: const Icon(
                                            Icons.group_add_outlined),
                                        label: const Text('Add group'),
                                      ),
                                    if (_canEdit)
                                      TextButton.icon(
                                        onPressed: _busy
                                            ? null
                                            : () => setState(
                                                () => _showAttendance = true),
                                        icon: const Icon(Icons.lock_outline),
                                        label: const Text('Attendance'),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed:
                                          _busy || _exporting || rows.isEmpty
                                              ? null
                                              : _exportCsv,
                                      icon: const Icon(Icons.download_outlined),
                                      label: Text(_exporting
                                          ? 'Exporting…'
                                          : 'Export CSV'),
                                    ),
                                  ],
                                ),
                              ],
                              if (!attendance && groups.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _groupRoster(groups),
                              ],
                              const SizedBox(height: 20),
                              if (dates.isNotEmpty)
                                DefaultTabController(
                                  key: ValueKey((dates.join(','), date)),
                                  length: dates.length,
                                  initialIndex: dates.indexOf(date!),
                                  child: TabBar(
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    onTap: (index) => setState(() {
                                      _selectedDate = dates[index];
                                      _attendanceSlot = null;
                                    }),
                                    tabs: [
                                      for (final day in dates)
                                        Tab(
                                          child: Semantics(
                                            excludeSemantics: true,
                                            label: localizations.formatFullDate(
                                                DateTime.parse(day)),
                                            child: Text(spansYears
                                                ? localizations.formatShortDate(
                                                    DateTime.parse(day))
                                                : localizations
                                                    .formatShortMonthDay(
                                                        DateTime.parse(day))),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (attendance)
                          SliverToBoxAdapter(
                              child: _attendancePanel(dayRows, groups))
                        else if (dayRows.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                groups.isEmpty && _canEdit
                                    ? 'Add a group with a lead to start planning.'
                                    : date == null
                                        ? 'No time slots have been scheduled yet.'
                                        : 'No time slots scheduled for this day.',
                              ),
                            ),
                          )
                        else
                          SliverList.builder(
                            itemCount: dayRows.length,
                            itemBuilder: (context, index) => _timeSlot(
                              dayRows[index],
                              groups,
                              compact: compact,
                            ),
                          ),
                      ]),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _groupRoster(List<Map<String, dynamic>> groups) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.groups_outlined),
      title: const Text('Groups and leads'),
      subtitle:
          Text('${groups.length} ${groups.length == 1 ? 'group' : 'groups'}'),
      children: [
        for (final group in groups)
          ListTile(
            contentPadding: const EdgeInsetsDirectional.only(start: 16),
            title: Text(group['name'] as String,
                style: theme.textTheme.titleMedium),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final person
                      in (group['members'] as List).cast<String>())
                    Text(
                      '${_members[person] ?? person}${person == group['lead'] ? ' · Lead' : ''}',
                      style: person == group['lead']
                          ? const TextStyle(fontWeight: FontWeight.w700)
                          : null,
                    ),
                ],
              ),
            ),
            trailing: _canEdit
                ? _editMenu(
                    'Manage group',
                    onEdit: () => _editGroup(group),
                    onDelete: () => _remove(group: group),
                  )
                : null,
          ),
      ],
    );
  }

  Widget _editMenu(
    String tooltip, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return PopupMenuButton<bool>(
      enabled: !_busy,
      tooltip: tooltip,
      onSelected: (edit) => edit ? onEdit() : onDelete(),
      itemBuilder: (context) => const [
        PopupMenuItem(value: true, child: Text('Edit')),
        PopupMenuItem(value: false, child: Text('Delete')),
      ],
    );
  }

  String _activity(Map<String, dynamic> row, Map<String, dynamic> group) =>
      ((row['activities'] as Map)[group['id']] as String? ?? '').trim();

  Widget _timeSlot(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> groups, {
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final time = Text(
      _formatTime(context, row['time'] as String),
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final actions = _canEdit
        ? _editMenu(
            'Manage time slot',
            onEdit: () => _editRow(null, existing: row),
            onDelete: () => _remove(row: row),
          )
        : null;
    final scheduled = groups.where((group) => _activity(row, group).isNotEmpty);
    final activities = LayoutBuilder(builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= 540;
      const gap = 12.0;
      final width =
          twoColumns ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: gap,
        runSpacing: 8,
        children: [
          for (final group in scheduled)
            SizedBox(
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group['name'] as String,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      const SizedBox(height: 4),
                      Text(_activity(row, group),
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
            ),
          if (scheduled.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('No activities assigned'),
            ),
        ],
      );
    });

    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(child: time),
                      if (actions != null) actions
                    ]),
                    const SizedBox(height: 8),
                    activities,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 168, child: time),
                    const SizedBox(width: 12),
                    Expanded(child: activities),
                    if (actions != null) ...[const SizedBox(width: 8), actions],
                  ],
                ),
        ),
      ],
    );
  }

  static const _attendanceLabels = {
    '': 'Unmarked',
    'tardy': 'Tardy',
    'extreme_tardy': 'Extreme Tardy',
    'absent': 'Absent',
  };

  Widget _attendancePanel(
    List<Map<String, dynamic>> rows,
    List<Map<String, dynamic>> groups,
  ) {
    final theme = Theme.of(context);
    final rosterGroups = groups.where(
      (group) => group['roster_group_id'] == widget.rosterGroupId,
    );
    final slots = rows
        .where((row) =>
            rosterGroups.any((group) => _activity(row, group).isNotEmpty))
        .toList();
    final row =
        slots.where((row) => row['id'] == _attendanceSlot).firstOrNull ??
            slots.firstOrNull;
    if (row == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('No activities are scheduled for your roster on this day.'),
      );
    }

    final assigned =
        rosterGroups.where((group) => _activity(row, group).isNotEmpty);
    final marks = {
      for (final mark in _maps(_schedule?['attendance']))
        if (mark['row_id'] == row['id'])
          (mark['group_id'], mark['student']): mark['status'] as String,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tardy is less than 5 min late. Extreme Tardy is more than 10 min late. '
            'Absent means the student missed the activity.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DropdownButtonFormField<String>(
                key: ValueKey(row['id']),
                initialValue: row['id'] as String,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Time slot'),
                items: [
                  for (final slot in slots)
                    DropdownMenuItem(
                      value: slot['id'] as String,
                      child: Text(_formatTime(context, slot['time'] as String)),
                    ),
                ],
                onChanged:
                    _busy ? null : (id) => setState(() => _attendanceSlot = id),
              ),
            ),
          ),
          for (final group in assigned) ...[
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Text(
                '${group['name']} · ${_activity(row, group)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final student in (group['members'] as List).cast<String>())
              _attendanceStudent(
                student,
                marks[(group['id'], student)] ?? '',
                onSelected: (status) =>
                    _markAttendance(row, group, student, status),
              ),
          ],
        ],
      ),
    );
  }

  Widget _attendanceStudent(
    String student,
    String status, {
    required ValueChanged<String> onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final name = _members[student] ?? student;
    final label = _attendanceLabels[status] ?? 'Unmarked';
    return Column(
      children: [
        const Divider(),
        PopupMenuButton<String>(
          enabled: !_busy,
          initialValue: status,
          tooltip: 'Attendance for $name',
          onSelected: (value) {
            if (value != status) onSelected(value);
          },
          itemBuilder: (context) => [
            for (final option in _attendanceLabels.entries)
              PopupMenuItem(value: option.key, child: Text(option.value)),
          ],
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(name),
            subtitle: Text(
              label,
              style: TextStyle(
                color: switch (status) {
                  'absent' || 'extreme_tardy' => scheme.error,
                  'tardy' => scheme.primary,
                  _ => scheme.onSurfaceVariant,
                },
              ),
            ),
            trailing: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }

  String _formatTime(BuildContext context, String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))
        .format(context);
  }
}
