import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../expense_tracker/domain/providers/expense_provider.dart';
import '../../../../core/utils/formatters.dart'; // Assuming Formatters exists here

// ─── Insights Data Provider ─────────────────────────────────────

/// Smart suggestions based on trip data.
final suggestionsProvider = Provider<List<InsightSuggestion>>((ref) {
  final trips = ref.watch(tripsProvider);
  final repository = ref.read(tripRepositoryProvider);
  final suggestions = <InsightSuggestion>[];

  // 1. Initial State Check
  if (trips.isEmpty) {
    suggestions.add(InsightSuggestion(
      icon: '🚗',
      title: 'Start Tracking',
      message: 'Save your first trip to get personalized fuel insights!',
      type: SuggestionType.info,
    ));
    return suggestions;
  }

  // 2. Time-based Calculations
  final now = DateTime.now();
  final currentMonth = repository.getMonthlyTotal(now.year, now.month);
  
  // Clean calculation for previous month
  final prevMonthDate = DateTime(now.year, now.month - 1);
  final prevMonth = repository.getMonthlyTotal(prevMonthDate.year, prevMonthDate.month);

  // 3. Spending Comparison Logic
  if (prevMonth > 0) {
    if (currentMonth > prevMonth) {
      final increase = currentMonth - prevMonth;
      final pct = ((increase / prevMonth) * 100).toStringAsFixed(0);
      suggestions.add(InsightSuggestion(
        icon: '📈',
        title: 'Spending Increased',
        message: 'Fuel spending increased $pct% compared to last month (+${Formatters.currency(increase)})',
        type: SuggestionType.warning,
      ));
    } else if (currentMonth < prevMonth) {
      final savings = prevMonth - currentMonth;
      suggestions.add(InsightSuggestion(
        icon: '🎉',
        title: 'Great Savings!',
        message: 'You saved ${Formatters.currency(savings)} this month compared to last month!',
        type: SuggestionType.success,
      ));
    }
  }

  // 4. Mileage Improvement Logic
  if (trips.length >= 3) {
    // Average of up to last 10 trips
    final recentTrips = trips.take(10).toList();
    final avgMileage = recentTrips.fold(0.0, (sum, t) => sum + t.mileage) / recentTrips.length;
    
    final potentialSavings = _calculateMileageSavings(
      avgMileage: avgMileage,
      monthlyDistance: repository.getMonthlyDistance(now.year, now.month),
      fuelPrice: trips.first.fuelPrice,
    );

    if (potentialSavings > 50) {
      suggestions.add(InsightSuggestion(
        icon: '💡',
        title: 'Improve Mileage',
        message: 'Improving mileage by 2 km/l could save you ${Formatters.currency(potentialSavings)}/month',
        type: SuggestionType.tip,
      ));
    }
  }

  // 5. Fuel Analysis Logic
  final hasPetrol = trips.any((t) => t.fuelType == 'Petrol');
  final hasDiesel = trips.any((t) => t.fuelType == 'Diesel');
  
  if (hasPetrol && !hasDiesel) {
    suggestions.add(InsightSuggestion(
      icon: '⛽',
      title: 'Consider Diesel',
      message: 'Diesel vehicles often have better mileage and lower per-km costs for long distances.',
      type: SuggestionType.info,
    ));
  }

  // 6. Static Driving Tip
  suggestions.add(InsightSuggestion(
    icon: '🌿',
    title: 'Eco Driving Tip',
    message: 'Maintaining steady speeds between 45-65 km/h can improve fuel efficiency by up to 15%.',
    type: SuggestionType.tip,
  ));

  return suggestions;
});

// ─── Helper Logic ───────────────────────────────────────────────

double _calculateMileageSavings({
  required double avgMileage,
  required double monthlyDistance,
  required double fuelPrice,
}) {
  if (avgMileage <= 0 || monthlyDistance <= 0) return 0;

  final currentFuelUsed = monthlyDistance / avgMileage;
  final improvedFuelUsed = monthlyDistance / (avgMileage + 2);
  final savings = (currentFuelUsed - improvedFuelUsed) * fuelPrice;

  return savings;
}

// ─── Cost Per Km Trend Provider ─────────────────────────────────

final costPerKmTrendProvider = Provider<List<TrendPoint>>((ref) {
  final trips = ref.watch(tripsProvider);
  if (trips.isEmpty) return [];

  // Sort trips by date and take the 20 most recent
  final sortedTrips = List.of(trips)..sort((a, b) => a.date.compareTo(b.date));
  final recentTrips = sortedTrips.length > 20 
      ? sortedTrips.sublist(sortedTrips.length - 20) 
      : sortedTrips;

  return recentTrips.map((trip) => TrendPoint(
    date: trip.date,
    value: trip.costPerKm,
    label: '${Formatters.currency(trip.costPerKm)}/km',
  )).toList();
});

// ─── Data Models ────────────────────────────────────────────────

class InsightSuggestion {
  final String icon;
  final String title;
  final String message;
  final SuggestionType type;

  const InsightSuggestion({
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