import 'package:flutter/material.dart';

/// Light page route: short fade + small slide from the right.
class AppRoute {
  static Route<T> push<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final fade = animation.drive(CurveTween(curve: Curves.easeOut));
        final slide = animation.drive(
          Tween(begin: const Offset(0.06, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

/// Shared settings for [AnimatedSwitcher] (day / tab / auth changes).
class AppAnim {
  static const Duration short = Duration(milliseconds: 260);

  static Widget fadeSlide(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }

  /// Keeps old/new children top-aligned and full width while switching.
  static Widget topLayout(Widget? current, List<Widget> previous) {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.topCenter,
      children: [...previous, if (current != null) current],
    );
  }
}

/// One-time fade + rise on first build. Higher [index] = slightly later.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}