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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.remainingAmount.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Payment: ${widget.title}',
                style: const TextStyle(
                  color: AppColors.whiteSmoke,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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

          // Amount Input
          const Text('Amount Paid', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [DecimalCurrencyFormatter()],
            style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: _amountController.text.isNotEmpty ? '₱ ' : null,
              prefixStyle: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold),
              hintText: '₱ 0.00',
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
          const SizedBox(height: 16),

          // Date Picker Tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Payment Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.drySage,
                fontWeight: FontWeight.bold,
                fontSize: 15,
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

          // Quick Presets
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                backgroundColor: AppColors.surfaceElevated,
                side: const BorderSide(color: AppColors.border),
                label: const Text('Today', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _selectedDate = DateTime.now()),
              ),
              ActionChip(
                backgroundColor: AppColors.surfaceElevated,
                side: const BorderSide(color: AppColors.border),
                label: const Text('Yesterday', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1))),
              ),
              ActionChip(
                backgroundColor: AppColors.surfaceElevated,
                side: const BorderSide(color: AppColors.border),
                label: const Text('3 Days Ago', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 3))),
              ),
              ActionChip(
                backgroundColor: AppColors.surfaceElevated,
                side: const BorderSide(color: AppColors.border),
                label: const Text('Last Kinsenas', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 15))),
              ),
            ],
          ),

          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dustyOlive,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              final cleanAmt = _amountController.text.replaceAll(',', '').replaceAll(' ', '').trim();
              final amt = double.tryParse(cleanAmt) ?? widget.remainingAmount;
              widget.onConfirm(amt, _selectedDate);
              Navigator.pop(context);
            },
            child: const Text('Confirm & Update Balance', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
