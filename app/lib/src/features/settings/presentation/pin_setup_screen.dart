import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lock_providers.dart';
import '../../../app/providers.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _firstPin = '';
  String _secondPin = '';
  bool _isConfirming = false;
  static const _maxPinLength = 4;

  void _onDigitPressed(int digit) {
    if (_isConfirming) {
      if (_secondPin.length < _maxPinLength) {
        setState(() => _secondPin += digit.toString());
        if (_secondPin.length == _maxPinLength) {
          _verifyAndSave();
        }
      }
    } else {
      if (_firstPin.length < _maxPinLength) {
        setState(() => _firstPin += digit.toString());
        if (_firstPin.length == _maxPinLength) {
          setState(() => _isConfirming = true);
        }
      }
    }
  }

  void _onBackspace() {
    if (_isConfirming) {
      if (_secondPin.isNotEmpty) {
        setState(
          () => _secondPin = _secondPin.substring(0, _secondPin.length - 1),
        );
      } else {
        setState(() => _isConfirming = false);
      }
    } else {
      if (_firstPin.isNotEmpty) {
        setState(
          () => _firstPin = _firstPin.substring(0, _firstPin.length - 1),
        );
      }
    }
  }

  Future<void> _verifyAndSave() async {
    if (_firstPin == _secondPin) {
      await ref.read(appLockServiceProvider).setPin(_firstPin);
      await ref.read(appLockStateProvider.notifier).init();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN set successfully')));
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _secondPin = '';
        _firstPin = '';
        _isConfirming = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PINs do not match. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isConfirming ? 'Confirm PIN' : 'Set PIN')),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _isConfirming ? 'Re-enter your PIN' : 'Enter a new 4-digit PIN',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_maxPinLength, (index) {
                final pin = _isConfirming ? _secondPin : _firstPin;
                final isFilled = index < pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(flex: 1),
            _buildNumericPad(theme),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericPad(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitButton(1),
              _buildDigitButton(2),
              _buildDigitButton(3),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitButton(4),
              _buildDigitButton(5),
              _buildDigitButton(6),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitButton(7),
              _buildDigitButton(8),
              _buildDigitButton(9),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 64),
              _buildDigitButton(0),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitButton(int digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: Text(
            digit.toString(),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: const Icon(Icons.backspace_outlined),
        ),
      ),
    );
  }
}
