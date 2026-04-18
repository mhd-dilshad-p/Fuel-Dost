import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/expense_tracker/data/models/trip_model.dart';

/// Manages Hive database initialization and box access.
class HiveService {
  static const String tripsBox = 'trips';
  static const String fuelPricesBox = 'fuel_prices';
  static const String settingsBox = 'settings';

  /// Initialize Hive and register all type adapters.
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TripModelAdapter());

    // Open boxes
    await Hive.openBox<TripModel>(tripsBox);
    await Hive.openBox(fuelPricesBox);
    await Hive.openBox(settingsBox);
  }

  /// Get the trips box.
  static Box<TripModel> getTripsBox() {
    return Hive.box<TripModel>(tripsBox);
  }

  /// Get the fuel prices box.
  static Box getFuelPricesBox() {
    return Hive.box(fuelPricesBox);
  }

  /// Get the settings box.
  static Box getSettingsBox() {
    return Hive.box(settingsBox);
  }

  /// Close all boxes.
  static Future<void> close() async {
    await Hive.close();
  }
}

/// Provider for the trips Hive box.
final tripsBoxProvider = Provider<Box<TripModel>>((ref) {
  return HiveService.getTripsBox();
});

/// Provider for the fuel prices Hive box.
final fuelPricesBoxProvider = Provider<Box>((ref) {
  return HiveService.getFuelPricesBox();
});

/// Provider for the settings Hive box.
final settingsBoxProvider = Provider<Box>((ref) {
  return HiveService.getSettingsBox();
});
