import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/providers/fuel_calculator_provider.dart';
import '../../../map/domain/providers/map_provider.dart';

class FuelResultCard extends ConsumerWidget {
  const FuelResultCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(calculationResultProvider);
    final hasResult = result.totalCost > 0;
    final origin = ref.watch(originProvider);
    final destination = ref.watch(destinationProvider);

    // Efficiency logic
    Color efficiencyColor = Colors.white;
    String insightText = '';
    if (hasResult) {
      if (result.costPerKm < 6) {
        efficiencyColor = Colors.greenAccent;
        insightText = 'Highly Efficient Trip! 🍃';
      } else if (result.costPerKm < 10) {
        efficiencyColor = Colors.orangeAccent;
        insightText = 'Moderate Trip Cost ⛽';
      } else {
        efficiencyColor = Colors.redAccent;
        insightText = 'Expensive Trip! 💸';
      }
    }

    return Column(
      children: [
        AnimatedOpacity(
          opacity: hasResult ? 1.0 : 0.0,
          duration: 400.ms,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 8,
            shadowColor: efficiencyColor.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: hasResult
                      ? [AppColors.primary, AppColors.primaryDark]
                      : [AppColors.surfaceVariant, AppColors.surfaceVariant],
                ),
              ),
              child: Column(
                children: [
                  // Total Cost (Hero number)
                  TweenAnimationBuilder<double>(
                    duration: 800.ms,
                    curve: Curves.easeOutExpo,
                    tween: Tween(begin: 0, end: hasResult ? result.totalCost : 0),
                    builder: (context, value, child) {
                      return Text(
                        value > 0 ? Formatters.currency(value) : '₹0.00',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Trip Total Cost',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Details row
                  Row(
                    children: [
                      _ResultItem(
                        icon: Icons.local_gas_station_rounded,
                        value: hasResult
                            ? Formatters.litres(result.fuelRequired)
                            : '0 L',
                        label: 'Fuel Needed',
                        color: Colors.white,
                      ),
                      _divider(),
                      _ResultItem(
                        icon: Icons.straighten_rounded,
                        value: hasResult
                            ? Formatters.distance(result.effectiveDistance)
                            : '0 km',
                        label: 'Distance',
                        color: Colors.white,
                      ),
                      _divider(),
                      _ResultItem(
                        icon: Icons.speed_rounded,
                        value: hasResult
                            ? Formatters.costPerKm(result.costPerKm)
                            : '₹0/km',
                        label: '₹/km',
                        color: efficiencyColor,
                      ),
                    ],
                  ),

                  if (hasResult) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        insightText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: efficiencyColor,
                        ),
                      ),
                    ).animate().fadeIn().scale(),
                  ],
                ],
              ),
            ),
          ).animate(target: hasResult ? 1 : 0).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        ),
        
        if (hasResult && origin != null && destination != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchNavigation(origin, destination),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Start Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.map_rounded,
                  onTap: () => _launchGoogleMaps(origin, destination),
                  tooltip: 'View in Google Maps',
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.5, end: 0),
        ],
      ],
    );
  }

  void _launchNavigation(dynamic origin, dynamic destination) async {
    final url = 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchGoogleMaps(dynamic origin, dynamic destination) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.15),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ResultItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.8)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}
