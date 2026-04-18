import '../datasources/fuel_price_local_source.dart';
import '../datasources/fuel_price_remote_source.dart';
import '../models/fuel_price_model.dart';

/// Repository that manages fuel price data with cache-first strategy.
class FuelPriceRepository {
  final FuelPriceRemoteSource _remoteSource;
  final FuelPriceLocalSource _localSource;

  FuelPriceRepository({
    FuelPriceRemoteSource? remoteSource,
    FuelPriceLocalSource? localSource,
  })  : _remoteSource = remoteSource ?? FuelPriceRemoteSource(),
        _localSource = localSource ?? FuelPriceLocalSource();

  /// Get fuel price for a city.
  /// Strategy: cache (if fresh) → remote → cache (if stale) → defaults.
  Future<FuelPriceModel> getFuelPrice(String city) async {
    // 1. Check fresh cache first
    final cached = _localSource.getCachedPrice();
    if (cached != null && cached.city.toLowerCase() == city.toLowerCase()) {
      return cached;
    }

    // 2. Try fetching from remote
    try {
      final remote = await _remoteSource.fetchFuelPrice(city);
      if (remote.petrolPrice > 0) {
        await _localSource.cachePrice(remote);
        return remote;
      }
    } catch (_) {
      // Network failure — fall through
    }

    // 3. Return stale cache if available (offline mode)
    final staleCached = _localSource.getCachedPriceForOffline();
    if (staleCached != null) {
      return staleCached;
    }

    // 4. Return default prices
    return FuelPriceModel.defaultPrices;
  }

  /// Force refresh from remote API.
  Future<FuelPriceModel> refreshFuelPrice(String city) async {
    try {
      final remote = await _remoteSource.fetchFuelPrice(city);
      if (remote.petrolPrice > 0) {
        await _localSource.cachePrice(remote);
        return remote;
      }
    } catch (_) {
      // Ignore and return cached
    }

    final cached = _localSource.getCachedPriceForOffline();
    return cached ?? FuelPriceModel.defaultPrices;
  }

  void dispose() {
    _remoteSource.dispose();
  }
}
