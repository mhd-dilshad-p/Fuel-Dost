import 'package:latlong2/latlong.dart';

/// Model representing a route between two points.
class RouteModel {
  final double distanceKm;
  final String distanceText;
  final String durationText;
  final int durationSeconds;
  final List<LatLng> polylinePoints;
  final LatLng origin;
  final LatLng destination;
  final String? originAddress;
  final String? destinationAddress;

  const RouteModel({
    required this.distanceKm,
    required this.distanceText,
    required this.durationText,
    required this.durationSeconds,
    required this.polylinePoints,
    required this.origin,
    required this.destination,
    this.originAddress,
    this.destinationAddress,
  });

  static const empty = RouteModel(
    distanceKm: 0,
    distanceText: '',
    durationText: '',
    durationSeconds: 0,
    polylinePoints: [],
    origin: LatLng(0, 0),
    destination: LatLng(0, 0),
  );

  bool get isEmpty => distanceKm <= 0;
  bool get isNotEmpty => !isEmpty;

  RouteModel copyWith({
    double? distanceKm,
    String? distanceText,
    String? durationText,
    int? durationSeconds,
    List<LatLng>? polylinePoints,
    LatLng? origin,
    LatLng? destination,
    String? originAddress,
    String? destinationAddress,
  }) {
    return RouteModel(
      distanceKm: distanceKm ?? this.distanceKm,
      distanceText: distanceText ?? this.distanceText,
      durationText: durationText ?? this.durationText,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      originAddress: originAddress ?? this.originAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
    );
  }
}
