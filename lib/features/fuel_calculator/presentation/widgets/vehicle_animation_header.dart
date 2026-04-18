import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/providers/fuel_calculator_provider.dart';
import '../../../map/domain/providers/map_provider.dart';

class VehicleAnimationHeader extends ConsumerWidget {
  const VehicleAnimationHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleType = ref.watch(vehicleTypeProvider);
    final isCalculating = ref.watch(isLoadingRouteProvider);

    return Container(
      height: 120,
      width: double.infinity,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Road decorative element
          Container(
            height: 2,
            width: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),

          // Vehicle Icon/Animation
          AnimatedSwitcher(
            duration: 500.ms,
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
            },
            child: KeyedSubtree(
              key: ValueKey(vehicleType),
              child: _buildVehicleIcon(vehicleType, isCalculating),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleIcon(VehicleType type, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          type.emoji,
          style: const TextStyle(fontSize: 60),
        )
        .animate(target: active ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -8, duration: 600.ms, curve: Curves.easeInOut)
        .shake(hz: 2, offset: const Offset(2, 0)),
        
        const SizedBox(height: 4),
        
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: const BorderRadius.all(Radius.elliptical(20, 2)),
          ),
        ).animate(target: active ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
         .scaleX(begin: 1, end: 0.7, duration: 600.ms),
      ],
    );
  }
}
