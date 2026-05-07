import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added missing import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../map/domain/providers/map_provider.dart';
import 'package:latlong2/latlong.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _ActionCard(
                icon: Icons.work_history_rounded,
                label: 'Home → Work',
                onTap: () => _setPreset(ref, 'Work', const LatLng(28.5355, 77.3910)),
              ),
              _ActionCard(
                icon: Icons.history_rounded,
                label: 'Last Trip',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loading last trip settings...')),
                  );
                },
              ),
              _ActionCard(
                icon: Icons.star_rounded,
                label: 'Favorites',
                onTap: () {
                  HapticFeedback.selectionClick();
                },
                color: Colors.amber[700],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setPreset(WidgetRef ref, String name, LatLng dest) {
    HapticFeedback.selectionClick();
    setDebouncedDestination(ref, dest);
    ref.read(destinationAddressProvider.notifier).state = name;
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color ?? AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}