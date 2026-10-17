import 'dart:math' show min;

import 'package:app/APIService.dart';
import 'package:app/models/2026Pitscouting.dart';
import 'package:app/models/auto_route.dart';
import 'package:app/widgets/auto_path_recorder.dart';
import 'package:app/models/scout_info.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PitScoutingTeamPage extends StatefulWidget {
  final int teamNumber;
  final String eventCode;

  const PitScoutingTeamPage({
    super.key,
    required this.teamNumber,
    required this.eventCode,
  });

  @override
  State<PitScoutingTeamPage> createState() => _PitScoutingTeamPageState();
}

class _EditableAutoPath {
  String name;
  final List<String> steps;

  _EditableAutoPath({
    required this.name,
    List<String>? steps,
  }) : steps = steps ?? <String>[];
}

class _PitScoutingTeamPageState extends State<PitScoutingTeamPage> {
  final TextEditingController _favoriteRobotPartController =
      TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _formSections = List.generate(4, (_) => GlobalKey());

  void _jumpToSection(int section) {
    FocusScope.of(context).unfocus();
    final target = _formSections[section].currentContext;
    if (target != null)
      Scrollable.ensureVisible(target,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          alignment: 0);
  }

  bool _trench = false;
  bool _bump = false;

  double _bps = 0;

  String? _shooterType;
  String? _climb;
  String? _driveTrain;

  int _driverEvents = 0;
  bool _isLoading = false;

  // Each item is a separate autonomous routine.
  final List<_EditableAutoPath> _autoPaths = <_EditableAutoPath>[
    _EditableAutoPath(name: 'Auto 1'),
  ];

  int _selectedAutoPathIndex = 0;

  static const List<String> _shooterTypes = <String>[
    'Turret',
    'Fixed Shooter',
    'Dumper',
    'Drum',
    'Double Shooter',
    'Other',
    'None',
  ];

  static const List<String> _climbOptions = <String>[
    'None',
    'L1',
    'L2',
    'L3',
    'Other',
  ];

  static const List<String> _driveTrainOptions = <String>[
    'Swerve',
    'Tank',
    'Mecanum',
    'Other',
  ];

  _EditableAutoPath get _selectedAutoPath => _autoPaths[_selectedAutoPathIndex];

  int get _recordedAutoPathCount =>
      _autoPaths.where((path) => path.steps.isNotEmpty).length;

  Future<void> _submit() async {
    if (_shooterType == null || _climb == null || _driveTrain == null) {
      _showMessage(
        'Please select a shooter type, climb, and drivetrain.',
      );
      return;
    }

    for (final path in _autoPaths.where((path) => path.steps.isNotEmpty)) {
      final error = _validateAutoSteps(path.steps);
      if (error != null) {
        _showMessage('${path.name}: $error');
        return;
      }
    }

    final auth = context.read<AuthService>();
    final groupId = auth.groupId;
    if (groupId == null || groupId.trim().isEmpty) {
      _showMessage('Join a scouting group before submitting pit data.');
      return;
    }

    final savedAutoPaths = _autoPaths
        .where((path) => path.steps.isNotEmpty)
        .map(
          (path) => PitAutoRoutine(
            name: path.name.trim().isEmpty ? 'Auto' : path.name.trim(),
            path: List<String>.from(path.steps),
          ),
        )
        .toList();

    final scoutInfo = ScoutInfo(
      userId: auth.username ?? '',
      firstName: auth.firstName ?? '',
      username: auth.username ?? '',
      team: auth.team.toString(),
    );
    final pitData = PitScouting2026(
      event: widget.eventCode,
      team: widget.teamNumber,
      groupId: groupId,
      scoutInfo: scoutInfo,
      data: Data(
        trench: _trench,
        bump: _bump,
        shooter_type: _shooterType!,
        bps: _bps,
        climb: _climb!,
        autos: Auto(
          autos: AutoPathPit(
            auto_paths: savedAutoPaths,
          ),
        ),
        driver_events: _driverEvents,
        favorite_robot_part: _favoriteRobotPartController.text.trim(),
        drive_train: _driveTrain!,
        comments: _commentController.text.trim(),
      ),
    );

    setState(() => _isLoading = true);

    final apiService = APIService();
    try {
      await apiService.submitPitScouting(pitData);

      if (!mounted) return;

      _showMessage(
        'Pit scouting submitted with '
        '${savedAutoPaths.length} autonomous '
        '${savedAutoPaths.length == 1 ? 'path' : 'paths'}.',
      );

      _resetForm();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('Error: $error');
    } finally {
      apiService.dispose();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _trench = false;
      _bump = false;
      _shooterType = null;
      _climb = null;
      _driveTrain = null;
      _driverEvents = 0;
      _bps = 0;

      _autoPaths
        ..clear()
        ..add(_EditableAutoPath(name: 'Auto 1'));
      _selectedAutoPathIndex = 0;
    });

