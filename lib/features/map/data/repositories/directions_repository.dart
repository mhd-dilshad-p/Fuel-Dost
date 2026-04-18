import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../../../../core/config.dart';

class DirectionsRepository {
  static const String _baseUrl = 'https://api.openrouteservice.org/v2/directions/driving-car';

  final http.Client _client;

  DirectionsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<RouteModel?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    const apiKey = AppConfig.orsApiKey;
    if (apiKey.isEmpty) {
      throw Exception('OpenRouteService API Key is missing. Provide it via --dart-define=ORS_API_KEY=your_key or check AppConfig.');
    }

    try {
      final originStr = '${origin.longitude},${origin.latitude}';
      final destStr = '${destination.longitude},${destination.latitude}';

      final url = '$_baseUrl?api_key=$apiKey&start=$originStr&end=$destStr';

      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final properties = data['features'][0]['properties'];
          final segments = properties['segments'][0];
          
          final geometry = data['features'][0]['geometry']['coordinates'] as List;
          final polylinePoints = geometry.map((coord) => LatLng(coord[1], coord[0])).toList();

          final distanceMeters = segments['distance'] as num;
          final durationSeconds = segments['duration'] as num;

          return RouteModel(
            origin: origin,
            destination: destination,
            distanceKm: distanceMeters / 1000.0,
            durationSeconds: durationSeconds.toInt(),
            distanceText: '${(distanceMeters / 1000.0).toStringAsFixed(1)} km',
            durationText: '${(durationSeconds / 60).round()} min',
            polylinePoints: polylinePoints,
            originAddress: 'Origin', // Omitted reverse geocoding for speed, can wrap if needed
            destinationAddress: 'Destination',
          );
        }
      }
      return null;
    } catch (e) {
      print('ORS API Error: $e');
      throw Exception('Failed to fetch route');
    }
  }
}
