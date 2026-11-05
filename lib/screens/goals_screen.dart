import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../widgets/goal_coin_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Goal _currentGoal = Goal(
    id: 'goal_motor',
    title: 'FOR MOTOR',
    targetAmount: 60000.0,
    currentAmount: 35000.0,
  );

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final goals = await DatabaseService.instance.getGoals();
    if (goals.isNotEmpty && mounted) {
      setState(() => _currentGoal = goals.first);
    }
  }

  void _deposit(double amount) async {
    final updated = _currentGoal.copyWith(
      currentAmount: (_currentGoal.currentAmount + amount).clamp(0.0, _currentGoal.targetAmount),
    );
    setState(() => _currentGoal = updated);
    await DatabaseService.instance.updateGoal(updated);
  }

  void _updateTitle(String newTitle) async {
    final updated = _currentGoal.copyWith(title: newTitle);
    setState(() => _currentGoal = updated);
    await DatabaseService.instance.updateGoal(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ipon & Goals', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Emil Kowalski refined sketch card (No target date, inline renameable)
          GoalCoinCard(
            goal: _currentGoal,
            onTitleChanged: _updateTitle,
            onDeposit: () => _deposit(1000),
          ),

          const SizedBox(height: 20),

          // Quick Deposit Action Chips
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF14151B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _deposit(500),
                  child: const Text('+ ₱500 (Tipid)', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _deposit(2500),
                  child: const Text('+ ₱2,500 (Sahod)', style: TextStyle(color: Color(0xFF1C1917), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
