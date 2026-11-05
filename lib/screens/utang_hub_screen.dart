import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../services/database_service.dart';
import '../widgets/backdated_payment_modal.dart';

enum DebtViewMode { utangKo, mayUtangSakin }

class UtangHubScreen extends StatefulWidget {
  const UtangHubScreen({super.key});

  @override
  State<UtangHubScreen> createState() => _UtangHubScreenState();
}

class _UtangHubScreenState extends State<UtangHubScreen> {
  DebtViewMode _mode = DebtViewMode.utangKo;

  final List<Debt> _mockPayables = [
    Debt(
      id: 'd1',
      title: 'SPayLater (Phone Installment)',
      type: DebtType.payable,
      totalAmount: 7500,
      remainingAmount: 5000,
      monthlyPayment: 1250,
      totalTerms: 6,
      paidTerms: 2,
      dueDayOfMonth: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Debt(
      id: 'd2',
      title: 'Kuya Mark (Personal loan)',
      type: DebtType.payable,
      totalAmount: 3000,
      remainingAmount: 3000,
      dueDayOfMonth: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  final List<Debt> _mockReceivables = [
    Debt(
      id: 'r1',
      title: 'Carl (Friday Lunch split)',
      type: DebtType.receivable,
      totalAmount: 450,
      remainingAmount: 450,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Debt(
      id: 'r2',
      title: 'Tita Ellen',
      type: DebtType.receivable,
      totalAmount: 5000,
      remainingAmount: 3500,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  void _handlePayment(Debt debt) {
    BackdatedPaymentModal.show(
      context: context,
      title: debt.title,
      remainingAmount: debt.monthlyPayment ?? debt.remainingAmount,
      onConfirm: (amount, paymentDate) async {
        final payment = DebtPayment(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          debtId: debt.id,
          amountPaid: amount,
          paymentDate: paymentDate,
        );

        await DatabaseService.instance.recordDebtPayment(payment);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF14151B),
              content: Text(
                '✓ Logged ₱${amount.toStringAsFixed(2)} paid on ${paymentDate.year}-${paymentDate.month}-${paymentDate.day}',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isUtangKo = _mode == DebtViewMode.utangKo;
    final debtsToShow = isUtangKo ? _mockPayables : _mockReceivables;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Utang Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Tactical Switch / Segmented Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF14151B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = DebtViewMode.utangKo),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isUtangKo ? const Color(0xFFF43F5E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Utang Ko (I Owe)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isUtangKo ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = DebtViewMode.mayUtangSakin),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isUtangKo ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'May Utang Sakin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !isUtangKo ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Debt Cards List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: debtsToShow.length,
              itemBuilder: (context, index) {
                final debt = debtsToShow[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14151B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(debt.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            debt.dueDayOfMonth != null ? 'Due every ${debt.dueDayOfMonth}th' : 'No fixed cutoff',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '₱${debt.remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isUtangKo ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white70, size: 22),
                            onPressed: () => _handlePayment(debt),
                            tooltip: 'Log payment with date',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
