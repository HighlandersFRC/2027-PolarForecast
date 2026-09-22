import 'package:app/widgets/PolarForecastAppBar.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color _primary = LiquidGlassColors.primary;
  static const Color _secondary = LiquidGlassColors.secondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PolarForecastAppBar(),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  _HeroSection(
                    onExplorePressed: () {
                      // Replace with your event-search route.
                      // Navigator.pushNamed(context, '/events');

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Connect this button to your event search page.',
                          ),
                        ),
                      );
                    },
                    onGroupsPressed: () {
                      // Replace with your groups route.
                      // Navigator.pushNamed(context, '/groups');

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Connect this button to your groups page.',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  const _SectionHeader(
                    eyebrow: 'BUILT FOR COMPETITION',
                    title: 'Everything your scouting team needs',
                    description:
                        'Collect reliable data, discover patterns, and make better decisions throughout every event.',
                  ),
                  const SizedBox(height: 28),
                  const _FeatureGrid(),
                  const SizedBox(height: 60),
                  const _WorkflowBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onExplorePressed;
  final VoidCallback onGroupsPressed;

  const _HeroSection({
    required this.onExplorePressed,
    required this.onGroupsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 850;

        final introduction = Column(
          crossAxisAlignment:
              isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            const _StatusBadge(),
            const SizedBox(height: 22),
            Text(
              'Scout smarter.\nCompete stronger.',
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 64 : 44,
                height: 1.02,
                letterSpacing: -2.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Text(
                'PolarForecast transforms match and pit scouting data into '
                'clear statistics, team insights, and match predictions—giving '
                'your alliance the information it needs when every decision matters.',
                textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 17,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _HeroDetail(
                  icon: Icons.bolt_rounded,
                  label: 'Fast data entry',
                ),
                _HeroDetail(
                  icon: Icons.auto_graph_rounded,
                  label: 'Live analytics',
                ),
                _HeroDetail(
                  icon: Icons.hub_outlined,
                  label: 'Team collaboration',
                ),
              ],
            ),
          ],
        );

        const preview = _DashboardPreview();

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 11, child: introduction),
              const SizedBox(width: 60),
              const Expanded(flex: 9, child: preview),
            ],
          );
        }

        return Column(
          children: [
            introduction,
            const SizedBox(height: 44),
            preview,
          ],
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: BorderRadius.circular(100),
      blurSigma: 14,
      shadow: false,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.ac_unit_rounded,
            color: HomePage._primary,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'FRC SCOUTING & ANALYTICS',
            style: TextStyle(
              color: HomePage._primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroDetail({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      borderRadius: BorderRadius.circular(100),
      blurSigma: 12,
      shadow: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: LiquidGlassColors.aqua),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPanel(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(28),
      blurSigma: 26,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      HomePage._primary,
                      HomePage._secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.ac_unit_rounded,
                  color: Color(0xFF07101A),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Live scouting intelligence',
                      style: TextStyle(
                        color: Color(0xFF8190A1),
                        fontSize: 12,
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
                  color: const Color(0xFF48D597).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFF48D597),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(
                child: _PreviewStat(
                  label: 'Teams',
                  value: '42',
                  icon: Icons.groups_2_outlined,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _PreviewStat(
                  label: 'Matches',
                  value: '68',
                  icon: Icons.stadium_outlined,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _PreviewStat(
                  label: 'Scouted',
                  value: '94%',
                  icon: Icons.fact_check_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _PredictionCard(),
          const SizedBox(height: 12),
          const _RankingRow(
            rank: '1',
            team: '4499',
            value: '217.4',
            progress: 0.92,
          ),
          const SizedBox(height: 9),
          const _RankingRow(
            rank: '2',
            team: '118',
            value: '199.8',
            progress: 0.82,
          ),
          const SizedBox(height: 9),
          const _RankingRow(
            rank: '3',
            team: '2996',
            value: '188.5',
            progress: 0.74,
          ),
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PreviewStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.13),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: HomePage._primary,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7D8B9C),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HomePage._primary.withOpacity(0.1),
            HomePage._secondary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: HomePage._primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Match prediction',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Qualification 38',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const _AllianceScore(
                label: 'RED',
                score: '184',
                alignment: CrossAxisAlignment.start,
                color: Color(0xFFFF6874),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.28),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '74% confidence',
                      style: TextStyle(
                        color: HomePage._primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const _AllianceScore(
                label: 'BLUE',
                score: '152',
                alignment: CrossAxisAlignment.end,
                color: HomePage._primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllianceScore extends StatelessWidget {
  final String label;
  final String score;
  final Color color;
  final CrossAxisAlignment alignment;

  const _AllianceScore({
    required this.label,
    required this.score,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          score,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final String rank;
  final String team;
  final String value;
  final double progress;

  const _RankingRow({
    required this.rank,
    required this.team,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank,
              style: const TextStyle(
                color: Color(0xFF69798A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Team $team',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  HomePage._primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            value,
            style: const TextStyle(
              color: HomePage._primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: HomePage._primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    const features = [
      _FeatureData(
        icon: Icons.query_stats_rounded,
        title: 'Team analytics',
        description:
            'Compare OPR, autonomous, teleop, endgame, reliability, and performance trends.',
      ),
      _FeatureData(
        icon: Icons.fact_check_outlined,
        title: 'Match scouting',
        description:
            'Capture structured match data quickly with an interface built for scouts in the stands.',
      ),
      _FeatureData(
        icon: Icons.precision_manufacturing_outlined,
        title: 'Pit scouting',
        description:
            'Record robot capabilities, mechanisms, strategies, and notes before matches begin.',
      ),
      _FeatureData(
        icon: Icons.auto_graph_rounded,
        title: 'Match predictions',
        description:
            'Estimate alliance scores and likely winners using current event performance data.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns;

        if (constraints.maxWidth >= 950) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: features
              .map(
                (feature) => SizedBox(
                  width: cardWidth,
                  child: _FeatureCard(data: feature),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FeatureCard extends StatefulWidget {
  final _FeatureData data;

  const _FeatureCard({
    required this.data,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(
          0,
          _hovered ? -5 : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [],
        ),
        child: LiquidGlassPanel(
          padding: const EdgeInsets.all(22),
          borderRadius: BorderRadius.circular(21),
          tint: _hovered ? HomePage._primary : HomePage._secondary,
          blurSigma: _hovered ? 22 : 16,
          shadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HomePage._primary.withOpacity(0.2),
                      HomePage._secondary.withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: HomePage._primary.withOpacity(0.18),
                  ),
                ),
                child: Icon(
                  widget.data.icon,
                  color: HomePage._primary,
                  size: 23,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.data.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowBanner extends StatelessWidget {
  const _WorkflowBanner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LiquidGlassPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 28,
        ),
        borderRadius: BorderRadius.circular(25),
        tint: HomePage._secondary,
        blurSigma: 22,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 700;

            final title = Column(
              crossAxisAlignment:
                  isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                const Text(
                  'From the stands to alliance selection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'One connected scouting workflow for your entire team.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            );

            const steps = Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                _WorkflowStep(number: '01', label: 'Collect'),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF526273),
                  size: 18,
                ),
                _WorkflowStep(number: '02', label: 'Analyze'),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF526273),
                  size: 18,
                ),
                _WorkflowStep(number: '03', label: 'Strategize'),
              ],
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 24),
                  steps,
                ],
              );
            }

            return Column(
              children: [
                title,
                const SizedBox(height: 24),
                steps,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final String number;
  final String label;

  const _WorkflowStep({
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.10),
            HomePage._primary.withOpacity(0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: HomePage._primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
