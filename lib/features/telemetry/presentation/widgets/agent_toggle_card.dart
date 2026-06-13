import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class AgentToggleCard extends StatelessWidget {
  final String agentId;
  final String label;
  final IconData icon;
  final String statusSummary;
  final bool isEnabled;
  final void Function(bool) onToggle;

  const AgentToggleCard({
    super.key, required this.agentId, required this.label, required this.icon,
    required this.statusSummary, required this.isEnabled, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppTheme.accentCyan.withValues(alpha: 0.5) : AppTheme.bgElevated,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: isEnabled ? AppTheme.accentCyan : AppTheme.textDisabled, size: 20),
            const Spacer(),
            Switch.adaptive(value: isEnabled, onChanged: onToggle, activeTrackColor: AppTheme.accentCyan),
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                statusSummary,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
