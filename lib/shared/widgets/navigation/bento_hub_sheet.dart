import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';

class BentoHubSheet extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectBranch;

  const BentoHubSheet({
    super.key,
    required this.currentIndex,
    required this.onSelectBranch,
  });

  static Future<void> show(
    BuildContext context, {
    required int currentIndex,
    required ValueChanged<int> onSelectBranch,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BentoHubSheet(
        currentIndex: currentIndex,
        onSelectBranch: onSelectBranch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final modules = [
      _BentoModule(
        index: 0,
        title: 'Home',
        subtitle: 'Focus & Day Overview',
        tag: 'DASHBOARD',
        icon: Icons.home_rounded,
        accentColor: colors.accentPrimary,
      ),
      _BentoModule(
        index: 1,
        title: 'Tasks',
        subtitle: 'Notes & Deep Work',
        tag: 'WORK',
        icon: Icons.task_alt_rounded,
        accentColor: colors.domainProductivity,
      ),
      _BentoModule(
        index: 2,
        title: 'Health',
        subtitle: 'Calories & Vitals',
        tag: 'BODY',
        icon: Icons.favorite_rounded,
        accentColor: colors.domainHealth,
      ),
      _BentoModule(
        index: 3,
        title: 'Finance',
        subtitle: 'Stocks & Subscriptions',
        tag: 'WEALTH',
        icon: Icons.account_balance_wallet_rounded,
        accentColor: colors.domainFinance,
      ),
      _BentoModule(
        index: 4,
        title: 'Church',
        subtitle: 'Coptic Mass & Agpeya',
        tag: 'SPIRIT',
        icon: Icons.church_rounded,
        accentColor: colors.domainChurch,
      ),
      _BentoModule(
        index: 5,
        title: 'Telemetry',
        subtitle: 'Hardware Rules & Usage',
        tag: 'SYSTEM',
        icon: Icons.bar_chart_rounded,
        accentColor: colors.domainTelemetry,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.borderSubtle, width: 1.5),
          left: BorderSide(color: colors.borderSubtle, width: 1),
          right: BorderSide(color: colors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MODULES CONTROL HUB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: colors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Text(
                  '6 MODULES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2x3 Bento Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemCount: modules.length,
            itemBuilder: (context, i) {
              final mod = modules[i];
              final isSelected = mod.index == currentIndex;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelectBranch(mod.index);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? mod.accentColor : colors.borderSubtle,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: mod.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(mod.icon, size: 18, color: mod.accentColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.bgElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                mod.tag,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mod.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              mod.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _BentoModule {
  final int index;
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color accentColor;

  const _BentoModule({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.accentColor,
  });
}
