import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
                  targetAmount: 50000.0,
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Reset "${_currentGoal.title}"?', style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Sigurado ka bang gusto mong i-reset sa ₱0 ang naipon mo para sa goal na ito?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warningRed),
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = _currentGoal.copyWith(currentAmount: 0.0);
              setState(() => _goals[_selectedGoalIndex] = updated);
              await DatabaseService.instance.updateGoal(updated);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text('✓ Na-reset na ang "${_currentGoal.title}" sa ₱0.', style: const TextStyle(color: AppColors.drySage)),
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
      backgroundColor: AppColors.surface,
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
                  style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Ano ang bagong pinag-iipunan mo?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 18),

            // Goal Title
            const Text('Pangalan ng Goal', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Hal. Emergency Fund, Laptop, Travel',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.drySage),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Target Amount
            const Text('Target Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold),
                hintText: '20,000',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.drySage),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Create Button (Dusty Olive)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dustyOlive,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                final clean = targetController.text.replaceAll(',', '').replaceAll(' ', '').trim();
                final target = double.tryParse(clean) ?? 0.0;
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
                      backgroundColor: AppColors.surface,
                      content: Text('✓ Naidagdag na ang goal na "$title"!', style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
              },
              child: const Text(
                'I-save ang Bagong Goal',
                style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 14),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Mag-ipon para sa "${_currentGoal.title}"', style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Magkano ang idadagdag mo sa iyong ipon?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold),
                hintText: '1,000',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.drySage),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dustyOlive),
            onPressed: () {
              final clean = controller.text.replaceAll(',', '').replaceAll(' ', '').trim();
              final amt = double.tryParse(clean) ?? 0.0;
              if (amt > 0) {
                _deposit(amt);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Idagdag', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold)),
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.drySage)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ipon & Goals', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteSmoke)),
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
                      selectedColor: AppColors.dustyOlive,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: isSelected ? AppColors.drySage : AppColors.border),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary,
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

          // Main Goal Coin Card (Using Dark Khaki & Dry Sage from palette)
          GoalCoinCard(
            goal: _currentGoal,
            onTitleChanged: _updateTitle,
            onTargetChanged: _updateTarget,
          ),

          const SizedBox(height: 18),

          // Action Buttons: Dusty Olive Mag-ipon and Earthy Outline Reset
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dustyOlive,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.whiteSmoke),
                  label: const Text('Mag-ipon', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: _showCustomDepositDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ashBrown,
                    side: const BorderSide(color: AppColors.ashBrown),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  onPressed: _resetIpon,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // "Add another ipon" Card Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.whiteSmoke,
              backgroundColor: AppColors.surface.withValues(alpha: 0.5),
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.drySage, size: 20),
            label: const Text(
              'Add another ipon',
              style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _showAddGoalModal,
          ),
        ],
      ),
    );
  }
}
