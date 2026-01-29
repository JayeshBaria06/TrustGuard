import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../models/widget_data.dart';

class WidgetDataService {
  final DashboardService _dashboardService;

  WidgetDataService({required DashboardService dashboardService})
    : _dashboardService = dashboardService;

  static const String _androidWidgetName = 'BalanceWidgetProvider';
  // static const String _iosWidgetName = 'BalanceWidget'; // Placeholder

  Future<WidgetData> getWidgetData() async {
    // For now, aggregate all balances (null selfMemberId)
    final summary = await _dashboardService.getGlobalSummary(null);

    return WidgetData(
      totalOwedToMe: summary.totalOwedToMe,
      totalOwedByMe: summary.totalOwedByMe,
      netBalance: summary.netBalance,
      currencyCode: 'USD', // Default to USD for now, could be improved later
      activeGroupCount: summary.groupCount,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> saveWidgetData(WidgetData data) async {
    await HomeWidget.saveWidgetData('widget_owed_to_me', data.totalOwedToMe);
    await HomeWidget.saveWidgetData('widget_owed_by_me', data.totalOwedByMe);
    await HomeWidget.saveWidgetData('widget_net_balance', data.netBalance);
    await HomeWidget.saveWidgetData('widget_currency_code', data.currencyCode);
    await HomeWidget.saveWidgetData(
      'widget_group_count',
      data.activeGroupCount,
    );
    await HomeWidget.saveWidgetData(
      'widget_last_updated',
      data.lastUpdated.toIso8601String(),
    );
  }

  Future<void> updateWidget() async {
    final data = await getWidgetData();
    await saveWidgetData(data);
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
      // iOSName: _iosWidgetName,
    );
  }
}

final widgetDataServiceProvider = Provider<WidgetDataService>((ref) {
  return WidgetDataService(
    dashboardService: ref.watch(dashboardServiceProvider),
  );
});
