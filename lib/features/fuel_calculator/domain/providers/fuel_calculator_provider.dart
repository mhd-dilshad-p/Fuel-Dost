import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/fuel_calculator.dart';
import '../../data/models/fuel_price_model.dart';
import '../../data/repositories/fuel_price_repository.dart';

// ─── Repositories ───────────────────────────────────────────────

final fuelPriceRepositoryProvider = Provider<FuelPriceRepository>((ref) {
  return FuelPriceRepository();
});

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

/// Auto vs Manual fuel price toggle.
final isAutoFuelPriceProvider = StateProvider<bool>((ref) => true);

/// Manual fuel price override (null = use API price).
final fuelPriceOverrideProvider = StateProvider<double?>((ref) => null);

/// User's detected city for fuel price lookup.
final userCityProvider = StateProvider<String>((ref) => 'Delhi');

// ─── Fuel Price Provider ────────────────────────────────────────

/// Async provider that fetches fuel price based on city.
final fuelPriceProvider = FutureProvider<FuelPriceModel>((ref) async {
  final city = ref.watch(userCityProvider);
  final repository = ref.read(fuelPriceRepositoryProvider);
  return repository.getFuelPrice(city);
});

/// The effective fuel price to use in calculations.
/// Uses override if set, otherwise API price based on fuel type.
final effectiveFuelPriceProvider = Provider<double>((ref) {
  final isAuto = ref.watch(isAutoFuelPriceProvider);
  final override = ref.watch(fuelPriceOverrideProvider);

  if (!isAuto && override != null && override > 0) return override;

  final fuelType = ref.watch(fuelTypeProvider);
  final priceAsync = ref.watch(fuelPriceProvider);

  return priceAsync.when(
    data: (model) {
      return fuelType == FuelType.petrol
          ? model.petrolPrice
          : model.dieselPrice;
    },
    loading: () {
      return fuelType == FuelType.petrol ? 103.44 : 90.56; // defaults
    },
    error: (_, __) {
      return fuelType == FuelType.petrol ? 103.44 : 90.56;
    },
  );
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
