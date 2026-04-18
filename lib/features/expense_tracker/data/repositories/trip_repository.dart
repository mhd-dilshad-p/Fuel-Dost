import 'package:hive/hive.dart';
import '../../../../database/hive_service.dart';
import '../models/trip_model.dart';

/// Repository for CRUD operations on saved trips.
class TripRepository {
  Box<TripModel> get _box => HiveService.getTripsBox();

  /// Get all trips sorted by date (newest first).
  List<TripModel> getAllTrips() {
    final trips = _box.values.toList();
    trips.sort((a, b) => b.date.compareTo(a.date));
    return trips;
  }

  /// Get recent trips (limited count).
  List<TripModel> getRecentTrips({int limit = 10}) {
    final trips = getAllTrips();
    return trips.take(limit).toList();
  }

  /// Get trips within a date range.
  List<TripModel> getTripsByDateRange(DateTime start, DateTime end) {
    return getAllTrips()
        .where((t) =>
            t.date.isAfter(start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  /// Get trips for a specific month/year.
  List<TripModel> getTripsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getTripsByDateRange(start, end);
  }

  /// Save a new trip.
  Future<void> saveTrip(TripModel trip) async {
    await _box.put(trip.id, trip);
  }

  /// Delete a trip by ID.
  Future<void> deleteTrip(String id) async {
    await _box.delete(id);
  }

  /// Get monthly total spending.
  double getMonthlyTotal(int year, int month) {
    final trips = getTripsForMonth(year, month);
    return trips.fold(0.0, (sum, trip) => sum + trip.cost);
  }

  /// Get monthly total distance.
  double getMonthlyDistance(int year, int month) {
    final trips = getTripsForMonth(year, month);
    return trips.fold(0.0, (sum, trip) {
      final d = trip.isRoundTrip ? trip.distance * 2 : trip.distance;
      return sum + d;
    });
  }

  /// Get monthly average cost per km.
  double getMonthlyAvgCostPerKm(int year, int month) {
    final totalCost = getMonthlyTotal(year, month);
    final totalDistance = getMonthlyDistance(year, month);
    if (totalDistance <= 0) return 0;
    return totalCost / totalDistance;
  }

  /// Get last N months spending data for charts.
  List<MonthlyData> getMonthlySpendingHistory({int months = 6}) {
    final result = <MonthlyData>[];
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final total = getMonthlyTotal(date.year, date.month);
      final distance = getMonthlyDistance(date.year, date.month);
      final trips = getTripsForMonth(date.year, date.month);

      result.add(MonthlyData(
        year: date.year,
        month: date.month,
        totalSpending: total,
        totalDistance: distance,
        tripCount: trips.length,
        avgCostPerKm: distance > 0 ? total / distance : 0,
      ));
    }

    return result;
  }

  /// Get total trip count.
  int get totalTrips => _box.length;
}

/// Data class for monthly statistics.
class MonthlyData {
  final int year;
  final int month;
  final double totalSpending;
  final double totalDistance;
  final int tripCount;
  final double avgCostPerKm;

  const MonthlyData({
    required this.year,
    required this.month,
    required this.totalSpending,
    required this.totalDistance,
    required this.tripCount,
    required this.avgCostPerKm,
  });

  DateTime get date => DateTime(year, month);
}
