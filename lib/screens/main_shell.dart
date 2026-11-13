import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/abstract_wave_nav_bar.dart';
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
      bottomNavigationBar: AbstractWaveNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (idx) => setState(() => _currentIndex = idx),
      ),
    );
  }
}
