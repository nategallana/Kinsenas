import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF14151B),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Forgot to update on time? Pick the exact date the money changed hands.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 18),

          // Amount Input
          const Text('Amount Paid', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: 16),

          // Date Picker Tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Payment Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
            subtitle: Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Color(0xFFF43F5E),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            trailing: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
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
                backgroundColor: const Color(0xFF1E2028),
                side: const BorderSide(color: Colors.white10),
                label: const Text('Today', style: TextStyle(color: Colors.white70, fontSize: 11)),
                onPressed: () => setState(() => _selectedDate = DateTime.now()),
              ),
              ActionChip(
                backgroundColor: const Color(0xFF1E2028),
                side: const BorderSide(color: Colors.white10),
                label: const Text('Yesterday', style: TextStyle(color: Colors.white70, fontSize: 11)),
                onPressed: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1))),
              ),
              ActionChip(
                backgroundColor: const Color(0xFF1E2028),
                side: const BorderSide(color: Colors.white10),
                label: const Text('3 Days Ago', style: TextStyle(color: Colors.white70, fontSize: 11)),
                onPressed: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 3))),
              ),
              ActionChip(
                backgroundColor: const Color(0xFF1E2028),
                side: const BorderSide(color: Colors.white10),
                label: const Text('Last Kinsenas', style: TextStyle(color: Colors.white70, fontSize: 11)),
                onPressed: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 15))),
              ),
            ],
          ),

          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              final cleanAmt = _amountController.text.replaceAll(',', '').replaceAll(' ', '').trim();
              final amt = double.tryParse(cleanAmt) ?? widget.remainingAmount;
              widget.onConfirm(amt, _selectedDate);
              Navigator.pop(context);
            },
            child: const Text('Confirm & Update Balance', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
