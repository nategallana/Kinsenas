import 'package:flutter/material.dart';
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
        backgroundColor: const Color(0xFF14151B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change Target Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Magkano ang target goal mo?', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
              final clean = controller.text.replaceAll(',', '').replaceAll(' ', '').trim();
              final newTarget = double.tryParse(clean) ?? widget.goal.targetAmount;
              if (newTarget > 0) {
                widget.onTargetChanged(newTarget);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        color: const Color(0xFF1A2219), // Refined deep forest sage
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 20,
            offset: Offset(0, 10),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF34D399)),
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
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, color: Colors.white70, size: 15),
                        ],
                      ),
                    ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Centerpiece: Tactile Coin Graphic with Radial Fill (Champagne gold & mint)
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFE8D08D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '₱',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1C1917),
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
              const Text('Saved', style: TextStyle(color: Colors.white60, fontSize: 13)),
              GestureDetector(
                onTap: _showEditTargetDialog,
                child: Row(
                  children: [
                    Text(
                      '₱${widget.goal.currentAmount.toStringAsFixed(0)} / ₱${widget.goal.targetAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.edit_outlined, color: Color(0xFF34D399), size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.black26,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
