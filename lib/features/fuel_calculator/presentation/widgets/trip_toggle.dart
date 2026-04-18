import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/providers/fuel_calculator_provider.dart';

class TripToggleWidget extends ConsumerWidget {
  const TripToggleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRoundTrip = ref.watch(isRoundTripProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'One-way',
            icon: Icons.arrow_forward_rounded,
            isSelected: !isRoundTrip,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(isRoundTripProvider.notifier).state = false;
            },
          ),
          _ToggleOption(
            label: 'Round Trip',
            icon: Icons.swap_horiz_rounded,
            isSelected: isRoundTrip,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(isRoundTripProvider.notifier).state = true;
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
