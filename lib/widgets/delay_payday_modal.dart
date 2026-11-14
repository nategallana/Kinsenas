import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

enum PaydayAdjustMode { early, delayed }

class DelayPaydayModal extends StatefulWidget {
  final DateTime currentScheduledDate;
  final DateTime? existingDelayedDate;
  final PaydayAdjustMode initialMode;
  final Function(DateTime newDate, bool isEarly) onConfirmDate;
  final VoidCallback onInstantReceived;
  final VoidCallback onResetToRegular;

  const DelayPaydayModal({
    super.key,
    required this.currentScheduledDate,
    required this.existingDelayedDate,
    this.initialMode = PaydayAdjustMode.delayed,
    required this.onConfirmDate,
    required this.onInstantReceived,
    required this.onResetToRegular,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTime currentScheduledDate,
    required DateTime? existingDelayedDate,
    PaydayAdjustMode initialMode = PaydayAdjustMode.delayed,
    required Function(DateTime newDate, bool isEarly) onConfirmDate,
    required VoidCallback onInstantReceived,
    required VoidCallback onResetToRegular,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DelayPaydayModal(
        currentScheduledDate: currentScheduledDate,
        existingDelayedDate: existingDelayedDate,
        initialMode: initialMode,
        onConfirmDate: onConfirmDate,
        onInstantReceived: onInstantReceived,
        onResetToRegular: onResetToRegular,
      ),
    );
  }

  @override
  State<DelayPaydayModal> createState() => _DelayPaydayModalState();
}

