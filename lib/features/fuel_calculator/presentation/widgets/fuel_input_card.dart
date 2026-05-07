import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/providers/fuel_calculator_provider.dart';

class FuelInputCard extends ConsumerStatefulWidget {
  const FuelInputCard({super.key});

  @override
  ConsumerState<FuelInputCard> createState() => _FuelInputCardState();
}

class _FuelInputCardState extends ConsumerState<FuelInputCard> {
  late TextEditingController _distanceController;
  late TextEditingController _mileageController;
  late TextEditingController _priceController;
  final FocusNode _distanceFocus = FocusNode();
  bool _distanceUserEditing = false;

  @override
  void initState() {
    super.initState();
    _distanceController = TextEditingController();
    _mileageController = TextEditingController(text: '15');
    _priceController = TextEditingController();

    _distanceFocus.addListener(() {
      _distanceUserEditing = _distanceFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _distanceFocus.dispose();
    _distanceController.dispose();
    _mileageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onVehicleChanged(VehicleType type) {
    ref.read(vehicleTypeProvider.notifier).state = type;
    final defaultMileage = type == VehicleType.bike ? 40.0 : 15.0;
    _mileageController.text = defaultMileage.toStringAsFixed(0);
    ref.read(mileageProvider.notifier).state = defaultMileage;
    HapticFeedback.mediumImpact();
  }

  void _updateMileage(double value) {
    _mileageController.text = value.toStringAsFixed(0);
    ref.read(mileageProvider.notifier).state = value;
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    // Only sync distance from map when the user is NOT manually typing
    ref.listen<double>(distanceProvider, (prev, next) {
      if (!_distanceUserEditing && next > 0) {
        final text = next.toStringAsFixed(1);
        if (_distanceController.text != text) {
          _distanceController.text = text;
        }
      }
    });

    final distanceMethod = ref.watch(distanceMethodProvider);
    final vehicleType = ref.watch(vehicleTypeProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VEHICLE SELECTION
            Row(
              children: [
                Text(
                  'Vehicle Type',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _VehicleToggle(
                  selected: vehicleType,
                  onChanged: _onVehicleChanged,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // DISTANCE METHOD TOGGLE
            Row(
              children: [
                Text(
                  'Distance',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _DistanceMethodToggle(
                  selected: distanceMethod,
                  onChanged: (val) {
                    ref.read(distanceMethodProvider.notifier).state = val;
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Distance Input — focus tracked to avoid overwriting while typing
            TextField(
              controller: _distanceController,
              focusNode: _distanceFocus,
              enabled: distanceMethod == DistanceMethod.manual,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final parsed = double.tryParse(value) ?? 0;
                ref.read(distanceProvider.notifier).state = parsed;
              },
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: distanceMethod == DistanceMethod.manual
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              decoration: InputDecoration(
                hintText: distanceMethod == DistanceMethod.auto
                    ? 'Select route on map'
                    : 'Enter distance manually',
                prefixIcon: Icon(
                  Icons.straighten_rounded,
                  color: distanceMethod == DistanceMethod.manual
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
                suffixText: 'km',
                filled: distanceMethod != DistanceMethod.manual,
                fillColor: AppColors.surfaceVariant.withOpacity(0.5),
              ),
            ).animate(target: distanceMethod == DistanceMethod.manual ? 1 : 0)
             .shimmer(duration: 800.ms, color: AppColors.primary.withOpacity(0.1)),

            const SizedBox(height: 12),

            // Mileage Input
            _InputField(
              controller: _mileageController,
              label: 'Mileage',
              suffix: 'km/l',
              icon: Icons.speed_rounded,
              hint: 'Vehicle mileage',
              onChanged: (value) {
                final parsed = double.tryParse(value) ?? 0;
                ref.read(mileageProvider.notifier).state = parsed;
              },
            ),

            const SizedBox(height: 10),

            // Mileage Presets — redesigned as larger labelled tiles
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    if (vehicleType == VehicleType.bike) ...[
                      _PresetChip(label: '35 km/l', onTap: () => _updateMileage(35)),
                      const SizedBox(width: 10),
                      _PresetChip(label: '40 km/l', onTap: () => _updateMileage(40)),
                      const SizedBox(width: 10),
                      _PresetChip(label: '45 km/l', onTap: () => _updateMileage(45)),
                    ] else ...[
                      _PresetChip(label: '12 km/l', onTap: () => _updateMileage(12)),
                      const SizedBox(width: 10),
                      _PresetChip(label: '15 km/l', onTap: () => _updateMileage(15)),
                      const SizedBox(width: 10),
                      _PresetChip(label: '18 km/l', onTap: () => _updateMileage(18)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FUEL TYPE SELECTION
            Row(
              children: [
                Text(
                  'Fuel Type',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _FuelTypeToggle(
                  selected: ref.watch(fuelTypeProvider),
                  onChanged: (val) {
                    ref.read(fuelTypeProvider.notifier).state = val;
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // FUEL PRICE — always manual, different prices per region
            Row(
              children: [
                const SizedBox(width: 4),
                Icon(Icons.local_gas_station_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Fuel Price',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(your region)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Price Input — always enabled, always manual
            _InputField(
              controller: _priceController,
              label: '',
              suffix: '₹/L',
              icon: Icons.currency_rupee_rounded,
              hint: 'Enter your local fuel price',
              enabled: true,
              onChanged: (value) {
                final parsed = double.tryParse(value);
                ref.read(fuelPriceOverrideProvider.notifier).state = parsed;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1.2),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const _InputField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        hintText: hint,
        prefixIcon: Icon(icon, color: enabled ? AppColors.primary : AppColors.textSecondary, size: 22),
        suffixText: suffix,
        filled: !enabled,
        fillColor: enabled ? Colors.transparent : AppColors.surfaceVariant.withOpacity(0.5),
      ),
    );
  }
}
class _VehicleToggle extends StatelessWidget {
  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;

  const _VehicleToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: VehicleType.values.map((type) {
          final isSelected = selected == type;
          return GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: 250.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected ? [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                ] : null,
              ),
              child: Row(
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 16)),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      type.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DistanceMethodToggle extends StatelessWidget {
  final DistanceMethod selected;
  final ValueChanged<DistanceMethod> onChanged;

  const _DistanceMethodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DistanceMethod.values.map((method) {
          final isSelected = selected == method;
          return GestureDetector(
            onTap: () => onChanged(method),
            child: AnimatedContainer(
              duration: 250.ms,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                method.displayName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FuelTypeToggle extends StatelessWidget {
  final FuelType selected;
  final ValueChanged<FuelType> onChanged;

  const _FuelTypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: FuelType.values.map((type) {
          final isSelected = selected == type;
          return GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: 250.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected ? [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                ] : null,
              ),
              child: Text(
                type.displayName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
