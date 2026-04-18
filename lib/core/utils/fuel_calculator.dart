/// Pure fuel calculation functions.
/// All functions are stateless and testable.
class FuelCalculator {
  FuelCalculator._();

  /// Calculate fuel required in litres.
  /// [distance] in km, [mileage] in km/l.
  /// Returns 0 if mileage is 0 or inputs are invalid.
  static double calculateFuelRequired({
    required double distance,
    required double mileage,
    required bool isRoundTrip,
  }) {
    if (distance <= 0 || mileage <= 0) return 0;
    final effectiveDistance = isRoundTrip ? distance * 2 : distance;
    return effectiveDistance / mileage;
  }

  /// Calculate total fuel cost in ₹.
  static double calculateTotalCost({
    required double fuelLitres,
    required double pricePerLitre,
  }) {
    if (fuelLitres <= 0 || pricePerLitre <= 0) return 0;
    return fuelLitres * pricePerLitre;
  }

  /// Calculate cost per km in ₹/km.
  static double calculateCostPerKm({
    required double totalCost,
    required double distance,
    required bool isRoundTrip,
  }) {
    final effectiveDistance = isRoundTrip ? distance * 2 : distance;
    if (effectiveDistance <= 0 || totalCost <= 0) return 0;
    return totalCost / effectiveDistance;
  }

  /// All-in-one calculation returning a result map.
  static FuelCalculationResult calculate({
    required double distance,
    required double mileage,
    required double pricePerLitre,
    required bool isRoundTrip,
  }) {
    final fuelRequired = calculateFuelRequired(
      distance: distance,
      mileage: mileage,
      isRoundTrip: isRoundTrip,
    );

    final totalCost = calculateTotalCost(
      fuelLitres: fuelRequired,
      pricePerLitre: pricePerLitre,
    );

    final costPerKm = calculateCostPerKm(
      totalCost: totalCost,
      distance: distance,
      isRoundTrip: isRoundTrip,
    );

    return FuelCalculationResult(
      fuelRequired: fuelRequired,
      totalCost: totalCost,
      costPerKm: costPerKm,
      effectiveDistance: isRoundTrip ? distance * 2 : distance,
    );
  }
}

class FuelCalculationResult {
  final double fuelRequired;
  final double totalCost;
  final double costPerKm;
  final double effectiveDistance;

  const FuelCalculationResult({
    required this.fuelRequired,
    required this.totalCost,
    required this.costPerKm,
    required this.effectiveDistance,
  });

  static const empty = FuelCalculationResult(
    fuelRequired: 0,
    totalCost: 0,
    costPerKm: 0,
    effectiveDistance: 0,
  );
}