class _DelayPaydayModalState extends State<DelayPaydayModal> {
  late PaydayAdjustMode _mode;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (widget.existingDelayedDate != null) {
      _selectedDate = widget.existingDelayedDate!;
      if (_selectedDate.isBefore(widget.currentScheduledDate)) {
        _mode = PaydayAdjustMode.early;
      } else {
        _mode = PaydayAdjustMode.delayed;
      }
    } else {
      if (_mode == PaydayAdjustMode.early) {
        _selectedDate = today;
      } else {
        _selectedDate = today.add(const Duration(days: 1));
      }
    }
  }

  DateTime _getNextMonday(DateTime from) {
    int daysUntilMonday = (DateTime.monday - from.weekday) % 7;
    if (daysUntilMonday <= 0) {
      daysUntilMonday += 7;
    }
    return from.add(Duration(days: daysUntilMonday));
  }

  DateTime _getPreviousFriday(DateTime from) {
    int daysAgo = (from.weekday - DateTime.friday) % 7;
    if (daysAgo <= 0) {
      daysAgo += 7;
    }
    return from.subtract(Duration(days: daysAgo));
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDate = _mode == PaydayAdjustMode.early
        ? today.subtract(const Duration(days: 10))
        : today.add(const Duration(days: 1));

    final lastDate = _mode == PaydayAdjustMode.early
        ? widget.currentScheduledDate
        : today.add(const Duration(days: 35));

    final initial = _selectedDate.isBefore(firstDate)
        ? firstDate
        : (_selectedDate.isAfter(lastDate) ? lastDate : _selectedDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
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

    final isEarlyMode = _mode == PaydayAdjustMode.early;

    // Presets for Delayed
    final plus1 = today.add(const Duration(days: 1));
    final plus2 = today.add(const Duration(days: 2));
    final plus3 = today.add(const Duration(days: 3));
    final nextMon = _getNextMonday(today);

    // Presets for Early
    final prevFri = _getPreviousFriday(widget.currentScheduledDate);
    final minus1 = widget.currentScheduledDate.subtract(const Duration(days: 1));
    final minus2 = widget.currentScheduledDate.subtract(const Duration(days: 2));

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
                  color: (isEarlyMode ? AppColors.dustyOlive : const Color(0x30E07A5F)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isEarlyMode ? Icons.bolt_rounded : Icons.hourglass_bottom_rounded,
                  color: isEarlyMode ? AppColors.drySage : AppColors.warningRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEarlyMode ? 'Maagang Sahod (Early Payout)' : 'Na-delay ang Sahod?',
                      style: const TextStyle(
                        color: AppColors.whiteSmoke,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEarlyMode
                          ? 'I-record kung pumasok nang maaga ang payout'
                          : 'I-adjust ang countdown at survival budget',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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

          const SizedBox(height: 14),

          // Mode Switcher (Early vs Delayed)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _mode = PaydayAdjustMode.early;
                        _selectedDate = today;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isEarlyMode ? AppColors.dustyOlive : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: isEarlyMode ? AppColors.whiteSmoke : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Maaga (Early)',
                            style: TextStyle(
                              color: isEarlyMode ? AppColors.whiteSmoke : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _mode = PaydayAdjustMode.delayed;
                        _selectedDate = today.add(const Duration(days: 1));
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isEarlyMode ? const Color(0x35E07A5F) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_bottom_rounded,
                            size: 14,
                            color: !isEarlyMode ? AppColors.warningRed : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Delayed (Na-delay)',
                            style: TextStyle(
                              color: !isEarlyMode ? AppColors.warningRed : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Instant button if received today in early mode
          if (isEarlyMode) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dustyOlive,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onInstantReceived();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_rounded, color: AppColors.whiteSmoke, size: 18),
              label: const Text(
                'Natanggap Ko Na Ngayong Araw! 🎉',
                style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'o pumili ng maagang petsa sa ibaba:',
                style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 11),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Selected target display
          Text(
            'Inaasahang Petsa: ${DateFormat('MMMM d, y (EEEE)').format(_selectedDate)}',
            style: TextStyle(
              color: isEarlyMode ? AppColors.drySage : AppColors.warningRed,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            daysDiff == 0
                ? 'Nakatakda ngayong araw'
                : (daysDiff > 0
                    ? 'Papasok sa $daysDiff araw mula ngayon'
                    : 'Mas maaga ng ${-daysDiff} araw'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),

          const SizedBox(height: 12),

          // Presets Grid
          if (isEarlyMode) ...[
            Row(
              children: [
                Expanded(
                  child: _buildPresetCard(
                    label: 'Ngayong Araw',
                    subtext: DateFormat('MMM d').format(today),
                    target: today,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPresetCard(
                    label: 'Bago Mag-Weekend',
                    subtext: DateFormat('MMM d (Biyernes)').format(prevFri),
                    target: prevFri,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPresetCard(
                    label: '-1 Araw Bago Payout',
                    subtext: DateFormat('MMM d').format(minus1),
                    target: minus1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPresetCard(
                    label: '-2 Araw Bago Payout',
                    subtext: DateFormat('MMM d').format(minus2),
                    target: minus2,
                  ),
                ),
              ],
            ),
          ] else ...[
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
          ],

          const SizedBox(height: 10),

          // Custom Date Picker Tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickCustomDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

          const SizedBox(height: 18),

          // Confirm Button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isEarlyMode ? AppColors.dustyOlive : const Color(0xFFC8684D),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              widget.onConfirmDate(_selectedDate, isEarlyMode);
              Navigator.pop(context);
            },
            child: Text(
              isEarlyMode ? 'I-save ang Maagang Petsa' : 'I-save ang Bagong Petsa',
              style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          // Reset to regular schedule if already adjusted
          if (widget.existingDelayedDate != null) ...[
            const SizedBox(height: 8),
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

    final isEarly = _mode == PaydayAdjustMode.early;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedDate = target),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isEarly ? AppColors.dustyOlive.withValues(alpha: 0.35) : const Color(0x30E07A5F))
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isEarly ? AppColors.drySage : AppColors.warningRed)
                  : AppColors.border,
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
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  color: isSelected
                      ? (isEarly ? AppColors.drySage : AppColors.warningRed)
                      : AppColors.textMuted,
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
