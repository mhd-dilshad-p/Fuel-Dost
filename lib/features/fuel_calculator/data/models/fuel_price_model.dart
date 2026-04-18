/// Fuel price model for API response and local caching.
class FuelPriceModel {
  final String city;
  final String state;
  final double petrolPrice;
  final double dieselPrice;
  final DateTime lastUpdated;

  const FuelPriceModel({
    required this.city,
    required this.state,
    required this.petrolPrice,
    required this.dieselPrice,
    required this.lastUpdated,
  });

  /// Create from API JSON response.
  factory FuelPriceModel.fromJson(Map<String, dynamic> json) {
    return FuelPriceModel(
      city: json['city'] as String? ?? 'Unknown',
      state: json['state'] as String? ?? 'Unknown',
      petrolPrice: _parseDouble(json['petrol']),
      dieselPrice: _parseDouble(json['diesel']),
      lastUpdated: DateTime.now(),
    );
  }

  /// Create from Hive cache.
  factory FuelPriceModel.fromCache(Map<dynamic, dynamic> cache) {
    return FuelPriceModel(
      city: cache['city'] as String? ?? 'Unknown',
      state: cache['state'] as String? ?? 'Unknown',
      petrolPrice: (cache['petrolPrice'] as num?)?.toDouble() ?? 0,
      dieselPrice: (cache['dieselPrice'] as num?)?.toDouble() ?? 0,
      lastUpdated: cache['lastUpdated'] != null
          ? DateTime.parse(cache['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to cache map for Hive.
  Map<String, dynamic> toCache() {
    return {
      'city': city,
      'state': state,
      'petrolPrice': petrolPrice,
      'dieselPrice': dieselPrice,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Default prices for India (national average).
  static FuelPriceModel get defaultPrices => FuelPriceModel(
        city: 'India Average',
        state: 'India',
        petrolPrice: 103.44,
        dieselPrice: 90.56,
        lastUpdated: DateTime.now(),
      );

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() =>
      'FuelPriceModel(city: $city, petrol: ₹$petrolPrice, diesel: ₹$dieselPrice)';
}
