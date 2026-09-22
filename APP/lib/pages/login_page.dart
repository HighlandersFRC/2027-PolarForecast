import 'package:app/APIService.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _groupNameController = TextEditingController();
  String? _groupMessage;
  bool _isCreatingGroup = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final api = APIService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const PolarForecastAppBar(
        extraText: 'Account',
        showAccountAction: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LiquidGlassPanel(
              tint: LiquidGlassColors.secondary,
              blurSigma: 28,
              padding: const EdgeInsets.all(28),
              child: auth.isLoggedIn
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${auth.firstName ?? '-'}'),
                          Text('Username: ${auth.username ?? '-'}'),
                          if (auth.group != null && auth.group!.isNotEmpty)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushNamed('/group/${auth.group}');
                                },
                                child: Text(
                                  'Group: ${auth.group}',
                                  style: const TextStyle(
                                    color: LiquidGlassColors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: LiquidGlassColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Text('Group: -'),
                          Text('Team: ${auth.team?.toString() ?? '-'}'),
                          const SizedBox(height: 20),
                          if (auth.group == null || auth.group!.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Create a group:'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _groupNameController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Group name',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_groupMessage != null)
                                  Text(
                                    _groupMessage!,
                                    style: TextStyle(
                                      color: _groupMessage!
                                              .startsWith('Group created')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _isCreatingGroup
                                      ? null
                                      : () async {
                                          final groupName =
                                              _groupNameController.text.trim();
                                          if (groupName.isEmpty) {
                                            setState(() {
                                              _groupMessage =
                                                  'Enter a group name first.';
                                            });
                                            return;
                                          }

                                          setState(() {
                                            _isCreatingGroup = true;
                                            _groupMessage = null;
                                          });

                                          try {
                                            // ignore: unused_local_variable
                                            final response =
                                                await api.createGroup(
                                              groupName,
                                              username: auth.username,
                                            );
                                            // Refresh tokens to get updated group claims from Keycloak
                                            await auth.refreshTokens();
                                            setState(() {
                                              _groupMessage =
                                                  'Group created successfully.';
                                            });
                                          } catch (e) {
                                            setState(() {
                                              _groupMessage =
                                                  'Unable to create group: ${e.toString()}';
                                            });
                                          } finally {
                                            setState(() {
                                              _isCreatingGroup = false;
                                            });
                                          }
                                        },
                                  child: _isCreatingGroup
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Create group'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              await auth.logout();
                              if (Navigator.canPop(context))
                                Navigator.of(context).pop();
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        try {
                          await auth.login();
                          if (Navigator.canPop(context))
                            Navigator.of(context).pop();
                        } catch (e) {
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Login failed: ${e.toString()}')),
                          );
                        }
                      },
                      child: const Text('Login with Keycloak'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
