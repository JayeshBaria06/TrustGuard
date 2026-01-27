import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a destructive action that can be undone within a delay.
class UndoableAction {
  /// Unique identifier for the action.
  final String id;

  /// Description of the action (e.g., 'Transaction deleted').
  final String description;

  /// The actual action to execute after the delay.
  final Future<void> Function() executeAction;

  /// Optional action to execute if the main action is cancelled.
  final Future<void> Function()? undoAction;

  /// How long to wait before executing the action.
  final Duration delay;

  UndoableAction({
    required this.id,
    required this.description,
    required this.executeAction,
    this.undoAction,
    this.delay = const Duration(seconds: 5),
  });
}

/// Service for managing delayed actions that can be undone.
class UndoableActionService {
  final Map<String, Timer> _pendingActions = {};
  final Map<String, UndoableAction> _actionData = {};

  /// Schedules an action to be executed after its specified delay.
  ///
  /// Returns the action ID.
  String schedule(UndoableAction action) {
    // If an action with the same ID already exists, execute it immediately
    // before scheduling the new one to avoid conflicts.
    if (_pendingActions.containsKey(action.id)) {
      executeNow(action.id);
    }

    _actionData[action.id] = action;
    _pendingActions[action.id] = Timer(action.delay, () {
      _execute(action.id);
    });

    return action.id;
  }

  /// Cancels a pending action and executes its undo callback if provided.
  Future<bool> cancel(String actionId) async {
    final timer = _pendingActions.remove(actionId);
    if (timer != null) {
      timer.cancel();
      final action = _actionData.remove(actionId);
      if (action?.undoAction != null) {
        await action!.undoAction!();
      }
      return true;
    }
    return false;
  }

  /// Executes a pending action immediately, bypassing the remaining delay.
  Future<void> executeNow(String actionId) async {
    final timer = _pendingActions.remove(actionId);
    if (timer != null) {
      timer.cancel();
      await _execute(actionId);
    }
  }

  Future<void> _execute(String actionId) async {
    final action = _actionData.remove(actionId);
    _pendingActions.remove(actionId);
    if (action != null) {
      try {
        await action.executeAction();
      } catch (e) {
        // In a real app, we might want to log this error.
        // For now, we'll just allow it to propagate or be swallowed.
      }
    }
  }

  /// Cancels all pending actions.
  void dispose() {
    for (final timer in _pendingActions.values) {
      timer.cancel();
    }
    _pendingActions.clear();
    _actionData.clear();
  }
}

/// Provider for the [UndoableActionService].
final undoableActionProvider = Provider<UndoableActionService>((ref) {
  final service = UndoableActionService();
  ref.onDispose(() => service.dispose());
  return service;
});
