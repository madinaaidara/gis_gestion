import 'package:flutter/material.dart';

/// Breakpoints unifiés — à utiliser partout (pages + widgets).
abstract final class AppBreakpoints {
  static const phone = 600;
  static const pagePadding = 720;
  static const twoColumn = 900;
  static const kpiRow = 960;
  static const sidebar = 1200;
}

class ResponsiveUtils {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isPhone(BuildContext context) => width(context) < AppBreakpoints.phone;

  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= AppBreakpoints.phone && w < AppBreakpoints.twoColumn;
  }

  static bool isDesktop(BuildContext context) => width(context) >= AppBreakpoints.twoColumn;

  /// Sidebar + top bar (navigation desktop).
  static bool hasSidebar(BuildContext context) => width(context) >= AppBreakpoints.sidebar;

  /// Bottom nav + drawer (téléphone / tablette).
  static bool useCompactNav(BuildContext context) => !hasSidebar(context);

  static bool isPageWide(BuildContext context) => width(context) >= AppBreakpoints.pagePadding;

  static bool isKpiRowWide(BuildContext context) => width(context) >= AppBreakpoints.kpiRow;

  static bool isTwoColumnWide(BuildContext context) => width(context) >= AppBreakpoints.twoColumn;

  /// Padding horizontal standard des pages (16 mobile / 24 à partir de 720px).
  static double pageHorizontalPadding(BuildContext context) => isPageWide(context) ? 24 : 16;

  /// Espace bas des listes scrollables dans la navigation compacte (bottom bar 64px).
  static double scrollBottomInset(BuildContext context) {
    if (hasSidebar(context)) return 16;
    return kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom + 12;
  }

  /// Layout caisse côte-à-côte uniquement avec la sidebar desktop.
  static bool useDesktopPosLayout(BuildContext context) => hasSidebar(context);

  static double getIconSize(BuildContext context, {double phone = 24, double tablet = 32, double desktop = 40}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getTitleSize(BuildContext context, {double phone = 20, double tablet = 24, double desktop = 28}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getBodySize(BuildContext context, {double phone = 16, double tablet = 14, double desktop = 16}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getPadding(BuildContext context, {double phone = 16, double tablet = 24, double desktop = 32}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getRadius(BuildContext context, {double phone = 12, double tablet = 14, double desktop = 16}) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getMaxContentWidth(BuildContext context) {
    if (isPhone(context)) return double.infinity;
    if (isTablet(context)) return 720;
    return double.infinity;
  }

  static Widget centerWithMaxWidth(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: getMaxContentWidth(context)),
        child: child,
      ),
    );
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isPhone(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  static double getGridSpacing(BuildContext context) => isPhone(context) ? 8 : 16;

  static double getDevicePixelRatio(BuildContext context) => MediaQuery.of(context).devicePixelRatio;

  static bool isHighDensity(BuildContext context) => MediaQuery.of(context).devicePixelRatio > 2.0;

  static double getWidthPercent(BuildContext context, double percent) => width(context) * (percent / 100);

  static double getHeightPercent(BuildContext context, double percent) =>
      MediaQuery.sizeOf(context).height * (percent / 100);

  static double getMaxContainerWidth(BuildContext context) {
    final w = width(context);
    if (w < AppBreakpoints.phone) return w * 0.9;
    if (w < AppBreakpoints.twoColumn) return 560;
    return 720;
  }
}
