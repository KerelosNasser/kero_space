import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kero_space/core/app_theme.dart';

class DeviceLockoutSheet extends StatefulWidget {
  const DeviceLockoutSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DeviceLockoutSheet(),
    );
  }

  @override
  State<DeviceLockoutSheet> createState() => _DeviceLockoutSheetState();
}

class _DeviceLockoutSheetState extends State<DeviceLockoutSheet> {
  static const _channel = MethodChannel('kero_space/methods');
  static const _presets = [15, 30, 45, 60, 90, 120];

  int _selectedMinutes = 30;
  bool _isLocking = false;

  Future<void> _startLockout() async {
    setState(() => _isLocking = true);
    HapticFeedback.heavyImpact();

    try {
      await _channel.invokeMethod('startDeviceLockout', {
        'durationMinutes': _selectedMinutes,
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start device lockout: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.phonelink_lock_rounded,
                  color: Color(0xFFEF5350),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep Me Out',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Full Phone Lockout & Screen Sleep',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Informational Warning Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFA726).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 20,
                  color: Color(0xFFFFA726),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This turns your screen off immediately and blocks all apps until the timer ends. Only emergency phone calls remain accessible.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Duration Selector
          Text(
            'LOCKOUT DURATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Preset Chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presets.map((mins) {
              final isSelected = _selectedMinutes == mins;
              final label = mins >= 60
                  ? '${(mins / 60).toStringAsFixed(mins % 60 == 0 ? 0 : 1)}h'
                  : '${mins}m';

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: const Color(0xFFEF5350).withValues(alpha: 0.25),
                backgroundColor: colors.bgBase,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFEF5350)
                      : colors.borderSubtle,
                  width: isSelected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFFEF5350)
                      : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMinutes = mins);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Slider
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFEF5350),
                    inactiveTrackColor: colors.borderSubtle,
                    thumbColor: const Color(0xFFEF5350),
                    overlayColor: const Color(0xFFEF5350).withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _selectedMinutes.toDouble(),
                    min: 10,
                    max: 180,
                    divisions: 34,
                    onChanged: (val) {
                      setState(() => _selectedMinutes = val.round());
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Text(
                  '${_selectedMinutes}m',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // CTA Action Button
          ElevatedButton(
            onPressed: _isLocking ? null : _startLockout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isLocking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power_settings_new_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Lock Phone & Turn Off Screen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
