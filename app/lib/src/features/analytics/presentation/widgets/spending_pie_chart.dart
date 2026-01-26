import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../ui/theme/chart_theme.dart';

class SpendingPieChart extends ConsumerStatefulWidget {
  final Map<String, int> data;
  final String title;
  final void Function(String)? onSegmentTap;

  const SpendingPieChart({
    super.key,
    required this.data,
    required this.title,
    this.onSegmentTap,
  });

  @override
  ConsumerState<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends ConsumerState<SpendingPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ChartTheme.getChartColors(theme);
    final formatMoney = ref.watch(moneyFormatterProvider);

    if (widget.data.isEmpty) {
      return _buildEmptyState(theme);
    }

    final total = widget.data.values.fold<int>(0, (sum, val) => sum + val);

    return Column(
      children: [
        Text(widget.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;

                        if (event is FlTapUpEvent && touchedIndex != -1) {
                          final category = widget.data.keys.elementAt(
                            touchedIndex,
                          );
                          widget.onSegmentTap?.call(category);
                        }
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _showingSections(colors, total, theme),
                ),
                duration: ChartTheme.defaultAnimationDuration,
              ),
              Center(
                child: SizedBox(
                  width: 90,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        touchedIndex != -1
                            ? widget.data.keys.elementAt(touchedIndex)
                            : 'Total',
                        style: ChartTheme.getLabelStyle(theme),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        touchedIndex != -1
                            ? formatMoney(
                                widget.data.values.elementAt(touchedIndex),
                              )
                            : formatMoney(total),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (touchedIndex != -1)
                        Text(
                          '${(widget.data.values.elementAt(touchedIndex) / total * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(colors, formatMoney, theme),
      ],
    );
  }

  List<PieChartSectionData> _showingSections(
    List<Color> colors,
    int total,
    ThemeData theme,
  ) {
    final entries = widget.data.entries.toList();
    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 25.0 : 20.0;
      final entry = entries[i];
      final amount = entry.value;

      return PieChartSectionData(
        color: colors[i % colors.length],
        value: amount.toDouble(),
        title: '', // We show info in the center
        radius: radius,
        showTitle: false,
      );
    });
  }

  Widget _buildLegend(
    List<Color> colors,
    MoneyFormatter formatMoney,
    ThemeData theme,
  ) {
    final entries = widget.data.entries.toList();
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(entries.length, (i) {
        final entry = entries[i];
        final color = colors[i % colors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.key}: ${formatMoney(entry.value)}',
              style: ChartTheme.getLegendStyle(theme),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No data for this period',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
