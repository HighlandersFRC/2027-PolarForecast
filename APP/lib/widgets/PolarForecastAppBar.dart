import 'dart:ui' as ui;

import 'package:app/APIService.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PolarForecastAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? extraText;
  final bool showSearchAction;
  final bool showAccountAction;

  const PolarForecastAppBar({
    Key? key,
    this.extraText,
    this.showSearchAction = true,
    this.showAccountAction = true,
  }) : super(key: key);

  static const Color _background = Color(0x7A132648);
  static const Color _accent = Color(0xFF72A7FF);

  @override
  Size get preferredSize => const Size.fromHeight(60);

  String get formattedExtraText {
    final label = extraText?.trim() ?? '';
    return label.replaceFirst(RegExp(r'^[|\u2022\u00B7\u2014\u2013-]+\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;
    final String title = formattedExtraText.isEmpty
        ? 'Polar Forecast'
        : 'Polar Forecast \u2022 $formattedExtraText';

    return AppBar(
      toolbarHeight: 60,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: isMobile ? 12 : 20,
      shape: const Border(
        bottom: BorderSide(
          color: LiquidGlassColors.border,
          width: 1,
        ),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xA62A466F),
                  _background,
                  Color(0x8A261E4C),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: isMobile ? 36 : 40,
            height: isMobile ? 36 : 40,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Image.asset(
              'assets/PolarBearHead.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.ac_unit_rounded,
                color: _accent,
                size: 22,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 9 : 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 16 : 19,
                fontWeight: FontWeight.w700,
                letterSpacing: isMobile ? 0.2 : 0.6,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (showSearchAction)
          _AppBarAction(
            icon: Icons.search_rounded,
            tooltip: 'Search events',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final selectedEvent = await showSearch<EventSearchKey?>(
                context: context,
                delegate: EventSearchDelegate(APIService().fetchEventKeys()),
              );

              if (selectedEvent == null) {
                return;
              }

              navigator.pushNamed('/event/2026${selectedEvent.eventCode}');
            },
          ),
        if (showAccountAction)
          Consumer<AuthService>(
            builder: (context, auth, _) {
              return _AppBarAction(
                icon: auth.isLoggedIn
                    ? Icons.account_circle_rounded
                    : Icons.account_circle_outlined,
                tooltip: auth.isLoggedIn ? 'Account' : 'Log in',
                onPressed: () async {
                  if (!auth.isLoggedIn) {
                    try {
                      await auth.login();
                    } catch (error) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Login failed: $error'),
                        ),
                      );
                    }
                    return;
                  }

                  if (!context.mounted) return;

                  showDialog<void>(
                    context: context,
                    builder: (context) => _AccountDialog(auth: auth),
                  );
                },
              );
            },
          ),
        SizedBox(width: isMobile ? 4 : 10),
      ],
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 42,
        ),
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.06),
          hoverColor: Colors.white.withOpacity(0.10),
          highlightColor: Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 22),
      ),
    );
  }
}

class _AccountDialog extends StatefulWidget {
  final AuthService auth;

  const _AccountDialog({required this.auth});

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

enum _AccountTeamAction {
  join,
  create,
}

class _AccountDialogState extends State<_AccountDialog> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();

  final APIService _api = APIService();

  _AccountTeamAction _selectedAction = _AccountTeamAction.join;

  String? _groupMessage;
  bool _groupMessageIsSuccess = false;

  bool _isCreatingGroup = false;
  bool _isJoiningGroup = false;
  bool _isLoggingOut = false;

  static const Color _background = Color(0xB3121D2C);
  static const Color _surface = Color(0x8A1A2A3F);
  static const Color _surfaceElevated = Color(0x7A263A50);
  static const Color _border = LiquidGlassColors.border;
  static const Color _primary = Color(0xFF4C8DFF);
  static const Color _danger = Color(0xFFFF5C5C);
  static const Color _success = Color(0xFF4ECB8D);

  bool get _isProcessing =>
      _isCreatingGroup || _isJoiningGroup || _isLoggingOut;

