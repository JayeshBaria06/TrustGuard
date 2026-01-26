import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/providers.dart';
import '../../../../ui/theme/chart_theme.dart';
import '../../models/spending_data.dart';

class SpendingTrendChart extends ConsumerStatefulWidget {
  final List<MonthlySpending> data;
  final String title;
  final int selectedMonths;
  final void Function(int)? onPeriodChanged;

  const SpendingTrendChart({
    super.key,
    required this.data,
    required this.title,
    this.selectedMonths = 6,
    this.onPeriodChanged,
  });

  @override
  ConsumerState<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends ConsumerState<SpendingTrendChart> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatMoney = ref.watch(moneyFormatterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.title, style: theme.textTheme.titleMedium),
              ),
              if (widget.onPeriodChanged != null) _buildPeriodSelector(theme),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.data.length < 2)
          _buildInsufficientDataState(theme)
        else
          AspectRatio(
            aspectRatio: 1.7,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 24,
                left: 12,
                top: 12,
                bottom: 12,
              ),
              child: LineChart(
                _mainData(theme, formatMoney),
                duration: ChartTheme.defaultAnimationDuration,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 3, label: Text('3M')),
        ButtonSegment(value: 6, label: Text('6M')),
        ButtonSegment(value: 12, label: Text('12M')),
      ],
      selected: {widget.selectedMonths},
      onSelectionChanged: (Set<int> newSelection) {
        widget.onPeriodChanged?.call(newSelection.first);
      },
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        textStyle: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  LineChartData _mainData(ThemeData theme, MoneyFormatter formatMoney) {
    final spots = widget.data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalAmountMinor.toDouble());
    }).toList();

    final maxVal = widget.data
        .map((e) => e.totalAmountMinor)
        .fold(0, (max, val) => val > max ? val : max);
    final maxY = maxVal > 0 ? maxVal.toDouble() * 1.2 : 1000.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxY / 4,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: ChartTheme.getGridLineColor(theme), strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: ChartTheme.getGridLineColor(theme), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.data.length) {
                return const SizedBox();
              }

              // Show labels based on data length to avoid overlap
              if (widget.data.length > 8 && index % 2 != 0) {
                return const SizedBox();
              }

              final date = widget.data[index].month;
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  DateFormat.MMM().format(date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox();
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  _formatCompact(value.toInt()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      minX: 0,
      maxX: (widget.data.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: theme.colorScheme.primary,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.3),
                theme.colorScheme.secondary.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              theme.colorScheme.surfaceContainerHighest,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final monthData = widget.data[barSpot.x.toInt()];
              return LineTooltipItem(
                '${DateFormat('MMMM yyyy').format(monthData.month)}\n',
                theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: formatMoney(monthData.totalAmountMinor),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}k';
    }
    // Convert minor units to major units for display
    final major = value / 100;
    if (major >= 1000) {
      return '${(major / 1000).toStringAsFixed(1)}k';
    }
    return major.toStringAsFixed(0);
  }

  Widget _buildInsufficientDataState(ThemeData theme) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Trend requires at least 2 months of data',
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
