import 'package:app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Makes the public-data fallback impossible to mistake for group scouting.
class DataSourceBanner extends StatelessWidget {
  const DataSourceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn) return const SizedBox.shrink();

        return Semantics(
          container: true,
          liveRegion: true,
          label:
              'Not logged in. Data shown here is purely from The Blue Alliance.',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            color: const Color(0xFF8E2F37),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'NOT LOGGED IN — DATA SHOWN HERE IS PURELY FROM THE BLUE ALLIANCE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: auth.login,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Log in'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6F2028),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
