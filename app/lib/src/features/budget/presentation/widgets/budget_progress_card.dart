import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/budget_progress.dart';
import '../../../../ui/theme/app_colors_extension.dart';
import '../../../../app/providers.dart';
import '../../../../ui/animations/animation_config.dart';

class BudgetProgressCard extends ConsumerWidget {
  final BudgetProgress progress;
  final bool compact;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.progress,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>();
    final formatMoney = ref.watch(moneyFormatterProvider);
    final budget = progress.budget;

    final percent = progress.percentUsed;
    final thresholdPercent = budget.alertThreshold / 100.0;

    // Determine color based on progress
    Color progressColor;
    if (percent >= thresholdPercent || progress.isOverBudget) {
      progressColor = theme.colorScheme.error;
    } else if (percent >= 0.5) {
      progressColor = Colors.amber; // Warning color
    } else {
      progressColor = appColors?.success ?? Colors.green;
    }

    final formattedSpent = formatMoney(
      progress.spentMinor,
      currencyCode: budget.currencyCode,
    );
    final formattedLimit = formatMoney(
      budget.limitMinor,
      currencyCode: budget.currencyCode,
    );

    return Card(
      margin: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: compact ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: compact
            ? BorderSide(color: theme.colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap:
            onTap ??
            () {
              // Navigate to budget settings (edit mode)
              context.push(
                '/group/${budget.groupId}/budget-settings',
                extra: budget,
              );
            },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      budget.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (progress.isOverBudget || percent >= thresholdPercent)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (compact) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$formattedSpent / $formattedLimit',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      progress.periodLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedSpent,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      'of $formattedLimit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  progress.periodLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _AnimatedProgressBar(
                percent: percent,
                color: progressColor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double percent;
  final Color color;
  final Color backgroundColor;

  const _AnimatedProgressBar({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp percent to 1.0 for the bar width, but logic might handle >100% differently?
    // Usually a bar fills up to 100%. If over, it's just full.
    final displayPercent = percent.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              AnimatedFractionallySizedBox(
                duration: AnimationConfig.defaultDuration,
                curve: Curves.easeOutCubic,
                widthFactor: displayPercent,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
