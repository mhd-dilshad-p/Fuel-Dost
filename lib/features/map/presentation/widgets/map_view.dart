import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/providers/map_provider.dart';
import '../../domain/providers/search_provider.dart';
import '../../../fuel_calculator/domain/providers/fuel_calculator_provider.dart';

// ─── Which field is actively searching ──────────────────────────
enum _ActiveSearch { none, origin, destination }

class MapViewWidget extends ConsumerStatefulWidget {
  const MapViewWidget({super.key});

  @override
  ConsumerState<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends ConsumerState<MapViewWidget>
    with SingleTickerProviderStateMixin {
  static const _defaultPosition = LatLng(20.5937, 78.9629);

  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _originFocus = FocusNode();
  final _destFocus = FocusNode();

  _ActiveSearch _activeSearch = _ActiveSearch.none;
  late AnimationController _cardAnim;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut);

    _originFocus.addListener(() {
      if (_originFocus.hasFocus) {
        setState(() => _activeSearch = _ActiveSearch.origin);
        _cardAnim.forward();
      }
    });
    _destFocus.addListener(() {
      if (_destFocus.hasFocus) {
        setState(() => _activeSearch = _ActiveSearch.destination);
        _cardAnim.forward();
      }
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    _cardAnim.dispose();
    super.dispose();
  }

  void _dismissSearch() {
    _originFocus.unfocus();
    _destFocus.unfocus();
    _cardAnim.reverse();
    setState(() => _activeSearch = _ActiveSearch.none);
  }

  @override
  Widget build(BuildContext context) {
    final mapController = ref.watch(mapControllerProvider);
    final origin = ref.watch(originProvider);
    final destination = ref.watch(destinationProvider);
    final routeAsync = ref.watch(routeProvider);
    final isLoading = ref.watch(isLoadingRouteProvider);
    final nearbyPumpsAsync = ref.watch(nearbyFuelPumpsProvider);

    // ── Sync text controllers with address providers ──────────────
    final originAddr = ref.watch(originAddressProvider);
    final destAddr = ref.watch(destinationAddressProvider);
    if (!_originFocus.hasFocus && _originController.text != originAddr) {
      _originController.text = originAddr;
    }
    if (!_destFocus.hasFocus && _destController.text != destAddr) {
      _destController.text = destAddr;
    }

    // ── Build Markers ─────────────────────────────────────────────
    final markers = <Marker>[];
    if (origin != null) {
      markers.add(Marker(
        point: origin,
        width: 40,
        height: 40,
        child: const Icon(Icons.trip_origin_rounded,
            color: AppColors.success, size: 36),
      ));
    }
    if (destination != null) {
      markers.add(Marker(
        point: destination,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on_rounded,
            color: AppColors.error, size: 40),
      ));
    }

    // Add nearby pump markers
    nearbyPumpsAsync.whenData((pumps) {
      for (int i = 0; i < pumps.length; i++) {
        final pump = pumps[i];
        final isClosest = i == 0;
        markers.add(Marker(
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
        ));
      }
    });

    // ── Build Polylines ───────────────────────────────────────────
    final polylines = <Polyline>[];
    routeAsync.whenData((route) {
      if (route != null && route.polylinePoints.isNotEmpty) {
        polylines.add(Polyline(
          points: route.polylinePoints,
          color: AppColors.primary,
          strokeWidth: 5.0,
        ));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(distanceProvider.notifier).state = route.distanceKm;
        });
      }
    });

    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: origin ?? _defaultPosition,
            initialZoom: origin != null ? 14.0 : 5.0,
            onTap: (_, latLng) {
              if (_activeSearch != _ActiveSearch.none) {
                _dismissSearch();
              } else {
                _onMapTap(latLng);
              }
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

        // ── Route Planner Card ───────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Column(
            children: [
              // Card with From / To fields
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.13),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ── FROM field ───────────────────────────────
                    _LocationField(
                      controller: _originController,
                      focusNode: _originFocus,
                      hintText: 'From — search or use GPS',
                      icon: Icons.trip_origin_rounded,
                      iconColor: AppColors.success,
                      isFirst: true,
                      onChanged: (val) {
                        ref.read(originSearchQueryProvider.notifier).state =
                            val;
                      },
                      onClear: () {
                        _originController.clear();
                        ref.read(originSearchQueryProvider.notifier).state = '';
                      },
                      trailingWidget: _GpsButton(onTap: _goToCurrentLocation),
                    ),

                    // Divider with swap button
                    _SwapDivider(onSwap: _swapLocations),

                    // ── TO field ────────────────────────────────
                    _LocationField(
                      controller: _destController,
                      focusNode: _destFocus,
                      hintText: 'To — search destination',
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.error,
                      isFirst: false,
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                      },
                      onClear: () {
                        _destController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(destinationProvider.notifier).state = null;
                        ref.read(destinationAddressProvider.notifier).state =
                            '';
                        ref.read(distanceProvider.notifier).state = 0;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ── Search Results Dropdown ──────────────────────
              if (_activeSearch == _ActiveSearch.origin)
                _SearchDropdown(
                  resultsAsync: ref.watch(originSearchResultsProvider),
                  onSelect: (res) => _onOriginSelected(res),
                  fade: _cardFade,
                ),
              if (_activeSearch == _ActiveSearch.destination)
                _SearchDropdown(
                  resultsAsync: ref.watch(searchResultsProvider),
                  onSelect: (res) => _onDestinationSelected(res),
                  fade: _cardFade,
                ),
            ],
          ),
        ),

        // ── Route calculating indicator ──────────────────────────
        if (isLoading)
          Positioned(
            top: MediaQuery.of(context).padding.top + 130,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calculating route...',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── FAB buttons (right side) ─────────────────────────────
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.45 + 16,
          right: 16,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.my_location_rounded,
                onTap: _goToCurrentLocation,
              ),
              const SizedBox(height: 8),
              if (origin != null && destination != null)
                _MapButton(
                  icon: Icons.clear_rounded,
                  onTap: _clearRoute,
                  color: AppColors.error,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Handlers ──────────────────────────────────────────────────

  void _onOriginSelected(SearchResult res) {
    HapticFeedback.selectionClick();
    _originController.text = res.name;
    ref.read(originSearchQueryProvider.notifier).state = '';
    _dismissSearch();

    setDebouncedOrigin(ref, res.location);
    ref.read(originAddressProvider.notifier).state = res.name;
    ref.read(mapControllerProvider).move(res.location, 14);
  }

  void _onDestinationSelected(SearchResult res) {
    HapticFeedback.selectionClick();
    _destController.text = res.name;
    ref.read(searchQueryProvider.notifier).state = '';
    _dismissSearch();

    setDebouncedDestination(ref, res.location);
    ref.read(destinationAddressProvider.notifier).state = res.name;
    ref.read(mapControllerProvider).move(res.location, 14);
  }

  void _onMapTap(LatLng latLng) {
    setDebouncedDestination(ref, latLng);
    final locationService = ref.read(locationServiceProvider);
    locationService
        .getAddressFromCoordinates(latLng.latitude, latLng.longitude)
        .then((addr) {
      ref.read(destinationAddressProvider.notifier).state = addr;
    }).catchError((_) {});
  }

  void _goToCurrentLocation() async {
    HapticFeedback.lightImpact();
    final locationService = ref.read(locationServiceProvider);
    try {
      final position = await locationService.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setDebouncedOrigin(ref, latLng);
      ref.read(originAddressProvider.notifier).state = 'My Location';
      _originController.text = 'My Location';
      ref.read(mapControllerProvider).move(latLng, 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  void _swapLocations() {
    HapticFeedback.mediumImpact();
    final curOrigin = ref.read(originProvider);
    final curDest = ref.read(destinationProvider);
    final curOriginAddr = ref.read(originAddressProvider);
    final curDestAddr = ref.read(destinationAddressProvider);

    if (curOrigin == null && curDest == null) return;

    // Swap providers
    if (curDest != null) {
      setDebouncedOrigin(ref, curDest);
      ref.read(originAddressProvider.notifier).state = curDestAddr;
    }
    if (curOrigin != null) {
      setDebouncedDestination(ref, curOrigin);
      ref.read(destinationAddressProvider.notifier).state = curOriginAddr;
    }
  }

  void _clearRoute() {
    HapticFeedback.lightImpact();
    ref.read(destinationProvider.notifier).state = null;
    ref.read(destinationAddressProvider.notifier).state = '';
    ref.read(distanceProvider.notifier).state = 0;
    _destController.clear();
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
                  child: const Icon(Icons.local_gas_station_rounded,
                      color: AppColors.primary),
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
                        style:
                            TextStyle(fontSize: 14, color: AppColors.textTertiary),
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
                    const Text('Distance',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

// ─── Location Field ──────────────────────────────────────────────

class _LocationField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final Color iconColor;
  final bool isFirst;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final Widget? trailingWidget;

  const _LocationField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    required this.iconColor,
    required this.isFirst,
    required this.onChanged,
    required this.onClear,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: isFirst
          ? const BorderRadius.vertical(top: Radius.circular(20))
          : BorderRadius.zero,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: Colors.grey),
                  onPressed: onClear,
                  splashRadius: 18,
                ),
              if (trailingWidget != null) trailingWidget!,
            ],
          ),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }
}

