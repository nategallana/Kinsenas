import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0x33BCBD8B), // Subtle Dry Sage pill
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.drySage),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.calculate_rounded, color: AppColors.drySage),
              label: 'Sahod',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.savings_rounded, color: AppColors.drySage),
              label: 'Ipon',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.swap_horiz_rounded, color: AppColors.drySage),
              label: 'Utang',
            ),
          ],
        ),
      ),
    );
  }
}
