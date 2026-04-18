import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/fuel_pump_model.dart';

/// Repository for fetching nearby fuel pumps using Overpass API.
class OverpassRepository {
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';
  
  final http.Client _client;

  OverpassRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch nearby fuel pumps within a radius (default 3000m).
  Future<List<FuelPumpModel>> getNearbyFuelPumps({
    required LatLng location,
    double radius = 3000,
    int limit = 10,
  }) async {
    final query = '''
    [out:json][timeout:25];
    node["amenity"="fuel"](around:$radius,${location.latitude},${location.longitude});
    out body $limit;
    ''';

    try {
      final response = await _client.post(
        Uri.parse(_baseUrl),
        body: query,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>? ?? [];
        
        final pumps = elements
            .map((e) => FuelPumpModel.fromOverpassJson(e as Map<String, dynamic>, location))
            .toList();
            
        // Sort by distance from user
        pumps.sort((a, b) => (a.distanceFromUser ?? 0).compareTo(b.distanceFromUser ?? 0));
        
        return pumps;
      }
    } catch (e) {
      print('Overpass API Error: $e');
    }
    return [];
  }
}
