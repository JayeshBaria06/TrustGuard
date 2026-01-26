import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/theme/app_theme.dart';
import '../providers/analytics_providers.dart';
import 'widgets/spending_pie_chart.dart';
import 'widgets/spending_trend_chart.dart';
import '../../../generated/app_localizations.dart';

class AnalyticsScreen extends ConsumerWidget {
  final String groupId;

  const AnalyticsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final period = ref.watch(analyticsPeriodProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(l10n.analyticsTitle),
            floating: true,
            actions: [_buildPeriodMenu(context, ref, period, l10n)],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.space16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCard(
                  context,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final dataAsync = ref.watch(
                        monthlyTrendProvider(groupId),
                      );
                      return dataAsync.when(
                        data: (data) => SpendingTrendChart(
                          data: data,
                          title: l10n.monthlyTrend,
                          selectedMonths: period.months,
                          onPeriodChanged: (months) {
                            final newPeriod = AnalyticsPeriod.values.firstWhere(
                              (p) => p.months == months,
                              orElse: () => AnalyticsPeriod.last6Months,
                            );
                            ref.read(analyticsPeriodProvider.notifier).state =
                                newPeriod;
                          },
                        ),
                        loading: () => const _LoadingPlaceholder(height: 250),
                        error: (err, _) => _ErrorPlaceholder(error: err),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                _buildCard(
                  context,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final dataAsync = ref.watch(
                        spendingByTagProvider(groupId),
                      );
                      return dataAsync.when(
                        data: (data) => SpendingPieChart(
                          data: data,
                          title: l10n.spendingByCategory,
                        ),
                        loading: () => const _LoadingPlaceholder(height: 300),
                        error: (err, _) => _ErrorPlaceholder(error: err),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                _buildCard(
                  context,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final dataAsync = ref.watch(
                        spendingByMemberProvider(groupId),
                      );
                      return dataAsync.when(
                        data: (data) => SpendingPieChart(
                          data: data,
                          title: l10n.spendingByMember,
                        ),
                        loading: () => const _LoadingPlaceholder(height: 300),
                        error: (err, _) => _ErrorPlaceholder(error: err),
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodMenu(
    BuildContext context,
    WidgetRef ref,
    AnalyticsPeriod currentPeriod,
    AppLocalizations l10n,
  ) {
    return PopupMenuButton<AnalyticsPeriod>(
      initialValue: currentPeriod,
      onSelected: (period) {
        ref.read(analyticsPeriodProvider.notifier).state = period;
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AnalyticsPeriod.last3Months,
          child: Text(l10n.period3Months),
        ),
        PopupMenuItem(
          value: AnalyticsPeriod.last6Months,
          child: Text(l10n.period6Months),
        ),
        PopupMenuItem(
          value: AnalyticsPeriod.last12Months,
          child: Text(l10n.period12Months),
        ),
      ],
      icon: const Icon(Icons.calendar_today_outlined),
      tooltip: 'Change Period',
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.space16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: child,
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;
  const _LoadingPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final Object error;
  const _ErrorPlaceholder({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Text('Error: $error', textAlign: TextAlign.center),
      ),
    );
  }
}
