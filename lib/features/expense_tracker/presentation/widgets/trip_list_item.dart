import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/trip_model.dart';

class TripListItem extends StatelessWidget {
  final TripModel trip;

  const TripListItem({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    // Determine the theme color based on fuel type
    final Color accentColor = trip.fuelType == 'Petrol' 
        ? AppColors.primary 
        : AppColors.accent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Full-height Left Accent Bar using Positioned.fill
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: accentColor,
              ),
            ),

            // 2. Main Content Row
            Row(
              children: [
                const SizedBox(width: 12), // Space for the accent bar
                
                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ROUTE HEADER
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getRouteText(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TripTypeBadge(isRoundTrip: trip.isRoundTrip),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // STATS ROW (Fixed: No LayoutBuilder, uses Flexible)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatItem(
                              icon: Icons.route_outlined,
                              label: Formatters.distance(
                                trip.isRoundTrip ? trip.distance * 2 : trip.distance,
                              ),
                            ),
                            _StatItem(
                              icon: Icons.water_drop_outlined,
                              label: Formatters.litres(trip.fuelUsed),
                            ),
                            _StatItem(
                              icon: Icons.event_note_outlined,
                              label: _formatCompactDate(trip.date),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Price Section (Matches height automatically)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(minHeight: 80),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.03),
                    border: Border(
                      left: BorderSide(color: AppColors.textTertiary.withOpacity(0.08)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(trip.cost),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'TOTAL',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRouteText() {
    if (trip.originName != null && trip.destinationName != null) {
      final origin = trip.originName!.split(',').first.trim();
      final dest = trip.destinationName!.split(',').first.trim();
      return '$origin → $dest';
    }
    return '${trip.fuelType} Trip';
  }

  String _formatCompactDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTypeBadge extends StatelessWidget {
  final bool isRoundTrip;

  const _TripTypeBadge({required this.isRoundTrip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRoundTrip 
            ? AppColors.primary.withOpacity(0.1) 
            : AppColors.textTertiary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isRoundTrip ? 'ROUND' : 'ONE-WAY',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isRoundTrip ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}