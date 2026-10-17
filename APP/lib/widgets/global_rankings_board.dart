import 'package:app/APIService.dart';
import 'package:app/models/global_ranking.dart';
import 'package:app/models/team_event.dart';
import 'package:app/services/global_rankings_controller.dart';
import 'package:app/widgets/global_rankings_grid.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:app/widgets/team_events_dialog.dart';
import 'package:flutter/material.dart';

class GlobalRankingsBoard extends StatefulWidget {
  final GlobalRankingsController? controller;
  final ValueChanged<GlobalRanking>? onTeamTap;
  final Future<List<TeamEvent>> Function(int)? loadTeamEvents;
  const GlobalRankingsBoard({
    super.key,
    this.controller,
    this.onTeamTap,
    this.loadTeamEvents,
  });
  @override
  State<GlobalRankingsBoard> createState() => _GlobalRankingsBoardState();
}

class _GlobalRankingsBoardState extends State<GlobalRankingsBoard> {
  APIService? _api;
  late final GlobalRankingsController _rankings;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _rankings = widget.controller!;
    } else {
      final api = _api = APIService();
      _rankings = GlobalRankingsController(
          load: api.fetchGlobalRankings,
          identity: (team) => api.fetchTeamIdentity(team));
    }
    _search = TextEditingController(text: _rankings.query);
  }

  @override
  void dispose() {
    _search.dispose();
    if (widget.controller == null) _rankings.dispose();
    _api?.dispose();
    super.dispose();
  }

  Future<void> _openTeam(GlobalRanking team) async {
    if (widget.onTeamTap != null) {
      widget.onTeamTap!(team);
    } else {
      final load =
          widget.loadTeamEvents ?? (_api ??= APIService()).fetchTeamEvents;
      final eventKey = await showDialog<String>(
        context: context,
        builder: (_) => TeamEventsDialog(
          team: team,
          load: () => load(team.team),
        ),
      );
      if (mounted && eventKey != null) {
        Navigator.of(context).pushNamed('/event/$eventKey');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _rankings,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Expanded(
                  child: TextField(
                key: const ValueKey('ranking-search'),
                controller: _search,
                maxLength: 100,
                onChanged: _rankings.search,
                onSubmitted: (_) => _rankings.refresh(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                    hintText: 'Search team number or name',
                    counterText: '',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _search.clear();
                              _rankings.search('');
                            }),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16)),
              )),
              const SizedBox(width: 8),
              IconButton(
                  tooltip: 'Refresh rankings',
                  onPressed: _rankings.loading || _rankings.refreshing
                      ? null
                      : _rankings.refresh,
                  icon: _rankings.refreshing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded)),
            ]),
          ),
          Expanded(
              child: _rankings.loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rankings.teams.isEmpty
                      ? _empty()
                      : GlobalRankingsGrid(
                          teams: _rankings.teams,
                          ranges: _rankings.ranges,
                          identity: _rankings.identity,
                          onTeamTap: _openTeam,
                          onRefresh: _rankings.refresh,
                          footer: _rankings.nextOffset == null
                              ? null
                              : _loadMore())),
          if (_rankings.error != null && _rankings.teams.isNotEmpty)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Flexible(
                  child: Text('Could not update rankings.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12))),
              TextButton(
                  onPressed: _rankings.refresh, child: const Text('Try again')),
            ]),
        ]),
      );

  Widget _loadMore() => SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          key: const ValueKey('load-more-rankings'),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.surfaceRaised,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          onPressed: _rankings.loadingMore || _rankings.refreshing
              ? null
              : _rankings.loadMore,
          icon: _rankings.loadingMore
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.expand_more_rounded),
          label: Text(_rankings.loadingMore ? 'Loading...' : 'Load more'),
        ),
      );

  Widget _empty() => Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              _rankings.error == null
                  ? Icons.search_off_rounded
                  : Icons.cloud_off_rounded,
              size: 32,
              color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
              _rankings.error != null
                  ? 'Could not load rankings'
                  : _rankings.query.isNotEmpty
                      ? 'No teams found'
                      : 'No rankings yet',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          if (_rankings.error != null)
            TextButton(
                onPressed: _rankings.refresh, child: const Text('Try again')),
        ]),
      ));
}
