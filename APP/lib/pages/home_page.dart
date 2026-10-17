import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/global_rankings_board.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        appBar: PolarForecastAppBar(),
        backgroundColor: Colors.transparent,
        body: SafeArea(top: false, child: GlobalRankingsBoard()),
      );
}
