import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SearchResult {
  final String name;
  final LatLng location;

  SearchResult({required this.name, required this.location});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      name: json['display_name'] ?? 'Unknown',
      location: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
    );
  }
}

// ── Destination search ──────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || query.length < 3) return [];

  final url =
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=in';

  try {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'FuelDost-App',
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => SearchResult.fromJson(item)).toList();
    }
  } catch (e) {
    print('Search error (dest): $e');
  }
  return [];
});

// ── Origin search ────────────────────────────────────────────────
final originSearchQueryProvider = StateProvider<String>((ref) => '');

final originSearchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(originSearchQueryProvider);
  if (query.isEmpty || query.length < 3) return [];

  final url =
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=in';

  try {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'FuelDost-App',
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => SearchResult.fromJson(item)).toList();
    }
  } catch (e) {
    print('Search error (origin): $e');
  }
  return [];
});
