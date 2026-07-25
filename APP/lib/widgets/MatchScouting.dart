import 'dart:math';

import 'package:app/APIService.dart';
import 'package:app/models/2026Matchscouting.dart';
import 'package:app/models/scout_info.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchScouting extends StatefulWidget {
  const MatchScouting({super.key});

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
  final uri = Uri.base;

  String get rawEvent =>
      uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "";

  String get eventCode => rawEvent;

  final _formKey = GlobalKey<FormState>();

  final _matchController = TextEditingController();
  final _commentsController = TextEditingController();

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

  // Coordinate system for the field overlay.
  // Use x from 0..1000 and y from 0..500 when placing buttons.
  static const double _fieldWidthUnits = 1000;
  static const double _fieldHeightUnits = 500;

  @override
  void dispose() {
    _matchController.dispose();
    _commentsController.dispose();
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

  Color get _hintColor => _primaryColor.withOpacity(0.15);

  String? get _fieldImagePath {
    if (_isRedAlliance) {
      return "2026FRCFeildImageFull.png";
    }

    if (_isBlueAlliance) {
      return "2026FRCFeildImageBlue.png";
    }

    // Do not show a field while Random is selected.
    return null;
  }

  Color _chipColor(StationMode mode, bool selected) {
    if (!selected) return LiquidGlassColors.glassSoft;

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

  Future<void> _loadTeams() async {
    final match = int.tryParse(_matchController.text.trim());

    if (match == null) {
      setState(() {
        _redTeams.clear();
        _blueTeams.clear();
      });
      return;
    }

    setState(() => _loadingTeams = true);

    try {
      final api = APIService();

      final red = await api.fetchTeamsPerAllianceRed(eventCode, match);
      final blue = await api.fetchTeamsPerAllianceBlue(eventCode, match);

      if (!mounted) return;

      setState(() {
        _redTeams = List<String>.from(red);
        _blueTeams = List<String>.from(blue);
        _loadingTeams = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTeams = false);
      debugPrint(e.toString());
    }
  }

  // --------------------------
  // TEAM RESOLUTION
  // --------------------------

  int? get selectedTeam {
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

  void _resetForm() {
    _matchController.clear();
    _commentsController.clear();

    _redTeams.clear();
    _blueTeams.clear();

    _autoPath = [];

    _autoFuel = 0;
    _teleopFuel = 0;
    _died = false;
    _defense = false;

    _selectedMode = StationMode.red1;
    _autoPath.clear();
  }

  // --------------------------
  // SUBMIT
  // --------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final team = selectedTeam;

    if (team == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid station")),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final auth = context.read<AuthService>();
      final api = APIService();

      final report = MatchScouting2026(
        groupId: auth.groupId,
        event: eventCode,
        match: _matchController.text.trim(),
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

      await api.submitMatchScouting(report);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _autoPath.isEmpty
                ? "Submitted successfully"
                : "Submitted successfully • Auto path: ${_autoPath.join(" -> ")}",
          ),
        ),
      );

      setState(_resetForm);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
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
  }) {
    return LiquidGlassPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(18),
      tint: _primaryColor,
      blurSigma: 8,
      shadow: false,
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
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
                  onPressed: onAdd,
                  backgroundColor: _primaryColor.withValues(alpha: 0.78),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCounterButton(
                  label: "+5",
                  icon: Icons.keyboard_double_arrow_up_rounded,
                  onPressed: onAddFive,
                  backgroundColor: _primaryColor.withValues(alpha: 0.78),
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
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return SizedBox(
      height: 62,
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
              size: 21,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
  }) {
    return LiquidGlassPanel(
      padding: padding,
      borderRadius: BorderRadius.circular(16),
      tint: _primaryColor,
      blurSigma: 8,
      shadow: false,
      child: child,
    );
  }

  // --------------------------
  // FIELD BUTTON BUILDER
  // --------------------------
  //
  // Use this function to add your own buttons.
  // Example:
  //
  // _buildFieldButton(
  //   x: 220,
  //   y: 170,
  //   fieldPixelWidth: width,
  //   fieldPixelHeight: height,
  //   value: "Left Note",
  //   label: "L",
  // )
  //
  Widget _buildFieldButton({
    required double x,
    required double y,
    required double fieldPixelWidth,
    required double fieldPixelHeight,
    required String value,
    String? label,
    IconData icon = Icons.add,
    double size = 44,
  }) {
    final px = (x / _fieldWidthUnits) * fieldPixelWidth;
    final py = (y / _fieldHeightUnits) * fieldPixelHeight;

    final left =
        (px - size / 2).clamp(0.0, max(0.0, fieldPixelWidth - size)).toDouble();

    final top = (py - size / 2)
        .clamp(0.0, max(0.0, fieldPixelHeight - size))
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: Tooltip(
        message: value,
        child: Material(
          color: _primaryColor.withOpacity(0.95),
          shape: const CircleBorder(),
          elevation: 5,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              setState(() {
                _autoPath.add(value);
              });
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),

              // The entire field is rotated 90° counterclockwise.
              // Rotate the content clockwise so the label stays upright.
              child: RotatedBox(
                quarterTurns: 1,
                child: Center(
                  child: label != null
                      ? FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          icon,
                          color: Colors.white,
                          size: size * 0.5,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSharedFieldButtons({
    required double width,
    required double height,
  }) {
    // The coordinate system is 1000 × 500.
    // Buttons scale with the rendered field width.
    final double buttonSize = (width * 0.07).clamp(42.0, 88.0).toDouble();

    return [
      _buildFieldButton(
        x: 260,
        y: 130,
        fieldPixelWidth: width,
        fieldPixelHeight: height,
        value: "Intaked At Depot",
        label: "Depot",
        size: buttonSize,
      ),
      _buildFieldButton(
        x: 500,
        y: 40,
        fieldPixelWidth: width,
        fieldPixelHeight: height,
        value: "Went Under Left Trench",
        label: "Left Trench",
        size: buttonSize,
      ),
      _buildFieldButton(
        x: 500,
        y: 150,
        fieldPixelWidth: width,
        fieldPixelHeight: height,
        value: "Went Over Left Bump",
        label: "Left Bump",
        size: buttonSize,
      ),
      _buildFieldButton(
        x: 500,
        y: 350,
        fieldPixelWidth: width,
        fieldPixelHeight: height,
        value: "Went Over Right Bump",
        label: "Right Bump",
        size: buttonSize,
      ),
      _buildFieldButton(
        x: 500,
        y: 500,
        fieldPixelWidth: width,
        fieldPixelHeight: height,
        value: "Went Under Right Trench",
        label: "Right Trench",
        size: buttonSize,
      ),
      _buildFieldButton(
        x: 530,
        y: 250,
        fieldPixelWidth: width,
        fieldPixelHeight: height,
        value: "Shot at Hub",
        label: "Hub",
        size: buttonSize,
      ),
      _buildFieldButton(
        x: 730,
        y: 250,
        fieldPixelWidth: width,
        fieldPixelHeight: height,
        value: "Intaked at Neutral Zone",
        label: "Neutral Zone",
        size: buttonSize,
      ),
    ];
  }

  Widget _buildAutoField() {
    final fieldImage = _fieldImagePath;
    final allianceColor =
        _isBlueAlliance ? const Color(0xFF4C8DFF) : const Color(0xFFFF5C68);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: allianceColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: allianceColor.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(
                            Icons.route_rounded,
                            color: allianceColor,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Auto Path",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Tap locations in the order the robot will visit them.",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Undo and clear controls
              _autoFieldActionButton(
                tooltip: "Undo last action",
                icon: Icons.undo_rounded,
                onPressed: _autoPath.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _autoPath.removeLast();
                        });
                      },
              ),
              const SizedBox(width: 8),
              _autoFieldActionButton(
                tooltip: "Clear auto path",
                icon: Icons.delete_outline_rounded,
                foregroundColor: const Color(0xFFFF6B75),
                onPressed: _autoPath.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _autoPath.clear();
                        });
                      },
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Field status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: fieldImage == null ? Colors.white30 : allianceColor,
                    shape: BoxShape.circle,
                    boxShadow: fieldImage == null
                        ? null
                        : [
                            BoxShadow(
                              color: allianceColor.withValues(alpha: 0.55),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    fieldImage == null
                        ? "Waiting for a driver station"
                        : "${_isBlueAlliance ? "Blue" : "Red"} alliance field",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _autoPath.isEmpty
                        ? Colors.white.withValues(alpha: 0.05)
                        : allianceColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _autoPath.isEmpty
                          ? Colors.white10
                          : allianceColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    "${_autoPath.length} "
                    "${_autoPath.length == 1 ? "action" : "actions"}",
                    style: TextStyle(
                      color: _autoPath.isEmpty ? Colors.white38 : allianceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: fieldImage == null
                ? _buildEmptyAutoField(allianceColor)
                : LayoutBuilder(
                    key: ValueKey(fieldImage),
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.sizeOf(context).width;
                      final isPhone = screenWidth < 600;

                      // Use much more of the card width instead of only one third.
                      final displayWidth = isPhone
                          ? constraints.maxWidth
                          : constraints.maxWidth.clamp(340.0, 560.0);

                      final displayHeight = displayWidth * 1.9;

                      return Center(
                        child: Container(
                          width: displayWidth,
                          height: displayHeight,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101216),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: allianceColor.withValues(alpha: 0.50),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: allianceColor.withValues(alpha: 0.12),
                                blurRadius: 28,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: LayoutBuilder(
                                builder: (context, fieldConstraints) {
                                  final fieldWidth = fieldConstraints.maxWidth;
                                  final fieldHeight =
                                      fieldConstraints.maxHeight;

                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      const ColoredBox(
                                        color: Color(0xFF090A0D),
                                      ),

                                      // Field image
                                      RotatedBox(
                                        quarterTurns: _isBlueAlliance ? 2 : 0,
                                        child: Image.asset(
                                          fieldImage,
                                          width: fieldWidth,
                                          height: fieldHeight,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),

                                      // Subtle contrast overlay
                                      IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withValues(
                                                  alpha: 0.04,
                                                ),
                                                Colors.transparent,
                                                Colors.black.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Interactive field buttons
                                      ..._buildSharedFieldButtons(
                                        width: fieldWidth,
                                        height: fieldHeight,
                                      ),

                                      // Inner field border
                                      IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 18),
          _buildAutoPathPreview(),
        ],
      ),
    );
  }

  Widget _autoFieldActionButton({
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
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: enabled ? Colors.white12 : Colors.white10,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled ? foregroundColor : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAutoField(Color allianceColor) {
    return Container(
      key: const ValueKey("empty-auto-field"),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      decoration: BoxDecoration(
        color: const Color(0xFF17191E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C1F25),
            Color(0xFF131519),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -35,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allianceColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.055),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(
                      Icons.stadium_outlined,
                      color: Colors.white54,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    "Choose a driver station",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    "Select a red or blue starting station to load the interactive field.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPathPreview() {
    if (_autoPath.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.route_outlined,
              color: Colors.white38,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              "No auto actions selected yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hintColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Auto Actions (${_autoPath.length})",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _autoPath.clear();
                  });
                },
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 18,
                ),
                label: const Text("Clear"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Each action fills the width of the card.
          ...List.generate(_autoPath.length, (index) {
            final item = _autoPath[index];
            final isLast = index == _autoPath.length - 1;

            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 10,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 64,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "Remove step",
                      onPressed: () {
                        setState(() {
                          _autoPath.removeAt(index);
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectedTeamCard() {
    final team = selectedTeam;

    return _buildSectionCard(
      child: _loadingTeams
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

    return LiquidGlassPanel(
      tint: color,
      blurSigma: 16,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.025),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    InputDecoration input(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          labelStyle: const TextStyle(color: LiquidGlassColors.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: LiquidGlassColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: _primaryColor),
          ),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              const SizedBox(height: 14),

// PRE-MATCH
              _buildScoutingSection(
                title: "Pre-Match",
                description: "Confirm the selected team and match information.",
                icon: Icons.assignment_outlined,
                accentColor: const Color(0xFF8B9DFF),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _matchController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: input("Match Number"),
                      onChanged: (_) => _loadTeams(),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter match number" : null,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: StationMode.values.map((mode) {
                        final selected = _selectedMode == mode;

                        String label;
                        switch (mode) {
                          case StationMode.red1:
                            label = "Red 1";
                            final team = _teamLabel(_redTeams, 0);
                            if (team != null) label += " • $team";
                            break;
                          case StationMode.red2:
                            label = "Red 2";
                            final team = _teamLabel(_redTeams, 1);
                            if (team != null) label += " • $team";
                            break;
                          case StationMode.red3:
                            label = "Red 3";
                            final team = _teamLabel(_redTeams, 2);
                            if (team != null) label += " • $team";
                            break;
                          case StationMode.blue1:
                            label = "Blue 1";
                            final team = _teamLabel(_blueTeams, 0);
                            if (team != null) label += " • $team";
                            break;
                          case StationMode.blue2:
                            label = "Blue 2";
                            final team = _teamLabel(_blueTeams, 1);
                            if (team != null) label += " • $team";
                            break;
                          case StationMode.blue3:
                            label = "Blue 3";
                            final team = _teamLabel(_blueTeams, 2);
                            if (team != null) label += " • $team";
                            break;
                        }

                        return ChoiceChip(
                          label: Text(
                            label,
                            style: const TextStyle(color: Colors.white),
                          ),
                          selected: selected,
                          selectedColor: _chipColor(mode, true),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.055),
                          side: BorderSide(
                            color: selected
                                ? _chipColor(mode, true).withValues(alpha: 0.70)
                                : LiquidGlassColors.border,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedMode = mode;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _buildSelectedTeamCard()
                  ],
                ),
              ),

              const SizedBox(height: 16),

// AUTO
              _buildScoutingSection(
                title: "Autonomous",
                description:
                    "Record the robot's autonomous path and fuel scored.",
                icon: Icons.route_rounded,
                accentColor: const Color(0xFFFFB74D),
                child: Column(
                  children: [
                    _buildAutoField(),
                    const SizedBox(height: 14),
                    buildCounterCard(
                      title: "Auto Fuel",
                      value: _autoFuel,
                      onAdd: () {
                        setState(() => _autoFuel += 1);
                      },
                      onRemove: () {
                        setState(() {
                          _autoFuel = (_autoFuel - 1).clamp(0, 999);
                        });
                      },
                      onAddFive: () {
                        setState(() => _autoFuel += 5);
                      },
                      onRemoveFive: () {
                        setState(() {
                          _autoFuel = (_autoFuel - 5).clamp(0, 999);
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

// TELEOP
              _buildScoutingSection(
                title: "Teleop",
                description:
                    "Track scoring during the driver-controlled period.",
                icon: Icons.sports_esports_rounded,
                accentColor: const Color(0xFF4C8DFF),
                child: buildCounterCard(
                  title: "Teleop Fuel",
                  value: _teleopFuel,
                  onAdd: () {
                    setState(() => _teleopFuel += 1);
                  },
                  onRemove: () {
                    setState(() {
                      _teleopFuel = (_teleopFuel - 1).clamp(0, 999);
                    });
                  },
                  onAddFive: () {
                    setState(() => _teleopFuel += 5);
                  },
                  onRemoveFive: () {
                    setState(() {
                      _teleopFuel = (_teleopFuel - 5).clamp(0, 999);
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

// MISC
              _buildScoutingSection(
                title: "Miscellaneous",
                description:
                    "Record reliability, defense, and additional observations.",
                icon: Icons.fact_check_outlined,
                accentColor: const Color(0xFF9B7BFF),
                child: Column(
                  children: [
                    _buildScoutingToggle(
                      title: "Robot Died",
                      subtitle:
                          "The robot became disabled or stopped functioning.",
                      icon: Icons.power_settings_new_rounded,
                      value: _died,
                      activeColor: const Color(0xFFFF5C68),
                      onChanged: (value) {
                        setState(() => _died = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildScoutingToggle(
                      title: "Played Defense",
                      subtitle: "The robot actively defended another robot.",
                      icon: Icons.shield_outlined,
                      value: _defense,
                      activeColor: const Color(0xFFFFB74D),
                      onChanged: (value) {
                        setState(() => _defense = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commentsController,
                      maxLines: 4,
                      minLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: input("Comments").copyWith(
                        hintText:
                            "Driver skill, issues, strategy, observations...",
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 76),
                          child: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
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
                  _submitting ? "Submitting..." : "Submit Scouting Data",
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor.withValues(alpha: 0.80),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primaryColor.withValues(alpha: 0.4),
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