// ─── GPS Button ──────────────────────────────────────────────────

class _GpsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GpsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 18),
      ),
    );
  }
}

// ─── Swap Divider ────────────────────────────────────────────────

class _SwapDivider extends StatelessWidget {
  final VoidCallback onSwap;
  const _SwapDivider({required this.onSwap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
        GestureDetector(
          onTap: onSwap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.swap_vert_rounded,
                size: 18, color: AppColors.primary),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

// ─── Search Results Dropdown ─────────────────────────────────────

class _SearchDropdown extends StatelessWidget {
  final AsyncValue<List<SearchResult>> resultsAsync;
  final ValueChanged<SearchResult> onSelect;
  final Animation<double> fade;

  const _SearchDropdown({
    required this.resultsAsync,
    required this.onSelect,
    required this.fade,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxHeight: 240),
        child: resultsAsync.when(
          data: (results) {
            if (results.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.search_off_rounded,
                        color: Colors.grey.shade400, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'No results found',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: results.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final res = results[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on_outlined,
                      color: AppColors.primary, size: 20),
                  title: Text(
                    res.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  onTap: () => onSelect(res),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red)),
          ),
        ),
      ),
    );
  }
}

// ─── Small Action Button ─────────────────────────────────────────

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _SmallActionButton(
      {required this.icon, required this.onTap, required this.color});

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

// ─── Map FAB Button ───────────────────────────────────────────────

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
