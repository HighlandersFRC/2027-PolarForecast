import 'package:app/models/auto_route.dart';
import 'package:app/widgets/matte_theme.dart';
import 'auto_field_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared by live scouting and pit routines. Every edit emits API-compatible
/// action strings; landmarks are shown over the existing field image.
class AutoPathRecorder extends StatefulWidget {
  final List<String> path;
  final ValueChanged<List<String>> onChanged;
  final bool blue;
  final bool enabled;
  final bool allowFocus;
  final String title;
  final int? fuel;
  final ValueChanged<int>? onFuelChanged;
  const AutoPathRecorder(
      {super.key,
      required this.path,
      required this.onChanged,
      this.blue = false,
      this.enabled = true,
      this.allowFocus = true,
      this.title = 'Auto path',
      this.fuel,
      this.onFuelChanged});

  @override
  State<AutoPathRecorder> createState() => _AutoPathRecorderState();
}

class _AutoPathRecorderState extends State<AutoPathRecorder> {
  final List<List<String>> _past = [];
  final List<List<String>> _future = [];
  final _timeline = ScrollController();
  bool _ownChange = false;
  bool _flipped = false;
  Color get _accent =>
      widget.blue ? const Color(0xFF94BEFF) : const Color(0xFFFF929E);

  @override
  void didUpdateWidget(covariant AutoPathRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ownChange && !listEquals(oldWidget.path, widget.path)) {
      _past.clear();
      _future.clear();
    }
    _ownChange = false;
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  void _emit(List<String> path) {
    _ownChange = true;
    widget.onChanged(List.of(path));
    HapticFeedback.selectionClick();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _timeline.hasClients)
        _timeline.jumpTo(_timeline.position.maxScrollExtent);
    });
  }

  void _change(List<String> path) {
    if (!widget.enabled || listEquals(path, widget.path)) return;
    _past.add(List.of(widget.path));
    _future.clear();
    _emit(path);
  }

  void _undo() {
    if (_past.isEmpty) {
      if (widget.path.isNotEmpty) {
        _future.add(List.of(widget.path));
        _emit(widget.path.take(widget.path.length - 1).toList());
      }
      return;
    }
    _future.add(List.of(widget.path));
    _emit(_past.removeLast());
  }

  void _redo() {
    if (_future.isEmpty) return;
    _past.add(List.of(widget.path));
    _emit(_future.removeLast());
  }

  Future<void> _clear() async {
    final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Start this route again?'),
              content: const Text(
                  'This clears the recorded actions. Undo can bring them back.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep route')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear route'))
              ],
            ));
    if (clear == true && mounted) _change([]);
  }

  Future<void> _focus() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => _AutoFocus(
              path: List.of(widget.path),
              blue: widget.blue,
              title: widget.title,
              fuel: widget.fuel,
              onFuelChanged: widget.onFuelChanged,
              onChanged: (path) {
                if (mounted) widget.onChanged(path);
              },
            )));
  }

  void _editSteps() {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
                child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text('Recorded route',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800))),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                            'Choose a step to remove it and everything after it. This keeps the route in order.',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12))),
                    const SizedBox(height: 12),
                    Expanded(
                        child: ListView.builder(
                            itemCount: widget.path.length,
                            itemBuilder: (_, i) => ListTile(
                                  leading: CircleAvatar(
                                      radius: 15,
                                      child: Text('${i + 1}',
                                          style:
                                              const TextStyle(fontSize: 12))),
                                  title: Text(AutoRoute.label(widget.path[i])),
                                  trailing:
                                      const Icon(Icons.undo_rounded, size: 20),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    _change(widget.path.take(i).toList());
                                  },
                                ))),
                  ]),
            )));
  }

  @override
  Widget build(BuildContext context) {
    final started = widget.path.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(Icons.route_rounded, size: 21, color: _accent),
        const SizedBox(width: 8),
        Expanded(
            child: Text(widget.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18))),
        IconButton(
            key: const ValueKey('route-undo'),
            tooltip: 'Undo route action',
            onPressed: widget.enabled && started ? _undo : null,
            icon: const Icon(Icons.undo_rounded)),
        IconButton(
            key: const ValueKey('route-redo'),
            tooltip: 'Redo route action',
            onPressed: widget.enabled && _future.isNotEmpty ? _redo : null,
            icon: const Icon(Icons.redo_rounded)),
        PopupMenuButton<String>(
            tooltip: 'Route options',
            enabled: widget.enabled,
            onSelected: (value) {
              if (value == 'clear')
                _clear();
              else
                setState(() => _flipped = !_flipped);
            },
            itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'flip', child: Text('Flip field view')),
                  if (started)
                    const PopupMenuItem(
                        value: 'clear', child: Text('Start over'))
                ]),
      ]),
      if (widget.allowFocus) ...[
        const SizedBox(height: 6),
        FilledButton.icon(
            key: const ValueKey('route-focus'),
            onPressed: widget.enabled ? _focus : null,
            icon: const Icon(Icons.fullscreen_rounded),
            label: const Text('Open stand mode'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: _accent,
                foregroundColor: AppColors.background)),
        const SizedBox(height: 10),
      ],
      if (started) ...[
        Row(children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
              child: Text(
                  '${AutoRoute.label(widget.path.first)} · ${widget.path.length} actions',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12))),
          TextButton(
              onPressed: widget.enabled ? _editSteps : null,
              child: const Text('Edit steps')),
        ]),
        SizedBox(
          height: 36,
          child: ListView.separated(
              controller: _timeline,
              scrollDirection: Axis.horizontal,
              itemCount: widget.path.length,
              separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppColors.textMuted)),
              itemBuilder: (_, i) => Center(
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: i == widget.path.length - 1
                              ? _accent.withValues(alpha: 0.16)
                              : AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                          '${i + 1}. ${AutoRoute.label(widget.path[i])}',
                          style: TextStyle(
                              fontSize: 11,
                              color: i == widget.path.length - 1
                                  ? _accent
                                  : AppColors.textMuted))))),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 8),
      AutoFieldMap(
          path: widget.path,
          blue: widget.blue,
          flipped: _flipped,
          onRotate: () => setState(() => _flipped = !_flipped),
          enabled: widget.enabled,
          onAction: (action) => _change([...widget.path, action])),
      const SizedBox(height: 10),
      Text(
          !started
              ? 'Tap a preload area on the field to begin.'
              : 'Tap the mapped trench, bump, intake, or hub as the robot uses it.',
          style: const TextStyle(
              fontSize: 11, height: 1.4, color: AppColors.textMuted)),
    ]);
  }
}

