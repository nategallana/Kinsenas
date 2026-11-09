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
  List<Goal> _goals = [];
  int _selectedGoalIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await DatabaseService.instance.getGoals();
    if (mounted) {
      setState(() {
        _goals = goals.isNotEmpty
            ? goals
            : [
                Goal(
                  id: 'goal_motor',
                  title: 'FOR MOTOR',
                  targetAmount: 60000.0,
                  currentAmount: 0.0,
                ),
              ];
        if (_selectedGoalIndex >= _goals.length) {
          _selectedGoalIndex = 0;
        }
        _isLoading = false;
      });
    }
  }

  Goal get _currentGoal => _goals[_selectedGoalIndex];

  void _deposit(double amount) async {
    final updated = _currentGoal.copyWith(
      currentAmount: (_currentGoal.currentAmount + amount).clamp(0.0, _currentGoal.targetAmount),
    );
    setState(() => _goals[_selectedGoalIndex] = updated);
    await DatabaseService.instance.updateGoal(updated);
  }

  void _resetIpon() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14151B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Reset "${_currentGoal.title}"?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
              setState(() => _goals[_selectedGoalIndex] = updated);
              await DatabaseService.instance.updateGoal(updated);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF14151B),
                    content: Text('✓ Na-reset na ang "${_currentGoal.title}" sa ₱0.', style: const TextStyle(color: Color(0xFF10B981))),
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

  void _showAddGoalModal() {
    final titleController = TextEditingController();
    final targetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14151B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Another Ipon Goal',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Ano ang bagong pinag-iipunan mo?',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 18),

            // Goal Title
            const Text('Pangalan ng Goal', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Hal. Emergency Fund, Laptop, Travel',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0B0C0F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Target Amount
            const Text('Target Amount', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                hintText: 'Hal. 20000',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0B0C0F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Create Button
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                final target = double.tryParse(targetController.text) ?? 0.0;
                if (title.isEmpty || target <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mangyaring ilagay ang pangalan at target amount.')),
                  );
                  return;
                }

                final newGoal = Goal(
                  id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                  title: title.toUpperCase(),
                  targetAmount: target,
                  currentAmount: 0.0,
                );

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);

                await DatabaseService.instance.insertGoal(newGoal);
                await _loadGoals();

                if (mounted) {
                  setState(() => _selectedGoalIndex = _goals.length - 1);
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF14151B),
                      content: Text('✓ Naidagdag na ang goal na "$title"!', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ),
                  );
                }
              },
              child: const Text(
                'I-save ang Bagong Goal',
                style: TextStyle(color: Color(0xFF1C1917), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDepositDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14151B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Mag-ipon para sa "${_currentGoal.title}"', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      ),
    );
  }

  void _updateTitle(String newTitle) async {
    final updated = _currentGoal.copyWith(title: newTitle);
    setState(() => _goals[_selectedGoalIndex] = updated);
    await DatabaseService.instance.updateGoal(updated);
  }

  void _updateTarget(double newTarget) async {
    final updated = _currentGoal.copyWith(targetAmount: newTarget);
    setState(() => _goals[_selectedGoalIndex] = updated);
    await DatabaseService.instance.updateGoal(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C0D10),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF43F5E))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ipon & Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        // Reset button removed from top right! Replaced with clean "+ Add Goal"
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Add Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: _showAddGoalModal,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Goal Switcher Tabs (If multiple goals exist)
          if (_goals.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _goals.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final g = entry.value;
                  final isSelected = idx == _selectedGoalIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g.title),
                      selected: isSelected,
                      selectedColor: const Color(0xFFF59E0B),
                      backgroundColor: const Color(0xFF14151B),
                      side: BorderSide(color: isSelected ? const Color(0xFFF59E0B) : Colors.white10),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF1C1917) : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedGoalIndex = idx);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Main Goal Coin Card
          GoalCoinCard(
            goal: _currentGoal,
            onTitleChanged: _updateTitle,
            onTargetChanged: _updateTarget,
          ),

          const SizedBox(height: 18),

          // Action Buttons: Mag-ipon (fixed double + bug!) and Reset
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
                  label: const Text('Mag-ipon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

          const SizedBox(height: 20),

          // "Add another ipon" Card Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0x08FFFFFF),
              side: const BorderSide(color: Color(0x20F59E0B)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFF59E0B), size: 20),
            label: const Text(
              'Add another ipon',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _showAddGoalModal,
          ),
        ],
      ),
    );
  }
}
