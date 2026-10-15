import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/global_rankings_board.dart';
import 'package:app/widgets/snowfall.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const PolarForecastAppBar(),
        backgroundColor: Colors.transparent,
        body: const Snowfall(
          child: SafeArea(top: false, child: GlobalRankingsBoard()),
        ),
      );
}
