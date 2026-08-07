import 'package:flutter/material.dart';

/// Exposes tablet sidebar visibility to descendant tabs (dashboard, items, …).
class TabletShellScope extends InheritedWidget {
  const TabletShellScope({
    super.key,
    required this.navOpen,
    required this.onToggleNav,
    required super.child,
  });

  final bool navOpen;
  final VoidCallback onToggleNav;

  static TabletShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabletShellScope>();
  }

  void toggleNav() => onToggleNav();

  @override
  bool updateShouldNotify(TabletShellScope oldWidget) =>
      oldWidget.navOpen != navOpen;
}
