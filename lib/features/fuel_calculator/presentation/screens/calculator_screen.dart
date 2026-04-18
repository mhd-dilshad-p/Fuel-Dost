import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/providers/fuel_calculator_provider.dart';
import '../../../map/domain/providers/map_provider.dart';
import '../../../expense_tracker/domain/providers/expense_provider.dart';
import '../widgets/fuel_input_card.dart';
import '../widgets/fuel_result_card.dart';
import '../widgets/trip_toggle.dart';
import '../../../map/presentation/widgets/map_view.dart';
import '../../../map/presentation/widgets/route_info_card.dart';

import '../widgets/vehicle_animation_header.dart';
import '../widgets/quick_actions.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(initLocationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map View (full screen behind sheet)
          const Positioned.fill(
            child: MapViewWidget(),
          ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.12,
            maxChildSize: 0.95,
            controller: _sheetController,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 14, bottom: 8),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // PREMIUM ANIMATION HEADER
                    const VehicleAnimationHeader(),

                    // QUICK ACTIONS
                    const QuickActionsWidget(),

                    const SizedBox(height: 12),

                    // SECTION 1: Route Info (Distance & Time)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: RouteInfoCard(),
                    ),

                    const SizedBox(height: 16),

                    // Input Card
                    const FuelInputCard(),

                    const SizedBox(height: 12),

                    // Trip Toggle
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TripToggleWidget(),
                    ),

                    const SizedBox(height: 16),

                    // Results Card
                    const FuelResultCard(),

                    const SizedBox(height: 16),

                    // Save Trip Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SaveTripButton(),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SaveTripButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(calculationResultProvider);
    final hasResult = result.totalCost > 0;

    return AnimatedOpacity(
      opacity: hasResult ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: hasResult
              ? () => _saveTrip(context, ref)
              : null,
          icon: const Icon(Icons.save_rounded, size: 20),
          label: Text(
            'Save Trip',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.textTertiary.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  void _saveTrip(BuildContext context, WidgetRef ref) {
    final distance = ref.read(distanceProvider);
    final result = ref.read(calculationResultProvider);
    final fuelType = ref.read(fuelTypeProvider);
    final mileage = ref.read(mileageProvider);
    final price = ref.read(effectiveFuelPriceProvider);
    final isRoundTrip = ref.read(isRoundTripProvider);
    final routeAsync = ref.read(routeProvider);

    String? originName;
    String? destinationName;
    routeAsync.whenData((route) {
      if (route != null) {
        originName = route.originAddress;
        destinationName = route.destinationAddress;
      }
    });

    final vehicleType = ref.read(vehicleTypeProvider);

    ref.read(tripsProvider.notifier).saveTrip(
          distance: distance,
          fuelUsed: result.fuelRequired,
          cost: result.totalCost,
          fuelType: fuelType.displayName,
          vehicleType: vehicleType.displayName,
          mileage: mileage,
          fuelPrice: price,
          isRoundTrip: isRoundTrip,
          originName: originName,
          destinationName: destinationName,
        );

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Trip saved! ${Formatters.currency(result.totalCost)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