class _AutoFocus extends StatefulWidget {
  final List<String> path;
  final ValueChanged<List<String>> onChanged;
  final bool blue;
  final String title;
  final int? fuel;
  final ValueChanged<int>? onFuelChanged;
  const _AutoFocus(
      {required this.path,
      required this.onChanged,
      required this.blue,
      required this.title,
      this.fuel,
      this.onFuelChanged});
  @override
  State<_AutoFocus> createState() => _AutoFocusState();
}

class _AutoFocusState extends State<_AutoFocus> {
  late List<String> _path = List.of(widget.path);
  late int _fuel = widget.fuel ?? 0;
  void _count(int delta) {
    setState(() => _fuel = (_fuel + delta).clamp(0, 300));
    widget.onFuelChanged?.call(_fuel);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Auto recording',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          Text(widget.title,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        body: SafeArea(
            top: false,
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: AutoPathRecorder(
                  path: _path,
                  blue: widget.blue,
                  allowFocus: false,
                  title: 'Auto path',
                  onChanged: (path) {
                    setState(() => _path = path);
                    widget.onChanged(path);
                  },
                ))),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (widget.onFuelChanged != null) ...[
                  Row(children: [
                    const Expanded(
                        child: Text('AUTO FUEL',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800))),
                    IconButton(
                        tooltip: 'Remove one auto fuel',
                        onPressed: _fuel == 0 ? null : () => _count(-1),
                        icon: const Icon(Icons.remove_rounded)),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$_fuel',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w900))),
                    FilledButton(
                        onPressed: () => _count(1), child: const Text('+1')),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                        onPressed: () => _count(5), child: const Text('+5')),
                  ]),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label:
                            Text('Done · ${_path.length} recorded actions'))),
              ]),
            )),
      );
}
