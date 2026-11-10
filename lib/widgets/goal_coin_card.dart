import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/goal.dart';

class GoalCoinCard extends StatefulWidget {
  final Goal goal;
  final Function(String newTitle) onTitleChanged;
  final Function(double newTarget) onTargetChanged;

  const GoalCoinCard({
    super.key,
    required this.goal,
    required this.onTitleChanged,
    required this.onTargetChanged,
  });

  @override
  State<GoalCoinCard> createState() => _GoalCoinCardState();
}

class _GoalCoinCardState extends State<GoalCoinCard> {
  late TextEditingController _titleController;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
  }

  @override
  void didUpdateWidget(covariant GoalCoinCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.title != widget.goal.title && !_isEditingTitle) {
      _titleController.text = widget.goal.title;
    }
  }

  void _showEditTargetDialog() {
    final controller = TextEditingController(text: widget.goal.targetAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change Target Amount', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Magkano ang target goal mo?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: controller.text.isNotEmpty ? '₱ ' : null,
                prefixStyle: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold),
                hintText: '₱ 50,000',
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
              final newTarget = double.tryParse(clean) ?? widget.goal.targetAmount;
              if (newTarget > 0) {
                widget.onTargetChanged(newTarget);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.goal.progressRatio;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkKhaki, // #373D20 Dark Khaki from user sketch!
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.drySage.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Inline Renameable Goal Name (NO TARGET DATE)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _isEditingTitle
                  ? Expanded(
                      child: TextField(
                        controller: _titleController,
                        autofocus: true,
                        style: const TextStyle(
                          color: AppColors.whiteSmoke,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.drySage),
                          ),
                        ),
                        onSubmitted: (val) {
                          setState(() => _isEditingTitle = false);
                          widget.onTitleChanged(val.trim().isEmpty ? 'UNTITLED GOAL' : val.trim());
                        },
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _isEditingTitle = true),
                      child: Row(
                        children: [
                          Text(
                            _titleController.text.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.whiteSmoke,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, color: AppColors.drySage, size: 15),
                        ],
                      ),
                    ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.drySage,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Centerpiece: Tactile Coin Graphic with Radial Fill
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.drySage),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.drySage, Color(0xFF9EA573)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '₱',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkKhaki,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Bottom: Progress Numbers and Bar (Tap target to edit target amount)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saved', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: _showEditTargetDialog,
                child: Row(
                  children: [
                    Text(
                      '₱${widget.goal.currentAmount.toStringAsFixed(0)} / ₱${widget.goal.targetAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.whiteSmoke,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.edit_outlined, color: AppColors.drySage, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.drySage),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
