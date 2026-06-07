import 'package:flutter/material.dart';

enum V2ScreenSize { mobile, tablet, desktop }

abstract final class V2Responsive {
  static V2ScreenSize of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1024) return V2ScreenSize.desktop;
    if (w >= 600) return V2ScreenSize.tablet;
    return V2ScreenSize.mobile;
  }

  static bool isMobile(BuildContext context) => of(context) == V2ScreenSize.mobile;

  static bool isNarrowMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 400;

  static double heroTitleSize(BuildContext context) {
    return switch (of(context)) {
      V2ScreenSize.desktop => 36,
      V2ScreenSize.tablet => 30,
      V2ScreenSize.mobile => 26,
    };
  }

  static double heroIllustrationHeight(BuildContext context) {
    return switch (of(context)) {
      V2ScreenSize.desktop => 280,
      V2ScreenSize.tablet => 240,
      V2ScreenSize.mobile => 180,
    };
  }

  static int serviceGridColumns(BuildContext context) {
    if (isNarrowMobile(context)) return 1;
    return gridColumns(context, mobile: 2, tablet: 2, desktop: 4);
  }

  static double serviceCardAspectRatio(BuildContext context) {
    if (isNarrowMobile(context)) return 2.4;
    return switch (of(context)) {
      V2ScreenSize.desktop => 1.15,
      V2ScreenSize.tablet => 1.25,
      V2ScreenSize.mobile => 1.35,
    };
  }

  static double contentMaxWidth(BuildContext context) {
    return switch (of(context)) {
      V2ScreenSize.desktop => 960,
      V2ScreenSize.tablet => 720,
      V2ScreenSize.mobile => double.infinity,
    };
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return switch (of(context)) {
      V2ScreenSize.desktop => const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      V2ScreenSize.tablet => const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      V2ScreenSize.mobile => const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    };
  }

  static int gridColumns(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    return switch (of(context)) {
      V2ScreenSize.desktop => desktop,
      V2ScreenSize.tablet => tablet,
      V2ScreenSize.mobile => mobile,
    };
  }

  static Widget constrain(Widget child, BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}
