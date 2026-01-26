import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/haptics.dart';

/// A custom numeric keypad for entering amounts.
class NumericKeypad extends StatelessWidget {
  /// Callback when a digit (0-9) is pressed.
  final ValueChanged<String> onDigitPressed;

  /// Callback when the decimal point is pressed.
  final VoidCallback onDecimalPressed;

  /// Callback when the backspace button is pressed.
  final VoidCallback onBackspacePressed;

  /// Callback when the clear button is pressed (e.g., long press on backspace).
  final VoidCallback onClearPressed;

  /// Whether to show the decimal point button.
  final bool showDecimal;

  /// Optional text style for the digits.
  final TextStyle? textStyle;

  /// Optional color for the keypad buttons.
  final Color? buttonColor;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDecimalPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
    this.showDecimal = true,
    this.textStyle,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.digit0 ||
              key == LogicalKeyboardKey.numpad0) {
            _handleDigit('0');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit1 ||
              key == LogicalKeyboardKey.numpad1) {
            _handleDigit('1');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit2 ||
              key == LogicalKeyboardKey.numpad2) {
            _handleDigit('2');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit3 ||
              key == LogicalKeyboardKey.numpad3) {
            _handleDigit('3');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit4 ||
              key == LogicalKeyboardKey.numpad4) {
            _handleDigit('4');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit5 ||
              key == LogicalKeyboardKey.numpad5) {
            _handleDigit('5');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit6 ||
              key == LogicalKeyboardKey.numpad6) {
            _handleDigit('6');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit7 ||
              key == LogicalKeyboardKey.numpad7) {
            _handleDigit('7');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit8 ||
              key == LogicalKeyboardKey.numpad8) {
            _handleDigit('8');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit9 ||
              key == LogicalKeyboardKey.numpad9) {
            _handleDigit('9');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.period ||
              key == LogicalKeyboardKey.numpadDecimal) {
            _handleDecimal();
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.backspace) {
            _handleBackspace();
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.escape) {
            _handleClear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          _buildRow(['4', '5', '6']),
          _buildRow(['7', '8', '9']),
          _buildLastRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (d) => _KeypadButton(
              label: d,
              onPressed: () => _handleDigit(d),
              textStyle: textStyle,
              color: buttonColor,
            ),
          )
          .toList(),
    );
  }

  Widget _buildLastRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _KeypadButton(
          label: showDecimal ? '.' : '',
          onPressed: showDecimal ? _handleDecimal : null,
          textStyle: textStyle,
          color: buttonColor,
          semanticsLabel: 'Decimal point',
        ),
        _KeypadButton(
          label: '0',
          onPressed: () => _handleDigit('0'),
          textStyle: textStyle,
          color: buttonColor,
        ),
        _KeypadButton(
          icon: Icons.backspace_outlined,
          onPressed: _handleBackspace,
          onLongPress: _handleClear,
          color: buttonColor,
          semanticsLabel: 'Backspace',
        ),
      ],
    );
  }

  void _handleDigit(String digit) {
    HapticsService.lightTap();
    onDigitPressed(digit);
  }

  void _handleDecimal() {
    if (showDecimal) {
      HapticsService.lightTap();
      onDecimalPressed();
    }
  }

  void _handleBackspace() {
    HapticsService.lightTap();
    onBackspacePressed();
  }

  void _handleClear() {
    HapticsService.warning();
    onClearPressed();
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final TextStyle? textStyle;
  final Color? color;
  final String? semanticsLabel;

  const _KeypadButton({
    this.label,
    this.icon,
    this.onPressed,
    this.onLongPress,
    this.textStyle,
    this.color,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Semantics(
              label: semanticsLabel ?? label,
              button: true,
              child: Container(
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      color ??
                      (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: icon != null
                    ? Icon(icon, size: 28, color: theme.colorScheme.primary)
                    : Text(
                        label ?? '',
                        style:
                            textStyle ??
                            theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
