import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../expense_tracker/domain/providers/expense_provider.dart';
import '../../domain/providers/insights_provider.dart';
import '../widgets/spending_chart.dart';
import '../widgets/trend_card.dart';
import '../widgets/suggestion_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    final suggestions = ref.watch(suggestionsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: trips.isEmpty
          ? _EmptyInsights(topPadding: topPadding)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. PREMIUM DYNAMIC APP BAR
                SliverAppBar(
                  expandedHeight: 80,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  // Adds professional status bar styling
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insights',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: -1.0,
                          ),
                        ),
                        // Collapses when scrolled
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),

                // 2. PRIMARY CHART: MONTHLY SPENDING
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _PremiumSectionCard(
                      title: 'Monthly Spending',
                      subtitle: 'Historical patterns',
                      icon: Icons.bubble_chart_rounded,
                      accentColor: AppColors.primary,
                      child: const SizedBox(
                        height: 240,
                        child: SpendingChart(),
                      ),
                    ),
                  ),
                ),

                // 3. SECONDARY CHART: TREND
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: _PremiumSectionCard(
                      title: 'Efficiency Trend',
                      subtitle: 'Cost per kilometer',
                      icon: Icons.analytics_outlined,
                      accentColor: AppColors.accent,
                      child: const SizedBox(
                        height: 200,
                        child: TrendCard(),
                      ),
                    ),
                  ),
                ),

                // 4. SMART TIPS SECTION HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Smart Recommendations',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.accent.withOpacity(0.5)),
                      ],
                    ),
                  ),
                ),

                // 5. SUGGESTION LIST
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SuggestionCard(suggestion: suggestions[index]),
                        );
                      },
                      childCount: suggestions.length,
                    ),
                  ),
                ),

                // Bottom Spacing for Navigation Bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}

class _PremiumSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _PremiumSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textTertiary.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Decorative Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withOpacity(0.2), accentColor.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Premium Detail Indicator
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary.withOpacity(0.3)),
              ],
            ),
          ),
          // Chart Container with subtle background padding
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  final double topPadding;
  const _EmptyInsights({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: topPadding + 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Insights',
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const Spacer(),
        Center(
          child: Column(
            children: [
              // Premium Animated-style illustration placeholder
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [AppColors.accent.withOpacity(0.1), Colors.transparent],
                      ),
                    ),
                  ),
                  Icon(Icons.auto_graph_rounded, size: 64, color: AppColors.accent.withOpacity(0.8)),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Analyzing Trends...',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Record more trips to allow our smart engine to calculate your fuel efficiency and saving patterns.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textTertiary,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}