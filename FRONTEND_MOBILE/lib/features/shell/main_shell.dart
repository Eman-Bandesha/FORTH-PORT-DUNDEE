import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/layout/app_breakpoints.dart';
import '../dashboard/data/dashboard_repository.dart';
import '../items/data/items_repository.dart';
import '../movements/data/movements_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../items/items_list_screen.dart';
import '../movements/movements_screen.dart';
import '../more/more_screen.dart';
import 'tablet_shell_scope.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/tablet_side_nav.dart';

/// The authenticated app shell: hosts the primary tabs and navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _tabletNavOpen = true;

  void _selectTab(int index) => setState(() => _index = index);

  void _toggleTabletNav() => setState(() => _tabletNavOpen = !_tabletNavOpen);

  @override
  void initState() {
    super.initState();
    if (!ItemsRepository.isMemoryMode) {
      unawaited(_syncRemoteData());
    }
  }

  Future<void> _syncRemoteData() async {
    try {
      await Future.wait(<Future<void>>[
        ItemsRepository.refresh(),
        MovementsRepository.refresh(),
        DashboardRepository.refresh(),
      ]);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    final List<Widget> tabs = <Widget>[
      DashboardScreen(
        onSelectTab: _selectTab,
        isTabletLayout: isTablet,
      ),
      const ItemsListScreen(),
      const MovementsScreen(),
      const MoreScreen(),
    ];

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: _tabletNavOpen ? TabletSideNav.width : 0,
                child: TabletSideNav(
                  currentIndex: _index,
                  onSelect: _selectTab,
                  onProfileTap: () => _selectTab(3),
                ),
              ),
            ),
            Expanded(
              child: TabletShellScope(
                navOpen: _tabletNavOpen,
                onToggleNav: _toggleTabletNav,
                child: IndexedStack(index: _index, children: tabs),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _selectTab,
      ),
    );
  }
}
