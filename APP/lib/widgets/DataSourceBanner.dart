import 'package:app/services/auth_service.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DataSourceBanner extends StatelessWidget {
  const DataSourceBanner({super.key});
  @override
  Widget build(BuildContext context) =>
      Consumer<AuthService>(builder: (context, auth, _) {
        if (auth.isLoggedIn) return const SizedBox.shrink();
        return Semantics(
            container: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: const BoxDecoration(
                  color: AppColors.surfaceSoft,
                  border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 17, color: AppColors.secondary),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text(
                        'Public data from The Blue Alliance. Log in for group scouting.',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.4))),
                const SizedBox(width: 8),
                TextButton(
                    onPressed: () async {
                      try {
                        await auth.login();
                      } catch (_) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Could not log in. Please try again.')));
                      }
                    },
                    child: const Text('Log in')),
              ]),
            ));
      });
}
