import 'package:flutter/material.dart';

/// Bagian landing www yang bisa di-scroll dari navbar.
enum WwwSection {
  services,
  pricing,
  signup,
  blog,
  testimonials,
}

/// Koordinasi scroll antar [WwwNavbar] dan [WwwRouterPage].
class WwwLandingScope extends InheritedWidget {
  const WwwLandingScope({
    super.key,
    required this.scrollController,
    required this.sectionKeys,
    required super.child,
  });

  final ScrollController scrollController;
  final Map<WwwSection, GlobalKey> sectionKeys;

  static WwwLandingScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WwwLandingScope>();
    assert(scope != null, 'WwwLandingScope tidak ditemukan di pohon widget.');
    return scope!;
  }

  static WwwLandingScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WwwLandingScope>();
  }

  Future<void> scrollToTop() async {
    if (!scrollController.hasClients) return;
    await scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> scrollTo(WwwSection section) async {
    final key = sectionKeys[section];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  bool updateShouldNotify(WwwLandingScope oldWidget) =>
      scrollController != oldWidget.scrollController ||
      sectionKeys != oldWidget.sectionKeys;
}
