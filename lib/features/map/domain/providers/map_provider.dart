import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import '../../../../core/services/location_service.dart';
import '../../data/models/route_model.dart';
import '../../data/repositories/directions_repository.dart';
import '../../data/repositories/overpass_repository.dart';
import '../../data/models/fuel_pump_model.dart';

// ─── Repositories ───────────────────────────────────────────────

final directionsRepositoryProvider = Provider<DirectionsRepository>((ref) {
  return DirectionsRepository();
});

final overpassRepositoryProvider = Provider<OverpassRepository>((ref) {
  return OverpassRepository();
});

// ─── Map Controller ─────────────────────────────────────────────
final mapControllerProvider = Provider<MapController>((ref) => MapController());

// ─── Origin & Destination ───────────────────────────────────────

final originProvider = StateProvider<LatLng?>((ref) => null);
final destinationProvider = StateProvider<LatLng?>((ref) => null);
final originAddressProvider = StateProvider<String>((ref) => 'Current Location');
final destinationAddressProvider = StateProvider<String>((ref) => '');

// ─── Route Provider (Debounced) ─────────────────────────────────
// To prevent excessive API calls, we'll wrap the destination in an 800ms debounce
final _debouncedDestinationProvider = StateProvider<LatLng?>((ref) => null);
Timer? _debounceTimer;

void setDebouncedDestination(WidgetRef ref, LatLng dest) {
  ref.read(destinationProvider.notifier).state = dest;
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 800), () {
    ref.read(_debouncedDestinationProvider.notifier).state = dest;
  });
}

final routeProvider = FutureProvider<RouteModel?>((ref) async {
  final origin = ref.watch(originProvider);
  final destination = ref.watch(_debouncedDestinationProvider);

  if (origin == null || destination == null) return null;

  final repo = ref.read(directionsRepositoryProvider);
  try {
    return await repo.getRoute(
      origin: origin,
      destination: destination,
    );
  } catch (e) {
    debugPrint('Route error: $e');
    return null;
  }
});

// ─── Nearby Fuel Pumps ──────────────────────────────────────────
final nearbyFuelPumpsProvider = FutureProvider<List<FuelPumpModel>>((ref) async {
  final origin = ref.watch(originProvider);
  if (origin == null) return [];

  final repo = ref.read(overpassRepositoryProvider);
  final pumps = await repo.getNearbyFuelPumps(location: origin);
  
  // Sort by distance
  pumps.sort((a, b) => (a.distanceFromUser ?? 0).compareTo(b.distanceFromUser ?? 0));
  return pumps;
});

// ─── Loading State ──────────────────────────────────────────────
final isLoadingRouteProvider = Provider<bool>((ref) {
  return ref.watch(routeProvider).isLoading;
});

// ─── Initialize Location ────────────────────────────────────────
final initLocationProvider = FutureProvider<void>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  try {
    final position = await locationService.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    ref.read(originProvider.notifier).state = latLng;

    // Center map on curr location
    ref.read(mapControllerProvider).move(latLng, 15.0);

    final city = await locationService.getCityFromCoordinates(
      position.latitude,
      position.longitude,
    );
    debugPrint('Detected city: $city');
  } catch (e) {
    debugPrint('Location init error: $e');
    final defaultLoc = const LatLng(28.6139, 77.2090);
    ref.read(originProvider.notifier).state = defaultLoc;
    ref.read(mapControllerProvider).move(defaultLoc, 15.0);
  }
});
