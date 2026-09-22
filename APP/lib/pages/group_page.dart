import 'package:app/APIService.dart';
import 'package:app/models/group_events.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GroupPage extends StatefulWidget {
  final String groupName;

  const GroupPage({
    required this.groupName,
    super.key,
  });

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  int _selectedIndex = 0;

  String get _cleanGroupName =>
      _cleanText(widget.groupName).replaceFirst(RegExp(r'^/+'), '');

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final groupName = _cleanGroupName;
        final currentGroup =
            _cleanText(auth.group).replaceFirst(RegExp(r'^/+'), '');
        final isLoggedIn = auth.isLoggedIn;
        final belongsToGroup = isLoggedIn &&
            currentGroup.isNotEmpty &&
            currentGroup.toLowerCase() == groupName.toLowerCase();
        final groupId = _cleanText(auth.groupId);
        final role = _cleanText(auth.role, fallback: 'member').toLowerCase();
        final currentUsername = _cleanText(auth.username);
        final isOwner = role == 'owner';
        final isAdmin = isOwner || role == 'admin';
        final isWide = MediaQuery.of(context).size.width >= 900;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          appBar: PolarForecastAppBar(
            extraText: groupName,
          ),
          bottomNavigationBar: belongsToGroup && groupId.isNotEmpty && !isWide
              ? _MobileNavigation(
                  selectedIndex: _selectedIndex,
                  onSelected: _selectPage,
                )
              : null,
          body: _buildBody(
            auth: auth,
            groupName: groupName,
            groupId: groupId,
            role: role,
            currentUsername: currentUsername,
            isAdmin: isAdmin,
            isOwner: isOwner,
            isLoggedIn: isLoggedIn,
            belongsToGroup: belongsToGroup,
            isWide: isWide,
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required AuthService auth,
    required String groupName,
    required String groupId,
    required String role,
    required String currentUsername,
    required bool isAdmin,
    required bool isOwner,
    required bool isLoggedIn,
    required bool belongsToGroup,
    required bool isWide,
  }) {
    if (!isLoggedIn) {
      return _LoginRequiredView(auth: auth);
    }

    if (!belongsToGroup) {
      return _AccessDeniedView(groupName: groupName);
    }

    if (groupId.isEmpty) {
      return const _ErrorState(
        title: 'Team information is incomplete',
        message:
            'Your account is connected to this team, but no group ID was provided. Refresh your login and try again.',
      );
    }

    final content = _GroupContent(
      selectedIndex: _selectedIndex,
      groupName: groupName,
      groupId: groupId,
      role: role,
      currentUsername: currentUsername,
      isAdmin: isAdmin,
      isOwner: isOwner,
    );

    if (!isWide) {
      return content;
    }

    return Row(
      children: [
        _DesktopNavigation(
          selectedIndex: _selectedIndex,
          groupName: groupName,
          role: role,
          onSelected: _selectPage,
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: _PolarColors.border,
        ),
        Expanded(child: content),
      ],
    );
  }

  void _selectPage(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }
}

class _GroupContent extends StatelessWidget {
  final int selectedIndex;
  final String groupName;
  final String groupId;
  final String role;
  final String currentUsername;
  final bool isAdmin;
  final bool isOwner;

