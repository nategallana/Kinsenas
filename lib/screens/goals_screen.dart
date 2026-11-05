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

  void _resetIpon() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14151B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Ipon?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Sigurado ka bang gusto mong i-reset sa ₱0 ang naipon mo para sa goal na ito?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = _currentGoal.copyWith(currentAmount: 0.0);
              setState(() => _currentGoal = updated);
              await DatabaseService.instance.updateGoal(updated);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF14151B),
                    content: Text('✓ Na-reset na ang ipon sa ₱0. Bagong simula!', style: TextStyle(color: Color(0xFF10B981))),
                  ),
                );
              }
            },
            child: const Text('Reset to ₱0', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCustomDepositDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF14151B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Mag-ipon (Deposit)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Magkano ang idadagdag mo sa iyong ipon?', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    prefixStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF0B0C0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Quick chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [100, 200, 500, 1000].map((amt) {
                    return ActionChip(
                      backgroundColor: const Color(0xFF1E2028),
                      side: const BorderSide(color: Colors.white10),
                      label: Text('+₱$amt', style: const TextStyle(color: Colors.amber, fontSize: 11)),
                      onPressed: () {
                        controller.text = amt.toString();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () {
                  final amt = double.tryParse(controller.text) ?? 0.0;
                  if (amt > 0) {
                    _deposit(amt);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Idagdag', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateTitle(String newTitle) async {
    final updated = _currentGoal.copyWith(title: newTitle);
    setState(() => _currentGoal = updated);
    await DatabaseService.instance.updateGoal(updated);
  }

  void _updateTarget(double newTarget) async {
    final updated = _currentGoal.copyWith(targetAmount: newTarget);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Reset Ipon to ₱0',
            onPressed: _resetIpon,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Emil Kowalski refined sketch card (Inline renameable title + changeable target)
          GoalCoinCard(
            goal: _currentGoal,
            onTitleChanged: _updateTitle,
            onTargetChanged: _updateTarget,
          ),

          const SizedBox(height: 18),

          // Action Buttons: + Mag-ipon (Add) and Reset
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  label: const Text('+ Mag-ipon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _showCustomDepositDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF43F5E),
                    side: const BorderSide(color: Color(0x50F43F5E)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _resetIpon,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quick Preset Deposit Chips
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF14151B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _deposit(500),
                  child: const Text('+ ₱500 (Tipid)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
