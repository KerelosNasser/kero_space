import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import '../../data/models/blacklist_rule.dart';

class RuleConfigurationSheet extends StatefulWidget {
  final String packageName;
  final BlacklistRule? existingRule;

  const RuleConfigurationSheet({super.key, required this.packageName, this.existingRule});

  static Future<BlacklistRule?> show(BuildContext context, String packageName, {BlacklistRule? existingRule}) {
    return showModalBottomSheet<BlacklistRule>(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: RuleConfigurationSheet(packageName: packageName, existingRule: existingRule),
      ),
    );
  }

  @override
  State<RuleConfigurationSheet> createState() => _State();
}

class _State extends State<RuleConfigurationSheet> {
  String? _subAppTarget;
  int? _sessionLimit;
  int? _cooldown;
  bool _strictMode = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      _subAppTarget = widget.existingRule!.subAppTarget;
      _sessionLimit = widget.existingRule!.sessionLimitMinutes;
      _cooldown = widget.existingRule!.cooldownMinutes;
      _strictMode = widget.existingRule!.strictMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configure App Rule', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          
          Text('Target Specific Context', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Entire App')),
              ButtonSegment(value: 'reels', label: Text('Reels/Shorts')),
            ],
            selected: {_subAppTarget},
            onSelectionChanged: (set) => setState(() => _subAppTarget = set.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: AppTheme.bgPrimary,
              foregroundColor: AppTheme.textPrimary,
              selectedForegroundColor: Colors.black,
              selectedBackgroundColor: AppTheme.accentCyan,
            ),
          ),
          
          const SizedBox(height: 24),
          Text('Session Limit (Minutes)', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<int?>(
            segments: const [
              ButtonSegment(value: null, label: Text('None')),
              ButtonSegment(value: 5, label: Text('5m')),
              ButtonSegment(value: 15, label: Text('15m')),
              ButtonSegment(value: 30, label: Text('30m')),
            ],
            selected: {_sessionLimit},
            onSelectionChanged: (set) => setState(() => _sessionLimit = set.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: AppTheme.bgPrimary,
              foregroundColor: AppTheme.textPrimary,
              selectedForegroundColor: Colors.black,
              selectedBackgroundColor: AppTheme.accentCyan,
            ),
          ),
          
          if (_sessionLimit != null) ...[
            const SizedBox(height: 24),
            Text('Cooldown Period', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<int?>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30m')),
                ButtonSegment(value: 60, label: Text('1h')),
                ButtonSegment(value: 120, label: Text('2h')),
              ],
              selected: {_cooldown ?? 60},
              onSelectionChanged: (set) => setState(() => _cooldown = set.first),
              style: SegmentedButton.styleFrom(
                backgroundColor: AppTheme.bgPrimary,
                foregroundColor: AppTheme.textPrimary,
                selectedForegroundColor: Colors.black,
                selectedBackgroundColor: AppTheme.accentCyan,
              ),
            ),
            
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Strict Block', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: const Text('No bypass during cooldown', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              value: _strictMode,
              onChanged: (val) => setState(() => _strictMode = val),
              activeTrackColor: AppTheme.accentCyan,
              contentPadding: EdgeInsets.zero,
            ),
          ],
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final rule = BlacklistRule(
                  packageName: widget.packageName,
                  subAppTarget: _subAppTarget,
                  sessionLimitMinutes: _sessionLimit,
                  cooldownMinutes: _sessionLimit != null ? (_cooldown ?? 60) : null,
                  strictMode: _strictMode,
                  decisionBreakSeconds: 30,
                );
                Navigator.of(context).pop(rule);
              },
              child: const Text('Save Rule', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
