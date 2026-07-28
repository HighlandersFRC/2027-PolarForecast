import 'package:app/pages/home_page.dart';
import 'package:app/pages/event_page.dart';
import 'package:app/pages/group_page.dart';
import 'package:app/pages/team_page.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/FollowUps.dart';
import 'package:app/widgets/PitScoutingTeamPage.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final auth = AuthService();
  await auth.init();

  runApp(
    ChangeNotifierProvider<AuthService>.value(
      value: auth,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polar Forecast',
      theme: buildLiquidGlassTheme(),
      builder: (context, child) => LiquidGlassBackground(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'event') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => EventPage(eventCode: uri.pathSegments[1]),
          );
        }

        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'group') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => GroupPage(groupName: uri.pathSegments[1]),
          );
        }

        if (uri.pathSegments.length == 4 &&
            uri.pathSegments[0] == 'event' &&
            uri.pathSegments[3] == 'team') {
          final eventCode = uri.pathSegments[1];

          final team = int.parse(uri.pathSegments[2]);
          final auth = context.read<AuthService>();
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => TeamPage(
              eventCode: eventCode,
              team: team,
              groupId: auth.groupId ?? '',
              username: auth.username ?? '',
            ),
          );
        }

        if (uri.pathSegments.length == 5 &&
            uri.pathSegments[0] == 'event' &&
            uri.pathSegments[2] == 'team' &&
            uri.pathSegments[4] == 'pitscouting') {
          final eventCode = uri.pathSegments[1];
          final team = int.parse(uri.pathSegments[3]);

          return MaterialPageRoute(
              settings: settings,
              builder: (_) =>
                  PitScoutingTeamPage(teamNumber: team, eventCode: eventCode));
        }

        if (uri.pathSegments.length == 5 &&
            uri.pathSegments[0] == 'event' &&
            uri.pathSegments[2] == 'team' &&
            uri.pathSegments[4] == 'followup') {
          final eventCode = uri.pathSegments[1];
          final team = int.parse(uri.pathSegments[3]);

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => FollowUpPage(
              eventCode: eventCode,
              teamNumber: team,
            ),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomePage(),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
