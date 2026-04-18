import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/providers/map_provider.dart';
import '../../domain/providers/search_provider.dart';
import '../../../fuel_calculator/domain/providers/fuel_calculator_provider.dart';

class MapViewWidget extends ConsumerStatefulWidget {
  const MapViewWidget({super.key});

  @override
  ConsumerState<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends ConsumerState<MapViewWidget> {
  static const _defaultPosition = LatLng(20.5937, 78.9629); // India center
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapController = ref.watch(mapControllerProvider);
    final origin = ref.watch(originProvider);
    final destination = ref.watch(destinationProvider);
    final routeAsync = ref.watch(routeProvider);
    final isLoading = ref.watch(isLoadingRouteProvider);
    final nearbyPumpsAsync = ref.watch(nearbyFuelPumpsProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    // Build Markers
    final markers = <Marker>[];
    if (origin != null) {
      markers.add(
        Marker(
          point: origin,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: AppColors.success, size: 40),
        ),
      );
    }
    if (destination != null) {
      markers.add(
        Marker(
          point: destination,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: AppColors.error, size: 40),
        ),
      );
    }

    // Add nearby pump markers
    nearbyPumpsAsync.whenData((pumps) {
      for (int i = 0; i < pumps.length; i++) {
        final pump = pumps[i];
        final isClosest = i == 0;
        markers.add(
          Marker(
            point: pump.location,
            width: isClosest ? 44 : 36,
            height: isClosest ? 44 : 36,
            child: GestureDetector(
              onTap: () => _showPumpDetails(pump),
              child: Container(
                decoration: BoxDecoration(
                  color: isClosest ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isClosest ? Colors.white : AppColors.primary, 
                    width: isClosest ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: isClosest ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  color: isClosest ? Colors.white : AppColors.primary,
                  size: isClosest ? 24 : 20,
                ),
              ),
            ),
          ),
        );
      }
    });

    // Build Polylines
    final polylines = <Polyline>[];
    routeAsync.whenData((route) {
      if (route != null && route.polylinePoints.isNotEmpty) {
        polylines.add(Polyline(
          points: route.polylinePoints,
          color: AppColors.primary,
          strokeWidth: 5.0,
        ));

        // Wait to draw and then try updating distance
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(distanceProvider.notifier).state = route.distanceKm;
        });
      }
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: origin ?? _defaultPosition,
            initialZoom: origin != null ? 14.0 : 5.0,
            onTap: (_, latLng) {
               _onMapTap(latLng);
               if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fueldost.app',
            ),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),

        // SEARCH BAR
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                    setState(() => _isSearching = val.isNotEmpty);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search destination...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() => _isSearching = false);
                            _searchFocusNode.unfocus();
                          },
                        )
                      : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              // Search Results List
              if (_isSearching)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: searchResultsAsync.when(
                    data: (results) {
                      if (results.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No results found'),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: results.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final res = results[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(
                              res.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              _onSearchResultTap(res);
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: $e'),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Loading indicator
        if (isLoading)
          Positioned(
            top: MediaQuery.of(context).padding.top + 75,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Calculating route...'),
                  ],
                ),
              ),
            ),
          ),

        // My Location Button
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.45 + 16,
          right: 16,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.my_location_rounded,
                onTap: () => _goToCurrentLocation(),
              ),
              const SizedBox(height: 8),
              if (origin != null && destination != null)
                _MapButton(
                  icon: Icons.clear_rounded,
                  onTap: () => _clearRoute(),
                  color: AppColors.error,
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSearchResultTap(SearchResult res) {
    _searchController.text = res.name;
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() => _isSearching = false);
    _searchFocusNode.unfocus();

    setDebouncedDestination(ref, res.location);
    ref.read(destinationAddressProvider.notifier).state = res.name;
    ref.read(mapControllerProvider).move(res.location, 14);
  }

  void _onMapTap(LatLng latLng) {
    setDebouncedDestination(ref, latLng);

    // Update destination address optionally if needed
    final locationService = ref.read(locationServiceProvider);
    locationService.getAddressFromCoordinates(latLng.latitude, latLng.longitude)
      .then((addr) {
        ref.read(destinationAddressProvider.notifier).state = addr;
      }).catchError((_) {});
  }

  void _goToCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);
    try {
      final position = await locationService.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      ref.read(originProvider.notifier).state = latLng;
      ref.read(mapControllerProvider).move(latLng, 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  void _clearRoute() {
    ref.read(destinationProvider.notifier).state = null;
    ref.read(destinationAddressProvider.notifier).state = '';
    ref.read(distanceProvider.notifier).state = 0;
  }

  void _showPumpDetails(dynamic pump) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_gas_station_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pump.name ?? 'Fuel Station',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Nearby Station',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                    Text(
                      '${(pump.distanceFromUser / 1000).toStringAsFixed(1)} KM',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _SmallActionButton(
                      icon: Icons.navigation_rounded,
                      onTap: () => _launchNavigationTo(pump.location),
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setDebouncedDestination(ref, pump.location);
                      },
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _launchNavigationTo(LatLng destination) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _SmallActionButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MapButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: color ?? AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
