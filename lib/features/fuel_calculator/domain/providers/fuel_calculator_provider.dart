import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/fuel_calculator.dart';

// ─── Input State Providers ──────────────────────────────────────

/// Distance in km (auto-filled from map or manual input).
final distanceProvider = StateProvider<double>((ref) => 0);

/// Method used for distance input (Auto Map vs Manual Entry).
final distanceMethodProvider = StateProvider<DistanceMethod>((ref) => DistanceMethod.auto);

/// Vehicle type: bike or car.
final vehicleTypeProvider = StateProvider<VehicleType>((ref) => VehicleType.car);

/// Vehicle mileage in km/l.
final mileageProvider = StateProvider<double>((ref) => 15);

/// Fuel type: petrol or diesel.
final fuelTypeProvider = StateProvider<FuelType>((ref) => FuelType.petrol);

/// One-way or round trip toggle.
final isRoundTripProvider = StateProvider<bool>((ref) => false);

/// Manual fuel price override — entered by the user for their region.
final fuelPriceOverrideProvider = StateProvider<double?>((ref) => null);

/// The effective fuel price — always uses the manual override set by the user.
/// Fuel prices vary by region, so manual entry is required.
final effectiveFuelPriceProvider = Provider<double>((ref) {
  final override = ref.watch(fuelPriceOverrideProvider);
  if (override != null && override > 0) return override;
  return 0; // Returns 0 if no price entered yet (calculation won't run)
});

// ─── Calculation Result ─────────────────────────────────────────

/// Real-time calculation result computed from all inputs.
final calculationResultProvider = Provider<FuelCalculationResult>((ref) {
  final distance = ref.watch(distanceProvider);
  final mileage = ref.watch(mileageProvider);
  final price = ref.watch(effectiveFuelPriceProvider);
  final isRoundTrip = ref.watch(isRoundTripProvider);

  if (distance <= 0 || mileage <= 0 || price <= 0) {
    return FuelCalculationResult.empty;
  }

  return FuelCalculator.calculate(
    distance: distance,
    mileage: mileage,
    pricePerLitre: price,
    isRoundTrip: isRoundTrip,
  );
});

// ─── Enums ──────────────────────────────────────────────────────

enum FuelType {
  petrol,
  diesel;

  String get displayName => this == FuelType.petrol ? 'Petrol' : 'Diesel';
}

enum VehicleType {
  bike,
  car;

  String get emoji => this == VehicleType.bike ? '🛵' : '🚗';
  String get displayName => this == VehicleType.bike ? 'Bike' : 'Car';
}

enum DistanceMethod {
  auto,
  manual;

  String get displayName => this == DistanceMethod.auto ? 'Auto (Map)' : 'Manual';
}
