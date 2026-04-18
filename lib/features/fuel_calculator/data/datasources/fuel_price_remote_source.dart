import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fuel_price_model.dart';
import '../../../../core/config.dart';

/// Remote data source for fetching fuel prices from API.
class FuelPriceRemoteSource {
  static const _baseUrl = 'https://fuel.indianapi.in';
  final String? _apiKey;
  final http.Client _client;

  FuelPriceRemoteSource({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey,
        _client = client ?? http.Client();

  /// Fetch live fuel price for a city.
  /// Falls back to scraping approach if API fails.
  Future<FuelPriceModel> fetchFuelPrice(String city) async {
    // Try IndianAPI first
    try {
      return await _fetchFromIndianApi(city);
    } catch (_) {
      // Fallback: try alternative free API
      try {
        return await _fetchFromAlternativeApi(city);
      } catch (_) {
        // Return default prices if all APIs fail
        return FuelPriceModel.defaultPrices;
      }
    }
  }

  Future<FuelPriceModel> _fetchFromIndianApi(String city) async {
    const apiKey = AppConfig.indianApiKey;
    if (apiKey.isEmpty) throw Exception('IndianAPI Key is missing');

    // Fetch Petrol prices
    final petrolPrice = await _fetchPriceForType(apiKey, city, 'petrol');
    // Fetch Diesel prices
    final dieselPrice = await _fetchPriceForType(apiKey, city, 'diesel');

    return FuelPriceModel(
      city: city,
      state: '', // The new API doesn't seem to return state in the list directly as per schema
      petrolPrice: petrolPrice,
      dieselPrice: dieselPrice,
      lastUpdated: DateTime.now(),
    );
  }

  Future<double> _fetchPriceForType(String apiKey, String city, String fuelType) async {
    final url = '$_baseUrl/live_fuel_price?fuel_type=$fuelType&location_type=city';
    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        // Filter locally: match using case-insensitive contains or exact match
        // and handle common variations (e.g., Kochi vs Ernakulam)
        final normalizedCity = city.toLowerCase();
        
        final cityData = data.firstWhere(
          (item) {
            final apiCity = (item['city'] as String).toLowerCase();
            return apiCity == normalizedCity || 
                   apiCity.contains(normalizedCity) || 
                   normalizedCity.contains(apiCity) ||
                   _checkVariations(normalizedCity, apiCity);
          },
          orElse: () => null,
        );

        if (cityData != null) {
          final priceStr = cityData['price'] as String;
          // Price is usually "₹103.44" or similar
          return double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        }
      }
    }
    return 0;
  }

  bool _checkVariations(String city, String apiCity) {
    final variations = {
      'kochi': ['ernakulam', 'cochin'],
      'bengaluru': ['bangalore'],
      'mumbai': ['bombay'],
      'chennai': ['madras'],
      'kolkata': ['calcutta'],
      'gurugram': ['gurgaon'],
      'prayagraj': ['allahabad'],
      'varanasi': ['banaras', 'kashi'],
    };

    if (variations.containsKey(city)) {
      return variations[city]!.any((v) => apiCity.contains(v));
    }
    return false;
  }

  Future<FuelPriceModel> _fetchFromAlternativeApi(String city) async {
    // Try a public fuel price API
    final url =
        'https://daily-fuel-prices-india.p.rapidapi.com/api/fuel-prices?city=${Uri.encodeComponent(city)}';

    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) {
        return FuelPriceModel.fromJson({
          'city': city,
          'state': data['state'] ?? '',
          'petrol': data['petrol'],
          'diesel': data['diesel'],
        });
      }
    }
    throw Exception('Failed to fetch from alternative API');
  }

  void dispose() {
    _client.close();
  }
}
