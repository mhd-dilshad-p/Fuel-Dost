import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _ActionCard(
                icon: Icons.work_history_rounded,
                label: 'Home → Work',
                onTap: () => _setPreset(ref, 'Work', const LatLng(28.5355, 77.3910)), // Example coord
              ),
              _ActionCard(
                icon: Icons.history_rounded,
                label: 'Last Trip',
                onTap: () {
                  // Re-use last trip logic (would fetch from hive in real app)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Re-applying last trip...')),
                  );
                },
              ),
              _ActionCard(
                icon: Icons.star_rounded,
                label: 'Favorites',
                onTap: () {},
                color: Colors.amber[700],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setPreset(WidgetRef ref, String name, LatLng dest) {
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.primary),
            const SizedBox(width: 8),
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
    );
  }
}
