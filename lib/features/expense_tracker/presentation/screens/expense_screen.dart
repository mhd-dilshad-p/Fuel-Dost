import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/providers/expense_provider.dart';
import '../widgets/trip_list_item.dart';
import '../widgets/monthly_summary_card.dart';

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    // Get device padding for safe area logic
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: trips.isEmpty 
          ? _EmptyState(topPadding: topPadding) 
          : _TripsList(trips: trips, topPadding: topPadding),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double topPadding;
  const _EmptyState({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: topPadding + 20),
        _HeaderSection(count: 0),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.5,
                  child: Icon(Icons.receipt_long_rounded, size: 80, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Records Found',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int count;
  const _HeaderSection({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expenses',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'History & Insights',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count trips',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripsList extends ConsumerWidget {
  final List trips;
  final double topPadding;

  const _TripsList({required this.trips, required this.topPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPadding + 20)),
        
        // 1. Title Header
        SliverToBoxAdapter(child: _HeaderSection(count: trips.length)),
        
        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // 2. Summary Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MonthlySummaryCard(),
          ),
        ),

        // 3. Section Divider
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Text(
              'RECENT ACTIVITY',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),

        // 4. List Items
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final trip = trips[index];
                return Dismissible(
                  key: Key(trip.id),
                  direction: DismissDirection.endToStart,
                  onUpdate: (details) {
                    if (details.reached && !details.previousReached) {
                      HapticFeedback.lightImpact();
                    }
                  },
                  background: _buildDeleteBackground(),
                  confirmDismiss: (dir) => _showDeleteConfirm(context, trip),
                  onDismissed: (_) => ref.read(tripsProvider.notifier).deleteTrip(trip.id),
                  child: TripListItem(trip: trip),
                );
              },
              childCount: trips.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
    );
  }

 Future<bool?> _showDeleteConfirm(BuildContext context, dynamic trip) {
    // FIX: Changed warningImpact to heavyImpact
    HapticFeedback.heavyImpact(); 
    
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Trip?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text('Remove this entry of ${Formatters.currency(trip.cost)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, 
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}