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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Fuel type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: trip.fuelType == 'Petrol'
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_gas_station_rounded,
                color: trip.fuelType == 'Petrol'
                    ? AppColors.primary
                    : AppColors.accent,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // Trip details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route
                  Text(
                    _getRouteText(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Details
                  Row(
                    children: [
                      _DetailChip(
                        icon: Icons.straighten,
                        text: Formatters.distance(
                          trip.isRoundTrip
                              ? trip.distance * 2
                              : trip.distance,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _DetailChip(
                        icon: Icons.local_gas_station,
                        text: Formatters.litres(trip.fuelUsed),
                      ),
                      const SizedBox(width: 12),
                      _DetailChip(
                        icon: Icons.calendar_today,
                        text: Formatters.date(trip.date),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Cost
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(trip.cost),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  trip.isRoundTrip ? 'Round trip' : 'One-way',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
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
      final origin = trip.originName!.split(',').first;
      final dest = trip.destinationName!.split(',').first;
      return '$origin → $dest';
    }
    return '${trip.fuelType} Trip • ${Formatters.distance(trip.distance)}';
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
