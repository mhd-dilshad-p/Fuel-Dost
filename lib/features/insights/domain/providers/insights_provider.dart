import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../expense_tracker/domain/providers/expense_provider.dart';

// ─── Insights Data ──────────────────────────────────────────────

/// Smart suggestions based on trip data.
final suggestionsProvider = Provider<List<InsightSuggestion>>((ref) {
  final trips = ref.watch(tripsProvider);
  final repository = ref.read(tripRepositoryProvider);
  final suggestions = <InsightSuggestion>[];

  if (trips.isEmpty) {
    suggestions.add(InsightSuggestion(
      icon: '🚗',
      title: 'Start Tracking',
      message: 'Save your first trip to get personalized fuel insights!',
      type: SuggestionType.info,
    ));
    return suggestions;
  }

  final now = DateTime.now();
  final currentMonth = repository.getMonthlyTotal(now.year, now.month);
  final prevMonth = repository.getMonthlyTotal(
    now.month == 1 ? now.year - 1 : now.year,
    now.month == 1 ? 12 : now.month - 1,
  );

  // Spending comparison
  if (prevMonth > 0 && currentMonth > prevMonth) {
    final increase = currentMonth - prevMonth;
    final pct = ((increase / prevMonth) * 100).toStringAsFixed(0);
    suggestions.add(InsightSuggestion(
      icon: '📈',
      title: 'Spending Increased',
      message:
          'Fuel spending increased $pct% compared to last month (+₹${increase.toStringAsFixed(0)})',
      type: SuggestionType.warning,
    ));
  } else if (prevMonth > 0 && currentMonth < prevMonth) {
    final savings = prevMonth - currentMonth;
    suggestions.add(InsightSuggestion(
      icon: '🎉',
      title: 'Great Savings!',
      message:
          'You saved ₹${savings.toStringAsFixed(0)} this month compared to last month!',
      type: SuggestionType.success,
    ));
  }

  // Mileage improvement suggestion
  if (trips.length >= 3) {
    final avgMileage =
        trips.take(10).fold(0.0, (sum, t) => sum + t.mileage) /
            trips.take(10).length.clamp(1, 10);
    final potentialSavings = _calculateMileageSavings(
      avgMileage: avgMileage,
      monthlyDistance: repository.getMonthlyDistance(now.year, now.month),
      fuelPrice: trips.first.fuelPrice,
    );

    if (potentialSavings > 50) {
      suggestions.add(InsightSuggestion(
        icon: '💡',
        title: 'Improve Mileage',
        message:
            'Improving mileage by 2 km/l could save you ₹${potentialSavings.toStringAsFixed(0)}/month',
        type: SuggestionType.tip,
      ));
    }
  }

  // Fuel type comparison
  final petrolTrips = trips.where((t) => t.fuelType == 'Petrol');
  final dieselTrips = trips.where((t) => t.fuelType == 'Diesel');
  if (petrolTrips.isNotEmpty && dieselTrips.isEmpty) {
    suggestions.add(InsightSuggestion(
      icon: '⛽',
      title: 'Consider Diesel',
      message:
          'Diesel vehicles often have better mileage and lower per-km costs',
      type: SuggestionType.info,
    ));
  }

  // Driving habit tip
  suggestions.add(InsightSuggestion(
    icon: '🌿',
    title: 'Eco Driving Tip',
    message:
        'Maintaining steady speeds between 45-65 km/h can improve fuel efficiency by up to 15%',
    type: SuggestionType.tip,
  ));

  return suggestions;
});

double _calculateMileageSavings({
  required double avgMileage,
  required double monthlyDistance,
  required double fuelPrice,
}) {
  if (avgMileage <= 0 || monthlyDistance <= 0) return 0;

  final currentFuel = monthlyDistance / avgMileage;
  final improvedFuel = monthlyDistance / (avgMileage + 2);
  final savings = (currentFuel - improvedFuel) * fuelPrice;

  return savings;
}

// ─── Cost Per Km Trend ──────────────────────────────────────────

final costPerKmTrendProvider = Provider<List<TrendPoint>>((ref) {
  final trips = ref.watch(tripsProvider);
  if (trips.isEmpty) return [];

  // Group by week and calculate average cost/km
  final points = <TrendPoint>[];
  final sortedTrips = List.of(trips)..sort((a, b) => a.date.compareTo(b.date));

  for (int i = 0; i < sortedTrips.length && i < 20; i++) {
    final trip = sortedTrips[sortedTrips.length - 1 - i];
    points.insert(
      0,
      TrendPoint(
        date: trip.date,
        value: trip.costPerKm,
        label: '₹${trip.costPerKm.toStringAsFixed(1)}/km',
      ),
    );
  }

  return points;
});

// ─── Models ─────────────────────────────────────────────────────

class InsightSuggestion {
  final String icon;
  final String title;
  final String message;
  final SuggestionType type;

  InsightSuggestion({
    required this.icon,
    required this.title,
    required this.message,
    required this.type,
  });
}

enum SuggestionType { success, warning, tip, info }

class TrendPoint {
  final DateTime date;
  final double value;
  final String label;

  const TrendPoint({
    required this.date,
    required this.value,
    required this.label,
  });
}
