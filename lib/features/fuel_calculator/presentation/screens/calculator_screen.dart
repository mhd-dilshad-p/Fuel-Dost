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
    // Get device size for responsive adjustments
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black, // Dark base for map contrast
      body: Stack(
        children: [
          // 1. FULL SCREEN MAP VIEW
          const Positioned.fill(
            child: MapViewWidget(),
          ),

          // 2. STATUS BAR ATMOSPHERE (Top Gradient)
          // Makes the system icons (time/battery) visible and looks premium
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. PREMIUM DRAGGABLE BOTTOM SHEET
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.18, // Allows user to see more of the map
            maxChildSize: 0.96,
            snap: true,
            controller: _sheetController,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 40,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle Bar Section
                    Container(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 40),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Vehicle Header (Animations)
                          const VehicleAnimationHeader(),

                          const SizedBox(height: 8),

                          // Quick Actions Row
                          const QuickActionsWidget(),

                          const SizedBox(height: 24),

                          // ROUTE INFO SECTION
                          // Wrapped in a subtle shadow for elevation
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: const RouteInfoCard(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // INPUT SECTION
                          const FuelInputCard(),

                          const SizedBox(height: 16),

                          // TRIP TOGGLE
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: TripToggleWidget(),
                          ),

                          const SizedBox(height: 24),

                          // RESULTS SECTION
                          const FuelResultCard(),

                          const SizedBox(height: 32),

                          // SAVE TRIP BUTTON
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _SaveTripButton(),
                          ),
                          
                          // Bottom extra padding for large screens
                          SizedBox(height: screenHeight * 0.05),
                        ],
                      ),
                    ),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        // Active Gradient
        gradient: hasResult
            ? LinearGradient(
                colors: [
                  AppColors.accent,
                  AppColors.accent.withBlue(255).withRed(80), // Subtle premium shift
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        // Inactive color
        color: hasResult ? null : AppColors.textTertiary.withOpacity(0.1),
        boxShadow: [
          if (hasResult)
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasResult ? () => _saveTrip(context, ref) : null,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasResult ? Icons.bolt_rounded : Icons.lock_outline_rounded,
                color: hasResult ? Colors.white : AppColors.textTertiary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'CONFIRM & SAVE TRIP',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: hasResult ? Colors.white : AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
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

    ref.read(tripsProvider.notifier).saveTrip(
          distance: distance,
          fuelUsed: result.fuelRequired,
          cost: result.totalCost,
          fuelType: fuelType.displayName,
          vehicleType: ref.read(vehicleTypeProvider).displayName,
          mileage: mileage,
          fuelPrice: price,
          isRoundTrip: isRoundTrip,
          originName: originName,
          destinationName: destinationName,
        );

    // Provide heavy premium haptic feedback
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Trip Recorded: ${Formatters.currency(result.totalCost)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}