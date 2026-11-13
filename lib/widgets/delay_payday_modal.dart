import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class DelayPaydayModal extends StatefulWidget {
  final DateTime currentScheduledDate;
  final DateTime? existingDelayedDate;
  final Function(DateTime newDate) onConfirmDelay;
  final VoidCallback onResetToRegular;

  const DelayPaydayModal({
    super.key,
    required this.currentScheduledDate,
    required this.existingDelayedDate,
    required this.onConfirmDelay,
    required this.onResetToRegular,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTime currentScheduledDate,
    required DateTime? existingDelayedDate,
    required Function(DateTime newDate) onConfirmDelay,
    required VoidCallback onResetToRegular,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DelayPaydayModal(
        currentScheduledDate: currentScheduledDate,
        existingDelayedDate: existingDelayedDate,
        onConfirmDelay: onConfirmDelay,
        onResetToRegular: onResetToRegular,
      ),
    );
  }

  @override
  State<DelayPaydayModal> createState() => _DelayPaydayModalState();
}

class _DelayPaydayModalState extends State<DelayPaydayModal> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (widget.existingDelayedDate != null &&
        widget.existingDelayedDate!.isAfter(today.subtract(const Duration(days: 1)))) {
      _selectedDate = widget.existingDelayedDate!;
    } else {
      // Default to tomorrow or next day
      _selectedDate = today.add(const Duration(days: 1));
    }
  }

  DateTime _getNextMonday(DateTime from) {
    // 1 = Monday, 7 = Sunday
    int daysUntilMonday = (DateTime.monday - from.weekday) % 7;
    if (daysUntilMonday <= 0) {
      daysUntilMonday += 7;
    }
    return from.add(Duration(days: daysUntilMonday));
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? _selectedDate : today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.dustyOlive,
              onPrimary: AppColors.whiteSmoke,
              surface: AppColors.surface,
              onSurface: AppColors.whiteSmoke,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysDiff = _selectedDate.difference(today).inDays;

    final plus1 = today.add(const Duration(days: 1));
    final plus2 = today.add(const Duration(days: 2));
    final plus3 = today.add(const Duration(days: 3));
    final nextMon = _getNextMonday(today);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dustyOlive.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.drySage, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Na-delay ang Sahod?',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'I-adjust ang countdown at survival budget',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Informational Alert
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderMuted),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.drySage, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hindi magagalaw ang regular settings mo. Pansamantalang ia-adjust lang ang cutoff na ito.',
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Selected target display
          Text(
            'Inaasahang Payout: ${DateFormat('MMMM d, y (EEEE)').format(_selectedDate)}',
            style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            daysDiff == 1 ? 'Papasok bukas (1 araw na lang)' : 'Papasok sa $daysDiff araw mula ngayon',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),

          const SizedBox(height: 14),

          // Quick Presets Grid (2x2)
          Row(
            children: [
              Expanded(
                child: _buildPresetCard(
                  label: '+1 Araw (Bukas)',
                  subtext: DateFormat('MMM d').format(plus1),
                  target: plus1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetCard(
                  label: '+2 Araw',
                  subtext: DateFormat('MMM d').format(plus2),
                  target: plus2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPresetCard(
                  label: '+3 Araw',
                  subtext: DateFormat('MMM d').format(plus3),
                  target: plus3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetCard(
                  label: 'Hanggang Lunes',
                  subtext: DateFormat('MMM d').format(nextMon),
                  target: nextMon,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Custom Date Picker Tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickCustomDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppColors.drySage, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Pumili ng Ibang Petsa sa Kalendaryo',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Confirm Button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dustyOlive,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              widget.onConfirmDelay(_selectedDate);
              Navigator.pop(context);
            },
            child: const Text(
              'I-save ang Bagong Petsa',
              style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),

          // Reset to regular schedule if already delayed
          if (widget.existingDelayedDate != null) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  widget.onResetToRegular();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.restart_alt_rounded, color: AppColors.warningRed, size: 16),
                label: const Text(
                  'Ibalik sa Regular Schedule',
                  style: TextStyle(color: AppColors.warningRed, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetCard({
    required String label,
    required String subtext,
    required DateTime target,
  }) {
    final isSelected = _selectedDate.year == target.year &&
        _selectedDate.month == target.month &&
        _selectedDate.day == target.day;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedDate = target),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.dustyOlive.withValues(alpha: 0.3)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.drySage : AppColors.border,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  color: isSelected ? AppColors.drySage : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
