import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/decimal_currency_formatter.dart';

class BackdatedPaymentModal extends StatefulWidget {
  final String title;
  final double remainingAmount;
  final Function(double amount, DateTime paymentDate) onConfirm;

  const BackdatedPaymentModal({
    super.key,
    required this.title,
    required this.remainingAmount,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required double remainingAmount,
    required Function(double amount, DateTime paymentDate) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => BackdatedPaymentModal(
        title: title,
        remainingAmount: remainingAmount,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<BackdatedPaymentModal> createState() => _BackdatedPaymentModalState();
}

class _BackdatedPaymentModalState extends State<BackdatedPaymentModal> {
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Automatically pre-fill the exact current balance into the input box
    final balanceStr = (widget.remainingAmount % 1 == 0)
        ? widget.remainingAmount.toInt().toString()
        : widget.remainingAmount.toStringAsFixed(2);
    _amountController = TextEditingController(text: balanceStr);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validateAmount(String value) {
    final clean = value.replaceAll(',', '').replaceAll(' ', '').trim();
    if (clean.isEmpty) {
      setState(() => _errorMessage = 'Ilagay ang halaga ng ibinayad (Enter amount)');
      return;
    }
    final entered = double.tryParse(clean);
    if (entered == null || entered <= 0) {
      setState(() => _errorMessage = 'Mangyaring maglagay ng tamang halaga');
    } else if (entered > widget.remainingAmount) {
      final maxStr = (widget.remainingAmount % 1 == 0)
          ? widget.remainingAmount.toInt().toString()
          : widget.remainingAmount.toStringAsFixed(2);
      setState(() => _errorMessage = 'Hindi maaaring lumagpas sa balanse (Max: ₱$maxStr)');
    } else {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    }
  }

  void _handleConfirm() {
    final clean = _amountController.text.replaceAll(',', '').replaceAll(' ', '').trim();
    final amt = double.tryParse(clean) ?? 0.0;

    if (amt <= 0) {
      setState(() => _errorMessage = 'Maglagay ng halagang mas mataas sa ₱0');
      return;
    }

    if (amt > widget.remainingAmount) {
      final maxStr = (widget.remainingAmount % 1 == 0)
          ? widget.remainingAmount.toInt().toString()
          : widget.remainingAmount.toStringAsFixed(2);
      setState(() => _errorMessage = 'Hindi maaaring lumagpas sa balanse (Max: ₱$maxStr)');
      return;
    }

    widget.onConfirm(amt, _selectedDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final formattedMax = (widget.remainingAmount % 1 == 0)
        ? widget.remainingAmount.toInt().toString()
        : widget.remainingAmount.toStringAsFixed(2);

    return Padding(
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Log Payment: ${widget.title}',
                  style: const TextStyle(
                    color: AppColors.whiteSmoke,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Forgot to update on time? Pick the exact date the money changed hands.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),

          // Amount Paid Header with Current Balance Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount Paid',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'Balance: ₱$formattedMax',
                style: const TextStyle(color: AppColors.drySage, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Amount Input Box (Pre-filled with balance & capped at balance)
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [DecimalCurrencyFormatter()],
            onChanged: _validateAmount,
            style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              prefixText: '₱ ',
              prefixStyle: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold, fontSize: 16),
              hintText: '0.00',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              errorText: _errorMessage,
              errorStyle: const TextStyle(color: AppColors.warningRed, fontSize: 11, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.drySage, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Date Title
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Payment Date',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.drySage,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.drySage),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          const SizedBox(height: 8),

          // Quick Presets in a clean 2x2 Grid
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPresetTile(
                      label: 'Today',
                      date: DateTime.now(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPresetTile(
                      label: 'Yesterday',
                      date: DateTime.now().subtract(const Duration(days: 1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPresetTile(
                      label: '3 Days Ago',
                      date: DateTime.now().subtract(const Duration(days: 3)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPresetTile(
                      label: 'Last Kinsenas',
                      date: DateTime.now().subtract(const Duration(days: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Confirm Button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _errorMessage != null ? AppColors.dustyOlive.withValues(alpha: 0.5) : AppColors.dustyOlive,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _handleConfirm,
            child: const Text(
              'Confirm & Update Balance',
              style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile({
    required String label,
    required DateTime date,
  }) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedDate = date),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
