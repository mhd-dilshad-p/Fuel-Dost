import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/providers/insights_provider.dart';

class SuggestionCard extends StatelessWidget {
  final InsightSuggestion suggestion;

  const SuggestionCard({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestion.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _backgroundColor {
    switch (suggestion.type) {
      case SuggestionType.success:
        return AppColors.primary.withOpacity(0.05);
      case SuggestionType.warning:
        return AppColors.accent.withOpacity(0.05);
      case SuggestionType.tip:
        return AppColors.info.withOpacity(0.05);
      case SuggestionType.info:
        return AppColors.surfaceVariant;
    }
  }

  Color get _borderColor {
    switch (suggestion.type) {
      case SuggestionType.success:
        return AppColors.primary.withOpacity(0.2);
      case SuggestionType.warning:
        return AppColors.accent.withOpacity(0.2);
      case SuggestionType.tip:
        return AppColors.info.withOpacity(0.2);
      case SuggestionType.info:
        return AppColors.divider;
    }
  }
}
