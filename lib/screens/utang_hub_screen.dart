import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    final debts = await DatabaseService.instance.getDebts();

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
      backgroundColor: AppColors.surface,
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
                          style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Type Toggle inside modal
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
                              onTap: () => setModalState(() => selectedType = DebtType.payable),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPayable ? AppColors.ashBrown : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Utang Ko (I Owe)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isPayable ? AppColors.whiteSmoke : AppColors.textSecondary,
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
                                  color: !isPayable ? AppColors.dustyOlive : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'May Utang Sakin',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !isPayable ? AppColors.whiteSmoke : AppColors.textSecondary,
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
                    const Text('Pangalan o Institusyon', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: isPayable ? 'Hal. SPayLater, Kuya Mark, BPI' : 'Hal. Carl, Tita Ellen',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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

                    const SizedBox(height: 14),

                    // Total Amount
                    const Text('Kabuuang Halaga (Total Amount)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: amountController.text.isNotEmpty ? '₱ ' : null,
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

                    const SizedBox(height: 14),

                    // Due Day (e.g. 15 or 30)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due Day (Araw ng Sahod)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: dueDayController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Hal. 15 o 30',
                                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly Bill (BNPL)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: monthlyController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  prefixText: monthlyController.text.isNotEmpty ? '₱ ' : null,
                                  prefixStyle: const TextStyle(color: AppColors.textSecondary),
                                  hintText: 'Opsyonal (₱ 0.00)',
                                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Borrowed Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Petsa Hiniram (Date Borrowed)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${borrowedDate.year}-${borrowedDate.month.toString().padLeft(2, '0')}-${borrowedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded, color: AppColors.drySage, size: 20),
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
                        backgroundColor: isPayable ? AppColors.ashBrown : AppColors.dustyOlive,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final cleanTotal = amountController.text.replaceAll(',', '').replaceAll(' ', '').trim();
                        final total = double.tryParse(cleanTotal) ?? 0.0;
                        if (title.isEmpty || total <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mangyaring ilagay ang pangalan at tamang halaga.')),
                          );
                          return;
                        }

                        final cleanMonthly = monthlyController.text.replaceAll(',', '').replaceAll(' ', '').trim();
                        final newDebt = Debt(
                          id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          type: selectedType,
                          totalAmount: total,
                          remainingAmount: total,
                          monthlyPayment: double.tryParse(cleanMonthly),
                          dueDayOfMonth: int.tryParse(dueDayController.text),
                          createdAt: borrowedDate,
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);

                        await DatabaseService.instance.insertDebt(newDebt);
                        _loadDebts();

                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surface,
                            content: Text('✓ Naidagdag na si "$title"!', style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                      child: Text(
                        isPayable ? 'I-save ang Utang Ko' : 'I-save ang Pautang',
                        style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 14),
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
              backgroundColor: AppColors.surface,
              content: Text(
                '✓ Logged ₱${amount.toStringAsFixed(2)} paid on ${paymentDate.year}-${paymentDate.month}-${paymentDate.day}',
                style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Burahin ang record?', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Sigurado ka bang nais mong tanggalin si "${debt.title}"?', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warningRed),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Utang Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteSmoke)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isUtangKo ? AppColors.ashBrown : AppColors.dustyOlive,
        foregroundColor: AppColors.whiteSmoke,
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = DebtViewMode.utangKo),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isUtangKo ? AppColors.ashBrown : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Utang Ko (I Owe)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isUtangKo ? AppColors.whiteSmoke : AppColors.textSecondary,
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
                          color: !isUtangKo ? AppColors.dustyOlive : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'May Utang Sakin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !isUtangKo ? AppColors.whiteSmoke : AppColors.textSecondary,
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.drySage))
                : debtsToShow.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              isUtangKo ? 'Walang utang na nakalista! 🎉' : 'Walang may utang sa iyo.',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(debt.title, style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(
                                        debt.dueDayOfMonth != null ? 'Due every ${debt.dueDayOfMonth}th' : 'No fixed cutoff',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '₱${debt.remainingAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isUtangKo ? AppColors.ashBrown : AppColors.drySage,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.drySage, size: 22),
                                      onPressed: () => _handlePayment(debt),
                                      tooltip: 'Log payment with date',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
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