  @override
  void dispose() {
    _groupNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;

    final String firstName = _displayValue(auth.firstName);
    final String username = _displayValue(auth.username);
    final String teamNumber = _displayValue(auth.team);
    final String groupName = _displayValue(auth.group, fallback: '');

    final bool hasGroup = groupName.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: LiquidGlassPanel(
          borderRadius: BorderRadius.circular(26),
          tint: _primary,
          blurSigma: 30,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(
                  firstName: firstName,
                  username: username,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeading(
                          icon: Icons.badge_outlined,
                          title: 'Profile details',
                          subtitle:
                              'Your account and scouting team information.',
                        ),
                        const SizedBox(height: 14),
                        _buildProfileDetails(
                          firstName: firstName,
                          username: username,
                          teamNumber: teamNumber,
                        ),
                        const SizedBox(height: 16),
                        _buildGroupStatusCard(
                          groupName: groupName,
                          hasGroup: hasGroup,
                        ),
                        if (!hasGroup) ...[
                          const SizedBox(height: 30),
                          _buildSectionHeading(
                            icon: Icons.groups_2_outlined,
                            title: 'Team management',
                            subtitle:
                                'Join an existing scouting team or create one.',
                          ),
                          const SizedBox(height: 14),
                          _buildActionSelector(),
                          const SizedBox(height: 18),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  axisAlignment: -1,
                                  child: child,
                                ),
                              );
                            },
                            child: _selectedAction == _AccountTeamAction.join
                                ? _buildJoinTeamForm(auth)
                                : _buildCreateTeamForm(auth),
                          ),
                        ],
                        if (_groupMessage != null) ...[
                          const SizedBox(height: 18),
                          _buildStatusMessage(),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildFooter(auth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String firstName,
    required String username,
  }) {
    final String displayName =
        firstName == '-' ? (username == '-' ? 'Account' : username) : firstName;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 22),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _primary.withOpacity(0.35),
              ),
            ),
            child: Text(
              _getInitials(displayName),
              style: const TextStyle(
                color: _primary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username == '-' ? 'Account profile' : '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white70,
              backgroundColor: Colors.white.withOpacity(0.05),
              disabledForegroundColor: Colors.white24,
            ),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: _primary,
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
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails({
    required String firstName,
    required String username,
    required String teamNumber,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useColumns = constraints.maxWidth >= 520;

        final cards = [
          _buildDetailCard(
            icon: Icons.person_outline,
            label: 'Name',
            value: firstName,
          ),
          _buildDetailCard(
            icon: Icons.alternate_email,
            label: 'Username',
            value: username,
          ),
          _buildDetailCard(
            icon: Icons.numbers,
            label: 'FRC team',
            value: teamNumber,
          ),
        ];

        if (!useColumns) {
          return Column(
            children: [
              for (int index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index != cards.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index != cards.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.white54,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStatusCard({
    required String groupName,
    required bool hasGroup,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: hasGroup ? _primary.withOpacity(0.08) : _surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasGroup ? _primary.withOpacity(0.35) : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasGroup
                  ? _primary.withOpacity(0.16)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              hasGroup ? Icons.groups_rounded : Icons.group_off_outlined,
              color: hasGroup ? _primary : Colors.white54,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasGroup ? 'Scouting team' : 'No scouting team',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasGroup ? groupName : 'Join or create a team below.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasGroup ? Colors.white : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (hasGroup)
            TextButton.icon(
              onPressed: _isProcessing ? null : () => _openGroup(groupName),
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              icon: const Icon(
                Icons.open_in_new,
                size: 17,
              ),
              label: const Text('Open'),
            ),
        ],
      ),
    );
  }

  Widget _buildActionSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionOption(
              action: _AccountTeamAction.join,
              icon: Icons.login_rounded,
              label: 'Join team',
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildActionOption(
              action: _AccountTeamAction.create,
              icon: Icons.add_circle_outline,
              label: 'Create team',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption({
    required _AccountTeamAction action,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedAction == action;

    return Material(
      color: isSelected ? _surfaceElevated : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: _isProcessing
            ? null
            : () {
                setState(() {
                  _selectedAction = action;
                  _groupMessage = null;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color:
                  isSelected ? _primary.withOpacity(0.35) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? _primary : Colors.white54,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinTeamForm(dynamic auth) {
    return Container(
      key: const ValueKey('join-team-form'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter a join code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ask your scouting lead for a Join code',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _joinCodeController,
            label: 'Join code',
            hint: 'Enter team join code',
            icon: Icons.key_outlined,
            textInputAction: TextInputAction.done,
            capitalization: TextCapitalization.characters,
            onSubmitted: (_) {
              if (!_isProcessing) {
                _handleJoinGroup(auth);
              }
            },
          ),
          const SizedBox(height: 13),
          _buildPrimaryButton(
            label: _isJoiningGroup ? 'Joining team...' : 'Join team',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isJoiningGroup,
            onPressed: _isProcessing ? null : () => _handleJoinGroup(auth),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTeamForm(dynamic auth) {
    return Container(
      key: const ValueKey('create-team-form'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create a scouting team',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'You will become the owner and can invite other scouts.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _groupNameController,
            label: 'Team name',
            hint: 'Enter a scouting team name',
            icon: Icons.groups_outlined,
            textInputAction: TextInputAction.done,
            capitalization: TextCapitalization.words,
            onSubmitted: (_) {
              if (!_isProcessing) {
                _handleCreateGroup(auth);
              }
            },
          ),
          const SizedBox(height: 13),
          _buildPrimaryButton(
            label: _isCreatingGroup ? 'Creating team...' : 'Create team',
            icon: Icons.add_rounded,
            isLoading: _isCreatingGroup,
            onPressed: _isProcessing ? null : () => _handleCreateGroup(auth),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputAction textInputAction,
    required TextCapitalization capitalization,
    required ValueChanged<String> onSubmitted,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isProcessing,
      cursorColor: _primary,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      textInputAction: textInputAction,
      textCapitalization: capitalization,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _background,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIconColor: Colors.white54,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: _primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _primary.withOpacity(0.35),
        disabledForegroundColor: Colors.white70,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: isLoading
            ? const Row(
                key: ValueKey('loading'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Processing...',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : Row(
                key: ValueKey(label),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    final Color color = _groupMessageIsSuccess ? _success : _danger;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _groupMessageIsSuccess
                ? Icons.check_circle_outline
                : Icons.error_outline,
            size: 21,
            color: color,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _groupMessage!,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            onPressed: () {
              setState(() {
                _groupMessage = null;
              });
            },
            icon: Icon(
              Icons.close,
              size: 17,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(dynamic auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _isProcessing ? null : () => _handleLogout(auth),
            style: TextButton.styleFrom(
              foregroundColor: _danger,
              disabledForegroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _danger,
                    ),
                  )
                : const Icon(
                    Icons.logout_rounded,
                    size: 19,
                  ),
            label: Text(
              _isLoggingOut ? 'Logging out...' : 'Log out',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _surfaceElevated,
              disabledBackgroundColor: _surfaceElevated.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJoinGroup(dynamic auth) async {
    final String joinCode = _joinCodeController.text.trim();

    if (joinCode.isEmpty) {
      _setMessage(
        'Enter a join code before continuing.',
        isSuccess: false,
      );
      return;
    }

    if (auth.username == null || auth.username.toString().trim().isEmpty) {
      _setMessage(
        'Your username could not be found. Please sign in again.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isJoiningGroup = true;
      _groupMessage = null;
    });

    try {
      await _api.joinGroup(
        username: auth.username!,
        joinCode: joinCode,
      );

      await auth.refreshTokens();

      if (!mounted) return;

      _joinCodeController.clear();

      _setMessage(
        'You joined the scouting team successfully.',
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) return;

      _setMessage(
        'Unable to join the team. Check the join code and try again.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningGroup = false;
        });
      }
    }
  }

  Future<void> _handleCreateGroup(dynamic auth) async {
    final String groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      _setMessage(
        'Enter a team name before continuing.',
        isSuccess: false,
      );
      return;
    }

    if (auth.username == null || auth.username.toString().trim().isEmpty) {
      _setMessage(
        'Your username could not be found. Please sign in again.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isCreatingGroup = true;
      _groupMessage = null;
    });

    try {
      await _api.createGroup(
        groupName,
        username: auth.username,
      );

      await auth.refreshTokens();

      if (!mounted) return;

      _groupNameController.clear();

      _setMessage(
        'The scouting team was created successfully.',
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) return;

      _setMessage(
        'Unable to create the team. The name may already be in use.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  Future<void> _handleLogout(dynamic auth) async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await auth.logout();

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      _setMessage(
        'Unable to log out. Please try again.',
        isSuccess: false,
      );

      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  void _openGroup(String groupName) {
    final navigator = Navigator.of(context);

    navigator.pop();
    navigator.pushNamed('/group/$groupName');
  }

  void _setMessage(
    String message, {
    required bool isSuccess,
  }) {
    if (!mounted) return;

    setState(() {
      _groupMessage = message;
      _groupMessageIsSuccess = isSuccess;
    });
  }

  String _displayValue(
    dynamic value, {
    String fallback = '-',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  String _getInitials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'A';
    }

    if (words.length == 1) {
      final word = words.first;

      if (word.length == 1) {
        return word.toUpperCase();
      }

      return word.substring(0, 2).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class EventSearchDelegate extends SearchDelegate<EventSearchKey?> {
  final Future<List<EventSearchKey>> _eventsFuture;

  EventSearchDelegate(this._eventsFuture)
      : super(
          searchFieldLabel: 'Search by event name or code',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);

    return theme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _EventSearchColors.background,
      colorScheme: theme.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: _EventSearchColors.accent,
        surface: _EventSearchColors.surface,
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: _EventSearchColors.appBar,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _EventSearchColors.searchField,
        hintStyle: const TextStyle(
          color: Colors.white54,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _EventSearchColors.accent,
            width: 1.2,
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _EventSearchColors.accent,
        selectionColor: Color(0x554F8CFF),
        selectionHandleColor: _EventSearchColors.accent,
      ),
      textTheme: theme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      dividerColor: _EventSearchColors.border,
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) {
      return null;
    }

    return [
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: IconButton(
          tooltip: 'Clear search',
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildEventList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildEventList(context);
  }

  Widget _buildEventList(BuildContext context) {
    return ColoredBox(
      color: _EventSearchColors.background,
      child: SafeArea(
        top: false,
        child: FutureBuilder<List<EventSearchKey>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _EventSearchLoadingState();
            }

            if (snapshot.hasError) {
              return _EventSearchMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load events',
                message: snapshot.error.toString(),
              );
            }

            final events = _rankEvents(
              snapshot.data ?? const [],
              query,
            );

            if (events.isEmpty) {
              return _EventSearchMessage(
                icon: Icons.search_off_rounded,
                title: 'No matching events',
                message: query.trim().isEmpty
                    ? 'There are no events available right now.'
                    : 'Try searching with another event name or code.',
              );
            }

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EventResultsHeader(
                      query: query,
                      resultCount: events.length,
                    ),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final event = events[index];

                            return _EventResultCard(
                              event: event,
                              query: query,
                              onTap: () => close(context, event),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<EventSearchKey> _rankEvents(
    List<EventSearchKey> events,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      final initialEvents = List<EventSearchKey>.from(events)
        ..sort(
          (a, b) => a.display.toLowerCase().compareTo(
                b.display.toLowerCase(),
              ),
        );

      return initialEvents.take(24).toList();
    }

    final scoredEvents = events
        .map(
          (event) => _RankedEvent(
            event: event,
            score: _scoreEvent(event, normalizedQuery),
          ),
        )
        .where((event) => event.score > 0)
        .toList()
      ..sort((a, b) {
        final scoreComparison = b.score.compareTo(a.score);

        if (scoreComparison != 0) {
          return scoreComparison;
        }

        return a.event.display.toLowerCase().compareTo(
              b.event.display.toLowerCase(),
            );
      });

    return scoredEvents
        .map((rankedEvent) => rankedEvent.event)
        .take(24)
        .toList();
  }

  int _scoreEvent(EventSearchKey event, String query) {
    final display = event.display.toLowerCase();
    final key = event.key.toLowerCase();
    final code = event.eventCode.toLowerCase();

    if (display == query || key == query || code == query) {
      return 1000;
    }

    if (display.startsWith(query) || key.startsWith(query)) {
      return 800;
    }

    if (code.startsWith(query)) {
      return 700;
    }

    if (display.contains(query) ||
        key.contains(query) ||
        code.contains(query)) {
      return 500;
    }

    final terms =
        query.split(RegExp(r'\s+')).where((term) => term.isNotEmpty).toList();

    final searchableText = '$display $key $code';

    if (terms.isNotEmpty &&
        terms.every((term) => searchableText.contains(term))) {
      return 300;
    }

    return 0;
  }
}

class _EventResultCard extends StatelessWidget {
  final EventSearchKey event;
  final String query;
  final VoidCallback onTap;

  const _EventResultCard({
    required this.event,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _EventSearchColors.accent.withValues(alpha: 0.10),
        highlightColor: _EventSearchColors.accent.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: _EventSearchColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _EventSearchColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _EventSearchColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: _EventSearchColors.accent,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightedText(
                        text: event.display,
                        query: query,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                        highlightedStyle: const TextStyle(
                          color: _EventSearchColors.accentLight,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _EventSearchColors.background,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: _EventSearchColors.border,
                                ),
                              ),
                              child: _HighlightedText(
                                text: event.key,
                                query: query,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                highlightedStyle: const TextStyle(
                                  color: _EventSearchColors.accentLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventResultsHeader extends StatelessWidget {
  final String query;
  final int resultCount;

  const _EventResultsHeader({
    required this.query,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
      child: Row(
        children: [
          Icon(
            hasQuery ? Icons.manage_search_rounded : Icons.explore_outlined,
            color: _EventSearchColors.accentLight,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasQuery ? 'Search results' : 'Available events',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: _EventSearchColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$resultCount',
              style: const TextStyle(
                color: _EventSearchColors.accentLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightedStyle;
  final int maxLines;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightedStyle,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = normalizedQuery.toLowerCase();
    final spans = <TextSpan>[];

    var currentIndex = 0;

    while (currentIndex < text.length) {
      final matchIndex = lowercaseText.indexOf(
        lowercaseQuery,
        currentIndex,
      );

      if (matchIndex == -1) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex),
            style: style,
          ),
        );
        break;
      }

      if (matchIndex > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, matchIndex),
            style: style,
          ),
        );
      }

      final matchEnd = matchIndex + normalizedQuery.length;

      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchEnd),
          style: highlightedStyle,
        ),
      );

      currentIndex = matchEnd;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _EventSearchLoadingState extends StatelessWidget {
  const _EventSearchLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              color: _EventSearchColors.accent,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading events...',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventSearchMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EventSearchMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 26,
              vertical: 30,
            ),
            decoration: BoxDecoration(
              color: _EventSearchColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _EventSearchColors.border,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: _EventSearchColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: _EventSearchColors.accentLight,
                    size: 31,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.45,
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

class _RankedEvent {
  final EventSearchKey event;
  final int score;

  const _RankedEvent({
    required this.event,
    required this.score,
  });
}

abstract final class _EventSearchColors {
  static const background = Color(0x00090E18);
  static const appBar = Color(0xA60D1A2B);
  static const surface = Color(0x99172A40);
  static const searchField = Color(0x7A243A55);
  static const border = LiquidGlassColors.border;
  static const accent = Color(0xFF4F8CFF);
  static const accentLight = Color(0xFF82ADFF);
}
