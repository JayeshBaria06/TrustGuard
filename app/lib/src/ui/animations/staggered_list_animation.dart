import 'package:flutter/material.dart';
import 'animation_config.dart';

/// Controller for managing staggered entrance animations for list items.
class StaggeredListAnimationController {
  final TickerProvider vsync;
  final int itemCount;
  final Duration staggerDelay;
  final Duration itemDuration;

  late final AnimationController controller;
  bool _isDisposed = false;

  StaggeredListAnimationController({
    required this.vsync,
    required this.itemCount,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemDuration = AnimationConfig.defaultDuration,
  }) {
    final totalDuration =
        itemDuration + (staggerDelay * (itemCount > 0 ? itemCount - 1 : 0));
    controller = AnimationController(vsync: vsync, duration: totalDuration);
  }

  /// Returns an animation for the item at the given [index].
  Animation<double> getAnimation(int index) {
    if (_isDisposed ||
        controller.duration == null ||
        controller.duration == Duration.zero) {
      return const AlwaysStoppedAnimation(1.0);
    }

    final start =
        (staggerDelay.inMilliseconds * index) /
        controller.duration!.inMilliseconds;
    final end =
        (staggerDelay.inMilliseconds * index + itemDuration.inMilliseconds) /
        controller.duration!.inMilliseconds;

    return CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// Starts the staggered animation sequence.
  void startAnimation() {
    if (!_isDisposed) {
      controller.forward();
    }
  }

  /// Resets the animation to the beginning.
  void reset() {
    if (!_isDisposed) {
      controller.reset();
    }
  }

  /// Disposes the underlying [AnimationController].
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    controller.dispose();
  }
}

/// A wrapper widget that applies fade and slide transitions to a [child]
/// based on the provided [animation].
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Offset slideOffset;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.animation,
    this.slideOffset = const Offset(0, 0.1),
  });

  @override
  Widget build(BuildContext context) {
    if (AnimationConfig.useReducedMotion(context)) {
      return child;
    }

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: slideOffset, end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}
