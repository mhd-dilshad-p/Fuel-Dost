import 'package:latlong2/latlong.dart';

/// Model representing a fuel station (pump) from Overpass API.
class FuelPumpModel {
  final String id;
  final String? name;
  final LatLng location;
  final double? distanceFromUser; // in meters

  const FuelPumpModel({
    required this.id,
    this.name,
    required this.location,
    this.distanceFromUser,
  });

  factory FuelPumpModel.fromOverpassJson(Map<String, dynamic> json, LatLng userLocation) {
    final lat = json['lat'] as double;
    final lon = json['lon'] as double;
    final tags = json['tags'] as Map<String, dynamic>?;
    final latLng = LatLng(lat, lon);
    
    // Distance calculation (simple Haversine)
    final Distance distance = const Distance();
    final double dist = distance.as(LengthUnit.Meter, userLocation, latLng);

    return FuelPumpModel(
      id: json['id']?.toString() ?? '',
      name: tags?['name'] ?? 'Fuel Station',
      location: latLng,
      distanceFromUser: dist,
    );
  }

  @override
  String toString() => 'FuelPumpModel(name: $name, distance: ${distanceFromUser?.toStringAsFixed(0)}m)';
}