  const _GroupContent({
    required this.selectedIndex,
    required this.groupName,
    required this.groupId,
    required this.role,
    required this.currentUsername,
    required this.isAdmin,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GroupHero(
          groupName: groupName,
          role: role,
          selectedIndex: selectedIndex,
        ),
        Expanded(
          child: IndexedStack(
            index: selectedIndex,
            children: [
              _GroupEventsView(
                api: APIService(),
                groupId: groupId,
                groupName: groupName,
                isAdmin: isAdmin,
              ),
              _GroupPeopleView(
                api: APIService(),
                groupId: groupId,
                requesterUsername: currentUsername,
                isOwner: isOwner,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupHero extends StatelessWidget {
  final String groupName;
  final String role;
  final int selectedIndex;

  const _GroupHero({
    required this.groupName,
    required this.role,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final pageTitle =
        selectedIndex == 0 ? 'Event workspace' : 'Scout directory';
    final pageDescription = selectedIndex == 0
        ? 'Open scouting events, organize your schedule, and keep the team focused.'
        : 'Manage scouts, review permissions, and share the team join code.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: LiquidGlassPanel(
          padding: const EdgeInsets.all(22),
          borderRadius: BorderRadius.circular(24),
          tint: LiquidGlassColors.secondary,
          blurSigma: 24,
          child: Wrap(
            spacing: 18,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _PolarColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: _PolarColors.primary.withOpacity(0.32),
                        ),
                      ),
                      child: const Icon(
                        Icons.ac_unit_rounded,
                        color: _PolarColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pageTitle,
                            style: const TextStyle(
                              color: _PolarColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            pageDescription,
                            style: const TextStyle(
                              color: _PolarColors.mutedText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _RoleBadge(role: role),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  final int selectedIndex;
  final String groupName;
  final String role;
  final ValueChanged<int> onSelected;

  const _DesktopNavigation({
    required this.selectedIndex,
    required this.groupName,
    required this.role,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: LiquidGlassPanel(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        tint: LiquidGlassColors.secondary,
        blurSigma: 26,
        shadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LiquidGlassPanel(
              padding: const EdgeInsets.all(15),
              borderRadius: BorderRadius.circular(18),
              blurSigma: 14,
              shadow: false,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 21,
                    backgroundColor: _PolarColors.primarySoft,
                    child: Icon(
                      Icons.groups_2_rounded,
                      color: _PolarColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _capitalize(role),
                          style: const TextStyle(
                            color: _PolarColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _NavigationButton(
              selected: selectedIndex == 0,
              icon: Icons.calendar_month_rounded,
              label: 'Events',
              onTap: () => onSelected(0),
            ),
            const SizedBox(height: 8),
            _NavigationButton(
              selected: selectedIndex == 1,
              icon: Icons.group_rounded,
              label: 'Scouts',
              onTap: () => onSelected(1),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'POLARFORECAST TEAM HUB',
                style: TextStyle(
                  color: _PolarColors.subtleText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _PolarColors.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? _PolarColors.primary : _PolarColors.mutedText,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _PolarColors.mutedText,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MobileNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPanel(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      blurSigma: 24,
      tint: LiquidGlassColors.secondary,
      shadow: false,
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 70,
          backgroundColor: Colors.transparent,
          indicatorColor: _PolarColors.primarySoft,
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
            return TextStyle(
              color: selected ? Colors.white : _PolarColors.mutedText,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(MaterialState.selected)
                  ? _PolarColors.primary
                  : _PolarColors.mutedText,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          backgroundColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'Scouts',
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupEventsView extends StatefulWidget {
  final APIService api;
  final String groupId;
  final String groupName;
  final bool isAdmin;

  const _GroupEventsView({
    required this.api,
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
  });

  @override
  State<_GroupEventsView> createState() => _GroupEventsViewState();
}

class _GroupEventsViewState extends State<_GroupEventsView> {
  late Future<_EventsPayload> _payloadFuture;
  final Set<String> _busyEventCodes = <String>{};
  bool _addingEvent = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant _GroupEventsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _reload();
    }
  }

  void _reload() {
    _payloadFuture = _fetchPayload();
  }

  Future<_EventsPayload> _fetchPayload() async {
    final eventsFuture = widget.api.getGroupEvents(widget.groupId);
    final keysFuture = widget.api.fetchEventKeys();

    return _EventsPayload(
      groupEvents: await eventsFuture,
      eventKeys: await keysFuture,
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _payloadFuture;
    } catch (_) {
      // FutureBuilder shows the actual error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EventsPayload>(
      future: _payloadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState(message: 'Loading team events...');
        }

        if (snapshot.hasError) {
          return _ErrorState(
            title: 'Could not load events',
            message: snapshot.error.toString(),
            onRetry: () => setState(_reload),
          );
        }

        final payload = snapshot.data!;
        final eventMap = <String, EventSearchKey>{
          for (final key in payload.eventKeys) key.key: key,
        };

        final events = List<String>.from(payload.groupEvents.events)
          ..sort((a, b) {
            final aName = eventMap[a]?.display ?? a;
            final bName = eventMap[b]?.display ?? b;
            return aName.toLowerCase().compareTo(bName.toLowerCase());
          });

        return RefreshIndicator(
          color: _PolarColors.primary,
          backgroundColor: _PolarColors.surfaceRaised,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    eyebrow: '',
                    title: 'Team events',
                    description: widget.isAdmin
                        ? 'Open an event or update which competitions are available to your scouts.'
                        : 'Open an event to view statistics, predictions, and scouting forms.',
                    trailing: _CountPill(
                      count: events.length,
                      singular: 'event',
                      plural: 'events',
                    ),
                  ),
                ),
              ),
              if (events.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No events yet',
                    message: widget.isAdmin
                        ? 'Add your first event to make it available to the team.'
                        : 'A team owner or admin has not added any events yet.',
                    action: widget.isAdmin
                        ? FilledButton.icon(
                            onPressed: _addingEvent
                                ? null
                                : () => _addEvent(
                                      events.toSet(),
                                      payload.eventKeys,
                                    ),
                            icon: _addingEvent
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_rounded),
                            label: Text(
                              _addingEvent ? 'Adding...' : 'Add event',
                            ),
                          )
                        : null,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) {
                          return const SizedBox(height: 12);
                        }

                        final eventIndex = index ~/ 2;
                        final eventCode = events[eventIndex];
                        final event = eventMap[eventCode];
                        final display = event?.display ?? eventCode;
                        final busy = _busyEventCodes.contains(eventCode);

                        return _EventCard(
                          eventCode: eventCode,
                          displayName: display,
                          canRemove: widget.isAdmin,
                          busy: busy,
                          onOpen: busy
                              ? null
                              : () => Navigator.pushNamed(
                                    context,
                                    '/event/$eventCode',
                                  ),
                          onRemove: busy
                              ? null
                              : () => _confirmRemoveEvent(
                                    eventCode: eventCode,
                                    displayName: display,
                                  ),
                        );
                      },
                      childCount: events.length * 2 - 1,
                    ),
                  ),
                ),
                if (widget.isAdmin)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    sliver: SliverToBoxAdapter(
                      child: FilledButton.icon(
                        onPressed: _addingEvent
                            ? null
                            : () => _addEvent(
                                  events.toSet(),
                                  payload.eventKeys,
                                ),
                        icon: _addingEvent
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_rounded),
                        label: Text(
                          _addingEvent
                              ? 'Adding event...'
                              : 'Add another event',
                        ),
                      ),
                    ),
                  )
                else
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 110),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addEvent(
    Set<String> existingEvents,
    List<EventSearchKey> allEvents,
  ) async {
    if (_addingEvent) return;

    final availableEvents =
        allEvents.where((event) => !existingEvents.contains(event.key)).toList()
          ..sort(
            (a, b) => a.display.toLowerCase().compareTo(
                  b.display.toLowerCase(),
                ),
          );

    if (availableEvents.isEmpty) {
      _showSnackBar(
        context,
        'Every available event has already been added to this team.',
      );
      return;
    }

    final selected = await showDialog<EventSearchKey>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (dialogContext) {
        return _EventSearchDialog(events: availableEvents);
      },
    );

    if (!mounted || selected == null) return;

    // Keep this check in case the team event list changed while the dialog
    // was open.
    if (existingEvents.contains(selected.key)) {
      _showSnackBar(
        context,
        '${selected.display} is already in this team.',
      );
      return;
    }

    setState(() => _addingEvent = true);

    try {
      await widget.api.addGroupEvent(
        groupId: widget.groupId,
        eventCode: selected.key,
      );

      if (!mounted) return;
      setState(() {
        _addingEvent = false;
        _reload();
      });
      _showSnackBar(context, '${selected.display} was added.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _addingEvent = false);
      _showSnackBar(
        context,
        'Could not add the event: $error',
        isError: true,
      );
    }
  }

  Future<void> _confirmRemoveEvent({
    required String eventCode,
    required String displayName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _PolarColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: _PolarColors.border),
          ),
          title: const Text(
            'Remove event?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '$displayName will no longer appear in this team workspace. Existing scouting data is not deleted by this action.',
            style: const TextStyle(color: _PolarColors.mutedText, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _PolarColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _removeEvent(eventCode, displayName);
  }

  Future<void> _removeEvent(String eventCode, String displayName) async {
    setState(() => _busyEventCodes.add(eventCode));

    try {
      await widget.api.removeGroupEvent(
        groupId: widget.groupId,
        eventCode: eventCode,
      );

      if (!mounted) return;
      setState(() {
        _busyEventCodes.remove(eventCode);
        _reload();
      });
      _showSnackBar(context, '$displayName was removed.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busyEventCodes.remove(eventCode));
      _showSnackBar(
        context,
        'Could not remove the event: $error',
        isError: true,
      );
    }
  }
}

class _EventSearchDialog extends StatefulWidget {
  final List<EventSearchKey> events;

  const _EventSearchDialog({required this.events});

  @override
  State<_EventSearchDialog> createState() => _EventSearchDialogState();
}

class _EventSearchDialogState extends State<_EventSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<EventSearchKey> get _filteredEvents {
    final normalizedQuery = _query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return widget.events;
    }

    return widget.events.where((event) {
      final display = event.display.toLowerCase();
      final key = event.key.toLowerCase();

      return display.contains(normalizedQuery) || key.contains(normalizedQuery);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _filteredEvents;
    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 28,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: screenSize.height * 0.82,
        ),
        child: LiquidGlassPanel(
          borderRadius: BorderRadius.circular(26),
          tint: LiquidGlassColors.secondary,
          blurSigma: 28,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _PolarColors.primary.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.event_available_rounded,
                          color: _PolarColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add an event',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Search by event name or event code.',
                              style: TextStyle(
                                color: _PolarColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _PolarColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) => setState(() => _query = value),
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      hintStyle: const TextStyle(
                        color: _PolarColors.mutedText,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _PolarColors.mutedText,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: _PolarColors.mutedText,
                              ),
                            ),
                      filled: true,
                      fillColor: _PolarColors.surfaceRaised,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _PolarColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _PolarColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Row(
                    children: [
                      Text(
                        '${filteredEvents.length} ${filteredEvents.length == 1 ? 'event' : 'events'}',
                        style: const TextStyle(
                          color: _PolarColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  color: _PolarColors.border,
                ),
                Flexible(
                  child: filteredEvents.isEmpty
                      ? const _EventSearchEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: filteredEvents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];

                            return Material(
                              color: Colors.white.withOpacity(0.055),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.pop(context, event),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _PolarColors.primary
                                              .withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.emoji_events_outlined,
                                          color: _PolarColors.primary,
                                          size: 21,
                                        ),
                                      ),
                                      const SizedBox(width: 13),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.display,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              event.key,
                                              style: const TextStyle(
                                                color: _PolarColors.mutedText,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.25,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: _PolarColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventSearchEmptyState extends StatelessWidget {
  const _EventSearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: _PolarColors.mutedText,
            ),
            SizedBox(height: 12),
            Text(
              'No matching events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try searching with a different event name or code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _PolarColors.mutedText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String eventCode;
  final String displayName;
  final bool canRemove;
  final bool busy;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  const _EventCard({
    required this.eventCode,
    required this.displayName,
    required this.canRemove,
    required this.busy,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPanel(
      borderRadius: BorderRadius.circular(20),
      blurSigma: 18,
      shadow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _PolarColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _PolarColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.stadium_rounded,
                    color: _PolarColors.primary,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        eventCode.toUpperCase(),
                        style: const TextStyle(
                          color: _PolarColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: _PolarColors.primary,
                      ),
                    ),
                  )
                else ...[
                  if (canRemove)
                    IconButton(
                      tooltip: 'Remove event',
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: _PolarColors.danger,
                      ),
                    ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _PolarColors.subtleText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupPeopleView extends StatefulWidget {
  final APIService api;
  final String groupId;
  final String requesterUsername;
  final bool isOwner;

  const _GroupPeopleView({
    required this.api,
    required this.groupId,
    required this.requesterUsername,
    required this.isOwner,
  });

  @override
  State<_GroupPeopleView> createState() => _GroupPeopleViewState();
}

class _GroupPeopleViewState extends State<_GroupPeopleView> {
  late Future<_PeoplePayload> _payloadFuture;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _busyUsernames = <String>{};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant _GroupPeopleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _reload();
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim().toLowerCase();
    if (nextQuery == _query) return;
    setState(() => _query = nextQuery);
  }

  void _reload() {
    _payloadFuture = _fetchPayload();
  }

  Future<_PeoplePayload> _fetchPayload() async {
    String? joinCode;
    Object? joinCodeError;

    try {
      joinCode = (await widget.api.getJoinCodeFromGroupID(widget.groupId))
          .replaceAll('"', '')
          .trim();
    } catch (error) {
      joinCodeError = error;
    }

    final members = await widget.api.fetchGroupMembers(widget.groupId);

    return _PeoplePayload(
      joinCode: joinCode,
      joinCodeError: joinCodeError,
      members: members,
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _payloadFuture;
    } catch (_) {
      // FutureBuilder shows the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PeoplePayload>(
      future: _payloadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState(message: 'Loading team members...');
        }

        if (snapshot.hasError) {
          return _ErrorState(
            title: 'Could not load the team directory',
            message: snapshot.error.toString(),
            onRetry: () => setState(_reload),
          );
        }

        final payload = snapshot.data!;
        final groupedMembers = _normalizedMembers(payload.members);
        final filteredMembers = <String, List<dynamic>>{
          for (final entry in groupedMembers.entries)
            entry.key: entry.value.where(_matchesSearch).toList(),
        };
        final totalMembers = groupedMembers.values.fold<int>(
          0,
          (total, members) => total + members.length,
        );
        final visibleMembers = filteredMembers.values.fold<int>(
          0,
          (total, members) => total + members.length,
        );

        return RefreshIndicator(
          color: _PolarColors.primary,
          backgroundColor: _PolarColors.surfaceRaised,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    eyebrow: 'TEAM DIRECTORY',
                    title: 'Scouts',
                    description:
                        'Find teammates, review roles, and share access with new scouts.',
                    trailing: _CountPill(
                      count: totalMembers,
                      singular: 'person',
                      plural: 'people',
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _JoinCodeCard(
                    code: payload.joinCode,
                    error: payload.joinCodeError,
                    onRetry: () => setState(_reload),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search team members',
                      hintStyle:
                          const TextStyle(color: _PolarColors.subtleText),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _PolarColors.mutedText,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: _searchController.clear,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: _PolarColors.mutedText,
                              ),
                            ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: _PolarColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: _PolarColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _PolarColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_query.isNotEmpty && visibleMembers == 0)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'No members found',
                    message: 'Try a different name, username, or role.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _RoleSection(
                          title: 'Owner',
                          role: 'owner',
                          members: filteredMembers['owner'] ?? const [],
                          canManageRoles: false,
                          busyUsernames: _busyUsernames,
                          onRoleChanged: _changeMemberRole,
                        ),
                        _RoleSection(
                          title: 'Admins',
                          role: 'admin',
                          members: filteredMembers['admin'] ?? const [],
                          canManageRoles: widget.isOwner,
                          busyUsernames: _busyUsernames,
                          onRoleChanged: _changeMemberRole,
                        ),
                        _RoleSection(
                          title: 'Members',
                          role: 'member',
                          members: filteredMembers['member'] ?? const [],
                          canManageRoles: widget.isOwner,
                          busyUsernames: _busyUsernames,
                          onRoleChanged: _changeMemberRole,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeMemberRole(
    dynamic member,
    String newRole,
  ) async {
    if (!widget.isOwner) {
      _showSnackBar(
        context,
        'Only the team owner can change scout roles.',
        isError: true,
      );
      return;
    }

    if (widget.requesterUsername.isEmpty) {
      _showSnackBar(
        context,
        'Your account username is unavailable. Sign in again and retry.',
        isError: true,
      );
      return;
    }

    final map = _memberMap(member);
    final username = _cleanText(map['username']);
    final currentRole =
        _cleanText(map['role'], fallback: 'member').toLowerCase();

    if (username.isEmpty || _busyUsernames.contains(username)) return;
    if (currentRole == 'owner' || currentRole == newRole) return;

    final isPromotion = newRole == 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _PolarColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: _PolarColors.border),
          ),
          title: Text(
            isPromotion ? 'Promote @$username?' : 'Demote @$username?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            isPromotion
                ? '@$username will become an admin and will be able to manage team events.'
                : '@$username will return to the member role and lose admin permissions.',
            style: const TextStyle(
              color: _PolarColors.mutedText,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor:
                    isPromotion ? _PolarColors.primary : _PolarColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: Icon(
                isPromotion
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_remove_alt_1_rounded,
              ),
              label: Text(isPromotion ? 'Promote' : 'Demote'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyUsernames.add(username));

    try {
      await widget.api.setGroupMemberRole(
        groupId: widget.groupId,
        username: username,
        newRole: newRole,
        requesterUsername: widget.requesterUsername,
      );

      if (!mounted) return;
      setState(() {
        _busyUsernames.remove(username);
        _reload();
      });

      _showSnackBar(
        context,
        isPromotion
            ? '@$username was promoted to admin.'
            : '@$username was demoted to member.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busyUsernames.remove(username));
      _showSnackBar(
        context,
        "Could not change @$username's role: $error",
        isError: true,
      );
    }
  }

  bool _matchesSearch(dynamic member) {
    if (_query.isEmpty) return true;
    final map = _memberMap(member);
    final searchable = [
      map['username'],
      map['firstName'],
      map['first_name'],
      map['lastName'],
      map['last_name'],
      map['role'],
      map['team'],
    ].map((value) => _cleanText(value).toLowerCase()).join(' ');

    return searchable.contains(_query);
  }
}

class _JoinCodeCard extends StatelessWidget {
  final String? code;
  final Object? error;
  final VoidCallback onRetry;

  const _JoinCodeCard({
    required this.code,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasCode = code != null && code!.isNotEmpty;

    return LiquidGlassPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: LiquidGlassColors.secondary,
      blurSigma: 18,
      shadow: false,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _PolarColors.purpleSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: _PolarColors.purple,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Team join code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                if (hasCode)
                  SelectableText(
                    code!,
                    style: const TextStyle(
                      color: _PolarColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  )
                else
                  Text(
                    error == null
                        ? 'No join code is available.'
                        : 'The join code could not be loaded.',
                    style: const TextStyle(color: _PolarColors.mutedText),
                  ),
              ],
            ),
          ),
          if (hasCode)
            IconButton.filledTonal(
              tooltip: 'Copy join code',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code!));
                if (!context.mounted) return;
                _showSnackBar(context, 'Join code copied.');
              },
              icon: const Icon(Icons.copy_rounded),
            )
          else
            IconButton(
              tooltip: 'Retry',
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                color: _PolarColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleSection extends StatelessWidget {
  final String title;
  final String role;
  final List<dynamic> members;
  final bool canManageRoles;
  final Set<String> busyUsernames;
  final Future<void> Function(dynamic member, String newRole) onRoleChanged;

  const _RoleSection({
    required this.title,
    required this.role,
    required this.members,
    required this.canManageRoles,
    required this.busyUsernames,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LiquidGlassPanel(
        borderRadius: BorderRadius.circular(20),
        tint: _roleColor(role),
        blurSigma: 18,
        shadow: false,
        child: ExpansionTile(
          initiallyExpanded: true,
          collapsedIconColor: _PolarColors.mutedText,
          iconColor: _PolarColors.primary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: _RoleIcon(role: role),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${members.length} ${members.length == 1 ? 'person' : 'people'}',
            style: const TextStyle(
              color: _PolarColors.mutedText,
              fontSize: 12,
            ),
          ),
          children: [
            for (var index = 0; index < members.length; index++) ...[
              if (index > 0)
                const Divider(
                  height: 1,
                  indent: 58,
                  color: _PolarColors.border,
                ),
              _MemberTile(
                member: members[index],
                fallbackRole: role,
                canManageRole: canManageRoles && role != 'owner',
                busy: busyUsernames.contains(
                  _cleanText(_memberMap(members[index])['username']),
                ),
                onRoleChanged: (newRole) =>
                    onRoleChanged(members[index], newRole),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final dynamic member;
  final String fallbackRole;
  final bool canManageRole;
  final bool busy;
  final Future<void> Function(String newRole) onRoleChanged;

  const _MemberTile({
    required this.member,
    required this.fallbackRole,
    required this.canManageRole,
    required this.busy,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final map = _memberMap(member);
    final username = _cleanText(map['username'], fallback: 'Unknown member');
    final firstName = _cleanText(map['firstName'] ?? map['first_name']);
    final lastName = _cleanText(map['lastName'] ?? map['last_name']);
    final fullName =
        [firstName, lastName].where((part) => part.isNotEmpty).join(' ').trim();
    final role = _cleanText(map['role'], fallback: fallbackRole).toLowerCase();
    final displayName = fullName.isEmpty ? username : fullName;
    final subtitle = fullName.isEmpty ? _capitalize(role) : '@$username';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: _roleColor(role).withOpacity(0.15),
        child: Text(
          _initials(displayName),
          style: TextStyle(
            color: _roleColor(role),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _PolarColors.mutedText),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmallRoleBadge(role: role),
          if (canManageRole) ...[
            const SizedBox(width: 8),
            _RoleActionButton(
              currentRole: role,
              busy: busy,
              onPressed: () => onRoleChanged(
                role == 'admin' ? 'member' : 'admin',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleActionButton extends StatelessWidget {
  final String currentRole;
  final bool busy;
  final VoidCallback onPressed;

  const _RoleActionButton({
    required this.currentRole,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = currentRole == 'admin';

    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isAdmin ? _PolarColors.danger : _PolarColors.primary,
          side: BorderSide(
            color: (isAdmin ? _PolarColors.danger : _PolarColors.primary)
                .withOpacity(0.55),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isAdmin
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 16,
              ),
        label: Text(
          busy ? 'Saving' : (isAdmin ? 'Demote' : 'Promote'),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoleIcon extends StatelessWidget {
  final String role;

  const _RoleIcon({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    final icon = switch (role) {
      'owner' => Icons.workspace_premium_rounded,
      'admin' => Icons.admin_panel_settings_rounded,
      _ => Icons.person_rounded,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            _capitalize(role),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallRoleBadge extends StatelessWidget {
  final String role;

  const _SmallRoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _capitalize(role),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _PolarColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: _PolarColors.mutedText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 14),
          trailing!,
        ],
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  final String singular;
  final String plural;

  const _CountPill({
    required this.count,
    required this.singular,
    required this.plural,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(999),
      blurSigma: 12,
      shadow: false,
      child: Text(
        '$count ${count == 1 ? singular : plural}',
        style: const TextStyle(
          color: _PolarColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoginRequiredView extends StatefulWidget {
  final AuthService auth;

  const _LoginRequiredView({required this.auth});

  @override
  State<_LoginRequiredView> createState() => _LoginRequiredViewState();
}

class _LoginRequiredViewState extends State<_LoginRequiredView> {
  bool _loggingIn = false;

  @override
  Widget build(BuildContext context) {
    return _CenteredPanel(
      icon: Icons.lock_outline_rounded,
      title: 'Sign in to continue',
      message:
          'Your team workspace contains private scouting information. Sign in to open it.',
      action: FilledButton.icon(
        onPressed: _loggingIn ? null : _login,
        icon: _loggingIn
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.login_rounded),
        label: Text(_loggingIn ? 'Signing in...' : 'Sign in'),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _loggingIn = true);
    try {
      await widget.auth.login();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(context, 'Login failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }
}

class _AccessDeniedView extends StatelessWidget {
  final String groupName;

  const _AccessDeniedView({required this.groupName});

  @override
  Widget build(BuildContext context) {
    return _CenteredPanel(
      icon: Icons.group_off_rounded,
      title: 'This team is not connected to your account',
      message:
          'You are signed in, but you are not currently a member of $groupName. Join the team or switch to the correct account.',
      action: OutlinedButton.icon(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Go back'),
      ),
    );
  }
}

class _CenteredPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _CenteredPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: LiquidGlassPanel(
            padding: const EdgeInsets.all(28),
            borderRadius: BorderRadius.circular(24),
            tint: LiquidGlassColors.secondary,
            blurSigma: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _PolarColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: _PolarColors.primary, size: 31),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _PolarColors.mutedText,
                    height: 1.5,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 22),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String message;

  const _LoadingState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _PolarColors.primary),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: _PolarColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredPanel(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: _PolarColors.surface,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: _PolarColors.border),
              ),
              child: Icon(icon, color: _PolarColors.mutedText, size: 31),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _PolarColors.mutedText,
                height: 1.45,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _EventsPayload {
  final GroupEvents groupEvents;
  final List<EventSearchKey> eventKeys;

  const _EventsPayload({
    required this.groupEvents,
    required this.eventKeys,
  });
}

class _PeoplePayload {
  final String? joinCode;
  final Object? joinCodeError;
  final Map<String, List<dynamic>> members;

  const _PeoplePayload({
    required this.joinCode,
    required this.joinCodeError,
    required this.members,
  });
}

Map<String, List<dynamic>> _normalizedMembers(
  Map<String, List<dynamic>> members,
) {
  List<dynamic> read(String singular, String plural) {
    return members[singular] ?? members[plural] ?? const <dynamic>[];
  }

  return {
    'owner': read('owner', 'owners'),
    'admin': read('admin', 'admins'),
    'member': read('member', 'members'),
  };
}

Map<String, dynamic> _memberMap(dynamic member) {
  if (member is Map<String, dynamic>) return member;
  if (member is Map) return Map<String, dynamic>.from(member);
  return const <String, dynamic>{};
}

String _cleanText(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _capitalize(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return clean;
  return '${clean[0].toUpperCase()}${clean.substring(1).toLowerCase()}';
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _roleColor(String role) {
  return switch (role.toLowerCase()) {
    'owner' => _PolarColors.gold,
    'admin' => _PolarColors.purple,
    _ => _PolarColors.primary,
  };
}

void _showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor:
            isError ? _PolarColors.dangerDark : _PolarColors.surfaceRaised,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isError ? _PolarColors.danger : _PolarColors.border,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: isError ? Colors.white : _PolarColors.success,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}

class _PolarColors {
  static const surface = LiquidGlassColors.glass;
  static const surfaceRaised = LiquidGlassColors.glassStrong;
  static const border = LiquidGlassColors.border;
  static const primary = LiquidGlassColors.primary;
  static const primarySoft = Color(0x4D69B8FF);
  static const purple = LiquidGlassColors.secondary;
  static const purpleSoft = Color(0x4D9B83FF);
  static const gold = Color(0xFFFFC75C);
  static const success = Color(0xFF62D7A5);
  static const danger = Color(0xFFFF6B7A);
  static const dangerDark = Color(0xFF7A2E39);
  static const mutedText = LiquidGlassColors.textMuted;
  static const subtleText = Color(0xFF718096);
}
