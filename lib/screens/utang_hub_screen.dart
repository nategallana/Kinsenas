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
  List<Debt> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    var debts = await DatabaseService.instance.getDebts();

    // If database is empty on first run, seed initial records
    if (debts.isEmpty) {
      final initialDebts = [
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

      for (var d in initialDebts) {
        await DatabaseService.instance.insertDebt(d);
      }
      debts = await DatabaseService.instance.getDebts();
    }

    if (mounted) {
      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    }
  }

  void _showAddDebtModal() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final monthlyController = TextEditingController();
    final dueDayController = TextEditingController();
    DebtType selectedType = (_mode == DebtViewMode.utangKo) ? DebtType.payable : DebtType.receivable;
    DateTime borrowedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14151B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isPayable = selectedType == DebtType.payable;

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPayable ? 'Magdagdag ng Utang Ko' : 'Magdagdag ng Pautang',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Type Toggle inside modal
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0C0F),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedType = DebtType.payable),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPayable ? const Color(0xFFF43F5E) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Utang Ko (I Owe)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isPayable ? Colors.white : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedType = DebtType.receivable),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isPayable ? const Color(0xFF10B981) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'May Utang Sakin',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !isPayable ? Colors.white : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Name / Entity
                    const Text('Pangalan o Institusyon', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: isPayable ? 'Hal. SPayLater, Kuya Mark, BPI' : 'Hal. Carl, Tita Ellen',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF0B0C0F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Total Amount
                    const Text('Kabuuang Halaga (Total Amount)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
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

                    const SizedBox(height: 14),

                    // Due Day (e.g. 15 or 30)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due Day (Araw ng Sahod)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: dueDayController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Hal. 15 o 30',
                                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly Bill (BNPL)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: monthlyController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  prefixText: '₱ ',
                                  prefixStyle: const TextStyle(color: Colors.white70),
                                  hintText: 'Opsyonal',
                                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Borrowed Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Petsa Hiniram (Date Borrowed)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      subtitle: Text(
                        '${borrowedDate.year}-${borrowedDate.month.toString().padLeft(2, '0')}-${borrowedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: borrowedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => borrowedDate = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isPayable ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final total = double.tryParse(amountController.text) ?? 0.0;
                        if (title.isEmpty || total <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mangyaring ilagay ang pangalan at tamang halaga.')),
                          );
                          return;
                        }

                        final newDebt = Debt(
                          id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          type: selectedType,
                          totalAmount: total,
                          remainingAmount: total,
                          monthlyPayment: double.tryParse(monthlyController.text),
                          dueDayOfMonth: int.tryParse(dueDayController.text),
                          createdAt: borrowedDate,
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);

                        await DatabaseService.instance.insertDebt(newDebt);
                        _loadDebts();

                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF14151B),
                            content: Text('✓ Naidagdag na si "$title"!', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                      child: Text(
                        isPayable ? 'I-save ang Utang Ko' : 'I-save ang Pautang',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
        _loadDebts();

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

  void _deleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14151B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Burahin ang record?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Sigurado ka bang nais mong tanggalin si "${debt.title}"?', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.deleteDebt(debt.id);
              _loadDebts();
            },
            child: const Text('Burahin', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isUtangKo = _mode == DebtViewMode.utangKo;
    final debtsToShow = _debts.where((d) => isUtangKo ? d.type == DebtType.payable : d.type == DebtType.receivable).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Utang Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            tooltip: 'Magdagdag ng Utang',
            onPressed: _showAddDebtModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isUtangKo ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          isUtangKo ? 'Utang Ko' : 'Pautang',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: _showAddDebtModal,
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

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF43F5E)))
                : debtsToShow.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              isUtangKo ? 'Walang utang na nakalista! 🎉' : 'Walang may utang sa iyo.',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
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
                                Expanded(
                                  child: Column(
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
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white70, size: 22),
                                      onPressed: () => _handlePayment(debt),
                                      tooltip: 'Log payment with date',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 18),
                                      onPressed: () => _deleteDebt(debt),
                                      tooltip: 'Delete',
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
