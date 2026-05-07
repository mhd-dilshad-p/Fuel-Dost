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
// To prevent excessive API calls, we'll debounce both origin & destination
final _debouncedDestinationProvider = StateProvider<LatLng?>((ref) => null);
final _debouncedOriginProvider = StateProvider<LatLng?>((ref) => null);
Timer? _debounceTimer;
Timer? _originDebounceTimer;

void setDebouncedDestination(WidgetRef ref, LatLng dest) {
  ref.read(destinationProvider.notifier).state = dest;
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 800), () {
    ref.read(_debouncedDestinationProvider.notifier).state = dest;
  });
}

void setDebouncedOrigin(WidgetRef ref, LatLng origin) {
  ref.read(originProvider.notifier).state = origin;
  _originDebounceTimer?.cancel();
  _originDebounceTimer = Timer(const Duration(milliseconds: 800), () {
    ref.read(_debouncedOriginProvider.notifier).state = origin;
  });
}

final routeProvider = FutureProvider<RouteModel?>((ref) async {
  final origin = ref.watch(_debouncedOriginProvider);
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
    // Populate both visual and debounced providers so route triggers immediately
    ref.read(originProvider.notifier).state = latLng;
    ref.read(_debouncedOriginProvider.notifier).state = latLng;
    ref.read(originAddressProvider.notifier).state = 'My Location';

    // Center map on current location
    ref.read(mapControllerProvider).move(latLng, 15.0);

    final city = await locationService.getCityFromCoordinates(
      position.latitude,
      position.longitude,
    );
    debugPrint('Detected city: $city');
  } catch (e) {
    debugPrint('Location init error: $e');
    const defaultLoc = LatLng(28.6139, 77.2090);
    ref.read(originProvider.notifier).state = defaultLoc;
    ref.read(_debouncedOriginProvider.notifier).state = defaultLoc;
    ref.read(originAddressProvider.notifier).state = 'My Location';
    ref.read(mapControllerProvider).move(defaultLoc, 15.0);
  }
});
