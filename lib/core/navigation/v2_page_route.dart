import 'package:flutter/material.dart';

/// Slide + fade page transition for v2 flows.
class V2PageRoute<T> extends PageRouteBuilder<T> {
  V2PageRoute({required this.page, this.slideFromRight = true})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offset = slideFromRight
                ? Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
                : Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero);
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: SlideTransition(
                position: offset.animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
        );

  final Widget page;
  final bool slideFromRight;
}

Future<T?> v2Push<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(V2PageRoute<T>(page: page));
}
