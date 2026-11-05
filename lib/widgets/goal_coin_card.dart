import 'package:flutter/material.dart';
import '../models/goal.dart';

class GoalCoinCard extends StatefulWidget {
  final Goal goal;
  final Function(String newTitle) onTitleChanged;
  final VoidCallback onDeposit;

  const GoalCoinCard({
    super.key,
    required this.goal,
    required this.onTitleChanged,
    required this.onDeposit,
  });

  @override
  State<GoalCoinCard> createState() => _GoalCoinCardState();
}

class _GoalCoinCardState extends State<GoalCoinCard> {
  late TextEditingController _titleController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
  }

  @override
  void didUpdateWidget(covariant GoalCoinCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.title != widget.goal.title && !_isEditing) {
      _titleController.text = widget.goal.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.goal.progressRatio;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3929), // Refined forest/olive from sketch
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
              _isEditing
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
                            borderSide: BorderSide(color: Color(0xFFF59E0B)),
                          ),
                        ),
                        onSubmitted: (val) {
                          setState(() => _isEditing = false);
                          widget.onTitleChanged(val.trim().isEmpty ? 'UNTITLED GOAL' : val.trim());
                        },
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
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
                  color: Color(0xFFFBBF24),
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
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
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

          // Bottom: Progress Numbers and Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saved', style: TextStyle(color: Colors.white60, fontSize: 13)),
              Text(
                '₱${widget.goal.currentAmount.toStringAsFixed(0)} / ₱${widget.goal.targetAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.black26,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
