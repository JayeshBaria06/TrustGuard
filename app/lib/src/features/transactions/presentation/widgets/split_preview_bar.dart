import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app.dart';
import '../../../../app/providers.dart';

class SplitPreviewBar extends ConsumerWidget {
  final int totalAmount;
  final Map<String, int> splits;
  final Map<String, String> memberNames;
  final String currencyCode;

  const SplitPreviewBar({
    super.key,
    required this.totalAmount,
    required this.splits,
    required this.memberNames,
    required this.currencyCode,
  });

  // Color palette for members
  static const List<Color> _palette = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatMoney = ref.watch(moneyFormatterProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final int customTotalMinor = splits.values.fold(0, (sum, val) => sum + val);
    final difference = totalAmount - customTotalMinor;
    final isCorrect = difference == 0;

    final sortedMemberIds = splits.keys.toList()..sort();
    final hasPortions = totalAmount > 0 && splits.values.any((v) => v > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Proportional Bar
        Container(
          height: 12,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: !hasPortions
              ? null
              : Row(
                  children: sortedMemberIds.map((id) {
                    final amount = splits[id] ?? 0;
                    if (amount <= 0) return const SizedBox.shrink();

                    final percentage = amount / totalAmount;
                    final colorIndex =
                        sortedMemberIds.indexOf(id) % _palette.length;
                    final color = _palette[colorIndex];

                    // Use Expanded with a flex proportional to the percentage
                    // Using a large base (1000) for better precision
                    return Expanded(
                      flex: (percentage * 1000).round().clamp(1, 1000),
                      child: Tooltip(
                        message: l10n.splitPortion(
                          memberNames[id] ?? '?',
                          formatMoney(amount, currencyCode: currencyCode),
                          (percentage * 100).toStringAsFixed(1),
                        ),
                        child: Container(color: color),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 8),
        // Status Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withAlpha(25)
                : Colors.red.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isCorrect ? Colors.green : Colors.red),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCorrect ? l10n.totalMatches : l10n.totalMismatch,
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                isCorrect
                    ? formatMoney(totalAmount, currencyCode: currencyCode)
                    : '${difference > 0 ? l10n.remaining : l10n.over}: ${formatMoney(difference.abs(), currencyCode: currencyCode)}',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
