import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/trip_model.dart';
import '../../data/repositories/trip_repository.dart';

// ─── Repository ─────────────────────────────────────────────────

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

// ─── Trips List ─────────────────────────────────────────────────

/// All trips (triggers rebuild when trips change).
final tripsProvider = StateNotifierProvider<TripsNotifier, List<TripModel>>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  return TripsNotifier(repository);
});

class TripsNotifier extends StateNotifier<List<TripModel>> {
  final TripRepository _repository;
  static const _uuid = Uuid();

  TripsNotifier(this._repository) : super([]) {
    _loadTrips();
  }

  void _loadTrips() {
    state = _repository.getAllTrips();
  }

  /// Save a new trip.
  Future<void> saveTrip({
    required double distance,
    required double fuelUsed,
    required double cost,
    required String fuelType,
    required String vehicleType,
    required double mileage,
    required double fuelPrice,
    required bool isRoundTrip,
    String? originName,
    String? destinationName,
  }) async {
    final trip = TripModel(
      id: _uuid.v4(),
      date: DateTime.now(),
      distance: distance,
      fuelUsed: fuelUsed,
      cost: cost,
      originName: originName,
      destinationName: destinationName,
      fuelType: fuelType,
      vehicleType: vehicleType,
      mileage: mileage,
      fuelPrice: fuelPrice,
      isRoundTrip: isRoundTrip,
    );

    await _repository.saveTrip(trip);
    _loadTrips();
  }

  /// Delete a trip.
  Future<void> deleteTrip(String id) async {
    await _repository.deleteTrip(id);
    _loadTrips();
  }

  /// Refresh trips from database.
  void refresh() {
    _loadTrips();
  }
}

// ─── Computed Providers ─────────────────────────────────────────

/// Recent trips (last 10).
final recentTripsProvider = Provider<List<TripModel>>((ref) {
  final trips = ref.watch(tripsProvider);
  return trips.take(10).toList();
});

/// Current month total spending.
final monthlyTotalProvider = Provider<double>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  final now = DateTime.now();
  // Need to trigger rebuild when trips change
  ref.watch(tripsProvider);
  return repository.getMonthlyTotal(now.year, now.month);
});

/// Current month total distance.
final monthlyDistanceProvider = Provider<double>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  final now = DateTime.now();
  ref.watch(tripsProvider);
  return repository.getMonthlyDistance(now.year, now.month);
});

/// Current month average cost per km.
final monthlyAvgCostPerKmProvider = Provider<double>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  final now = DateTime.now();
  ref.watch(tripsProvider);
  return repository.getMonthlyAvgCostPerKm(now.year, now.month);
});

/// Monthly spending history for charts (last 6 months).
final monthlySpendingHistoryProvider = Provider<List<MonthlyData>>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  ref.watch(tripsProvider);
  return repository.getMonthlySpendingHistory(months: 6);
});
