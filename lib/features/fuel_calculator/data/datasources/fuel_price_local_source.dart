import 'package:hive/hive.dart';
import '../../../../database/hive_service.dart';
import '../models/fuel_price_model.dart';

/// Local data source for caching fuel prices in Hive.
class FuelPriceLocalSource {
  static const _cacheKey = 'cached_fuel_price';
  static const _cacheExpiry = Duration(hours: 24);

  Box get _box => HiveService.getFuelPricesBox();

  /// Get cached fuel price.
  /// Returns null if cache is expired or empty.
  FuelPriceModel? getCachedPrice() {
    try {
      final cached = _box.get(_cacheKey);
      if (cached == null) return null;

      final cacheMap = Map<dynamic, dynamic>.from(cached as Map);
      final model = FuelPriceModel.fromCache(cacheMap);

      // Check if cache is expired
      if (DateTime.now().difference(model.lastUpdated) > _cacheExpiry) {
        return null; // Expired
      }

      return model;
    } catch (_) {
      return null;
    }
  }

  /// Get cached price even if expired (for offline usage).
  FuelPriceModel? getCachedPriceForOffline() {
    try {
      final cached = _box.get(_cacheKey);
      if (cached == null) return null;
      final cacheMap = Map<dynamic, dynamic>.from(cached as Map);
      return FuelPriceModel.fromCache(cacheMap);
    } catch (_) {
      return null;
    }
  }

  /// Cache fuel price.
  Future<void> cachePrice(FuelPriceModel price) async {
    await _box.put(_cacheKey, price.toCache());
  }

  /// Clear cache.
  Future<void> clearCache() async {
    await _box.delete(_cacheKey);
  }

  /// Check if cache is fresh (less than 24 hours old).
  bool isCacheFresh() {
    return getCachedPrice() != null;
  }
}
