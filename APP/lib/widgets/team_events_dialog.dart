import 'package:app/models/global_ranking.dart';
import 'package:app/models/team_event.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';

class TeamEventsDialog extends StatefulWidget {
  final GlobalRanking team;
  final Future<List<TeamEvent>> Function() load;

  const TeamEventsDialog({super.key, required this.team, required this.load});

  @override
  State<TeamEventsDialog> createState() => _TeamEventsDialogState();
}

class _TeamEventsDialogState extends State<TeamEventsDialog> {
  late Future<List<TeamEvent>> _events = widget.load();

  String _dateRange(TeamEvent event) {
    if (event.start == null) return 'Date unavailable';
    final dates = MaterialLocalizations.of(context);
    final start = dates.formatShortDate(event.start!);
    return event.end == null || event.end == event.start
        ? start
        : '$start \u2013 ${dates.formatShortDate(event.end!)}';
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 560,
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Team ${widget.team.team}',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(widget.team.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('2026 REBUILT \u00b7 Newest to oldest',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close event history',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<TeamEvent>>(
                  future: _events,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Could not load event history.'),
                            TextButton.icon(
                              onPressed: () => setState(() {
                                _events = widget.load();
                              }),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      );
                    }
                    final events = snapshot.data ?? [];
                    if (events.isEmpty) {
                      return const Center(
                        child: Text('No event history found.'),
                      );
                    }
                    return ListView.separated(
                      key: const ValueKey('team-event-history'),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          key: ValueKey('team-event-${event.key}'),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          title: Text(event.name),
                          subtitle: Text([
                            _dateRange(event),
                            if (event.location.isNotEmpty) event.location,
                          ].join('\n')),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.primary),
                          onTap: () => Navigator.of(context).pop(event.key),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}
