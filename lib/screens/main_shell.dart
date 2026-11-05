import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'salary_splitter_screen.dart';
import 'goals_screen.dart';
import 'utang_hub_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    SalarySplitterScreen(),
    GoalsScreen(),
    UtangHubScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D10),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF14151B),
          border: Border(top: BorderSide(color: Colors.white10, width: 0.8)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0x20F43F5E),
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFF43F5E)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.calculate_rounded, color: Color(0xFFF43F5E)),
              label: 'Sahod',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.savings_rounded, color: Color(0xFFF43F5E)),
              label: 'Ipon',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_rounded, color: Colors.white60),
              selectedIcon: Icon(Icons.swap_horiz_rounded, color: Color(0xFFF43F5E)),
              label: 'Utang',
            ),
          ],
        ),
      ),
    );
  }
}