    _favoriteRobotPartController.clear();
    _commentController.clear();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addAutoPath() {
    setState(() {
      _autoPaths.add(
        _EditableAutoPath(
          name: 'Auto ${_autoPaths.length + 1}',
        ),
      );
      _selectedAutoPathIndex = _autoPaths.length - 1;
    });
  }

  void _deleteSelectedAutoPath() {
    if (_autoPaths.length == 1) {
      setState(() {
        _selectedAutoPath.steps.clear();
        _selectedAutoPath.name = 'Auto 1';
      });
      return;
    }

    setState(() {
      _autoPaths.removeAt(_selectedAutoPathIndex);
      _selectedAutoPathIndex = min(
        _selectedAutoPathIndex,
        _autoPaths.length - 1,
      );
    });
  }

  Future<void> _renameSelectedAutoPath() async {
    final controller = TextEditingController(
      text: _selectedAutoPath.name,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: MattePanel(
            padding: const EdgeInsets.all(22),
            tint: AppColors.secondary,
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Rename autonomous path',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 30,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    hintText: 'Example: Left trench auto',
                    prefixIcon: Icons.edit_outlined,
                  ),
                  onSubmitted: (value) {
                    Navigator.of(dialogContext).pop(value.trim());
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(
                          controller.text.trim(),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();

    if (!mounted || result == null || result.trim().isEmpty) return;

    setState(() {
      _selectedAutoPath.name = result.trim();
    });
  }

  String? _validateAutoSteps(List<String> steps) => AutoRoute.validate(steps);

  @override
  void dispose() {
    _favoriteRobotPartController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PolarForecastAppBar(
          extraText: 'Pit scouting · Team ${widget.teamNumber}'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (var i = 0; i < 4; i++)
                        Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: Icon(
                                  [
                                    Icons.settings_outlined,
                                    Icons.route_rounded,
                                    Icons.speed_rounded,
                                    Icons.notes_rounded
                                  ][i],
                                  size: 16),
                              label: Text([
                                'Robot',
                                'Auto routines',
                                'Driver & scoring',
                                'Notes'
                              ][i]),
                              onPressed: () => _jumpToSection(i),
                            )),
                    ]))),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                      key: _formSections[0], child: _buildFieldAccessCard()),
                  const SizedBox(height: 16),
                  _buildRobotConfigurationCard(),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                      key: _formSections[1],
                      child: _buildAutonomousPathsCard()),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                      key: _formSections[2],
                      child: _buildDriverExperienceCard()),
                  const SizedBox(height: 16),
                  _buildBPSCard(),
                  const SizedBox(height: 16),
                  _buildFavoriteRobotPartCard(),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                      key: _formSections[3], child: _buildCommentsCard()),
                ],
              ),
            ),
            _buildSubmitArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return _sectionContainer(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.precision_manufacturing_outlined,
              color: Colors.blueAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pit Scouting',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Team ${widget.teamNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.eventCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              '$_recordedAutoPathCount '
              '${_recordedAutoPathCount == 1 ? 'auto' : 'autos'}',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldAccessCard() {
    return _buildSection(
      icon: Icons.route_outlined,
      title: 'Field Access',
      subtitle: 'Where can the robot travel?',
      children: [
        _buildSwitchTile(
          title: 'Trench',
          subtitle: 'The robot can travel through the trench.',
          value: _trench,
          onChanged: (value) => setState(() => _trench = value),
        ),
        const SizedBox(height: 10),
        _buildSwitchTile(
          title: 'Bump',
          subtitle: 'The robot can cross the bump.',
          value: _bump,
          onChanged: (value) => setState(() => _bump = value),
        ),
      ],
    );
  }

  Widget _buildRobotConfigurationCard() {
    return _buildSection(
      icon: Icons.settings_outlined,
      title: 'Robot Configuration',
      subtitle: 'Select the primary robot mechanisms.',
      children: [
        _buildDropdown(
          label: 'Shooter Type',
          hint: 'Select shooter type',
          icon: Icons.sports_basketball_outlined,
          value: _shooterType,
          items: _shooterTypes,
          onChanged: (value) => setState(() => _shooterType = value),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          label: 'Climb',
          hint: 'Select climb capability',
          icon: Icons.vertical_align_top_rounded,
          value: _climb,
          items: _climbOptions,
          onChanged: (value) => setState(() => _climb = value),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          label: 'Drivetrain',
          hint: 'Select drivetrain',
          icon: Icons.tire_repair_outlined,
          value: _driveTrain,
          items: _driveTrainOptions,
          onChanged: (value) => setState(() => _driveTrain = value),
        ),
      ],
    );
  }

  Widget _buildAutonomousPathsCard() {
    return _buildSection(
      icon: Icons.alt_route_rounded,
      title: 'Autonomous Paths',
      subtitle: 'Build each routine with the same recorder used in the stands.',
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_autoPaths.length} '
                '${_autoPaths.length == 1 ? 'path' : 'paths'} created',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _addAutoPath,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add Path'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _autoPaths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final path = _autoPaths[index];
              final selected = index == _selectedAutoPathIndex;

              return ChoiceChip(
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedAutoPathIndex = index);
                },
                avatar: CircleAvatar(
                  radius: 11,
                  backgroundColor: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.08),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: Text(
                  '${path.name} • ${path.steps.length}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selectedColor: Colors.blueAccent,
                backgroundColor: Colors.white.withValues(alpha: 0.055),
                side: BorderSide(
                  color: selected ? Colors.blueAccent : Colors.white10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_selectedAutoPathIndex + 1}',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAutoPath.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedAutoPath.steps.length} '
                      '${_selectedAutoPath.steps.length == 1 ? 'action' : 'actions'}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _smallActionButton(
                tooltip: 'Rename path',
                icon: Icons.edit_outlined,
                onPressed: _renameSelectedAutoPath,
              ),
              const SizedBox(width: 7),
              _smallActionButton(
                tooltip: 'Delete path',
                icon: Icons.delete_outline_rounded,
                foregroundColor: Colors.redAccent,
                onPressed: _deleteSelectedAutoPath,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildAutoField(),
      ],
    );
  }

  Widget _buildAutoField() => AutoPathRecorder(
        key: ObjectKey(_selectedAutoPath),
        path: _selectedAutoPath.steps,
        title: _selectedAutoPath.name,
        enabled: !_isLoading,
        onChanged: (path) => setState(() {
          _selectedAutoPath.steps
            ..clear()
            ..addAll(path);
        }),
      );

  Widget _buildBPSCard() {
    return _buildSection(
      icon: Icons.sports_esports_outlined,
      title: 'Fuel Per Second',
      subtitle: 'How fast can a team score fuel in a second on average.',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Fuel Per Second',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _counterButton(
                icon: Icons.remove,
                onPressed: _bps == 0 ? null : () => setState(() => _bps--),
              ),
              SizedBox(
                width: 54,
                child: Text(
                  '$_bps',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _counterButton(
                icon: Icons.add,
                onPressed: () => setState(() => _bps++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverExperienceCard() {
    return _buildSection(
      icon: Icons.sports_esports_outlined,
      title: 'Driver Experience',
      subtitle: 'Number of events driven by the drive team.',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Driver Events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _counterButton(
                icon: Icons.remove,
                onPressed: _driverEvents == 0
                    ? null
                    : () => setState(() => _driverEvents--),
              ),
              SizedBox(
                width: 54,
                child: Text(
                  '$_driverEvents',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _counterButton(
                icon: Icons.add,
                onPressed: () => setState(() => _driverEvents++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteRobotPartCard() {
    return _buildSection(
      icon: Icons.favorite_border,
      title: 'Favorite Robot Feature',
      subtitle: 'Record the team’s favorite part of their robot.',
      children: [
        TextField(
          controller: _favoriteRobotPartController,
          maxLines: 3,
          minLines: 1,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.blueAccent,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            hintText: 'Example: turret, intake, drivetrain...',
            prefixIcon: Icons.star_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsCard() {
    return _buildSection(
      icon: Icons.notes_outlined,
      title: 'Comments',
      subtitle: 'Add any other observations or robot details.',
      children: [
        TextField(
          controller: _commentController,
          minLines: 5,
          maxLines: 10,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.blueAccent,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            hintText: 'Enter observations, notes, and robot details...',
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.blueAccent,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: value
              ? Colors.blueAccent.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? Colors.blueAccent.withValues(alpha: 0.45)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              activeThumbColor: Colors.blueAccent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppColors.surfaceRaised,
          iconEnabledColor: Colors.white60,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          isExpanded: true,
          decoration: _inputDecoration(
            hintText: hint,
            prefixIcon: icon,
          ),
          hint: Text(
            hint,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _smallActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    Color foregroundColor = Colors.white70,
  }) {
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              size: 19,
              color: enabled ? foregroundColor : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _counterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: onPressed == null
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.blueAccent.withValues(alpha: 0.14),
          foregroundColor:
              onPressed == null ? Colors.white24 : Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }

  Widget _sectionContainer({
    required Widget child,
  }) {
    return MattePanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      tint: AppColors.primary,
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.white38,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: Colors.white38,
              size: 20,
            ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.065),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.blueAccent,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildSubmitArea() {
    return ClipRect(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          border: const Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _isLoading ? 'Submitting...' : 'Submit Pit Scouting',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.82),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.surfaceRaised.withValues(alpha: 0.72),
              disabledForegroundColor: Colors.white60,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
