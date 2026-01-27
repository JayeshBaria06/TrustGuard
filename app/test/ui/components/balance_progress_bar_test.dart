import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/components/balance_progress_bar.dart';

void main() {
  String formatMoney(int amount, {String? currencyCode, String? locale}) {
    return '\$${(amount / 100).toStringAsFixed(2)}';
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 200, child: child)),
      ),
    );
  }

  group('BalanceProgressBar', () {
    testWidgets('renders positive amount correctly', (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceProgressBar(
            amount: 5000,
            maxAmount: 10000,
            currencyCode: 'USD',
            formatMoney: formatMoney,
          ),
        ),
      );

      expect(find.text('\$50.00'), findsOneWidget);

      // The positive bar should have width 50 (halfWidth * 0.5)
      // constraints.maxWidth in wrap is 200, so halfWidth is 100.
      // 100 * (5000/10000) = 50.

      final greenContainer = find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.green,
      );
      expect(greenContainer, findsOneWidget);

      // For AnimatedContainer, the width is passed to the internal Container
      // Since it's inside a Stack/Positioned, we can check the RenderBox size
      final RenderBox box = tester.renderObject(greenContainer);
      expect(box.size.width, 50.0);
    });

    testWidgets('renders negative amount correctly', (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceProgressBar(
            amount: -2500,
            maxAmount: 10000,
            currencyCode: 'USD',
            formatMoney: formatMoney,
          ),
        ),
      );

      expect(find.text('\$25.00'), findsOneWidget);

      final redContainer = find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.red,
      );
      expect(redContainer, findsOneWidget);

      final RenderBox box = tester.renderObject(redContainer);
      expect(box.size.width, 25.0);
    });

    testWidgets('renders zero amount correctly', (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceProgressBar(
            amount: 0,
            maxAmount: 10000,
            currencyCode: 'USD',
            formatMoney: formatMoney,
          ),
        ),
      );

      expect(find.text('\$0.00'), findsOneWidget);

      // Both bars should have width 0
      final redContainer = find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.red,
      );
      final greenContainer = find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.green,
      );

      expect(tester.renderObject<RenderBox>(redContainer).size.width, 0.0);
      expect(tester.renderObject<RenderBox>(greenContainer).size.width, 0.0);
    });

    testWidgets('respects showLabel=false', (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceProgressBar(
            amount: 5000,
            maxAmount: 10000,
            currencyCode: 'USD',
            formatMoney: formatMoney,
            showLabel: false,
          ),
        ),
      );

      expect(find.text('\$50.00'), findsNothing);
    });

    testWidgets('caps at maxAmount', (tester) async {
      await tester.pumpWidget(
        wrap(
          BalanceProgressBar(
            amount: 15000,
            maxAmount: 10000,
            currencyCode: 'USD',
            formatMoney: formatMoney,
          ),
        ),
      );

      final greenContainer = find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.green,
      );

      // Should be halfWidth (100)
      expect(tester.renderObject<RenderBox>(greenContainer).size.width, 100.0);
    });
  });
}
