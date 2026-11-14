import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/bill.dart';
import '../services/database_service.dart';
import '../utils/decimal_currency_formatter.dart';

enum BillFilter { all, fifteenth, thirtieth, unpaid, paid }

class MgaBayarinScreen extends StatefulWidget {
  const MgaBayarinScreen({super.key});

  @override
  State<MgaBayarinScreen> createState() => _MgaBayarinScreenState();
}

class _MgaBayarinScreenState extends State<MgaBayarinScreen> {
  List<Bill> _bills = [];
  bool _isLoading = true;
  BillFilter _activeFilter = BillFilter.all;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      final bills = await DatabaseService.instance.getBills();
      if (mounted) {
        setState(() {
          _bills = bills;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePaid(Bill bill) async {
    final newStatus = !bill.isPaid;
    await DatabaseService.instance.toggleBillPaid(bill.id, newStatus);
    await _loadBills();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 2),
          content: Text(
            newStatus
                ? '✓ Namarkahang bayad na ang "${bill.title}"!'
                : 'Naibalik sa "Hindi Pa Bayad" ang "${bill.title}".',
            style: TextStyle(
              color: newStatus ? AppColors.drySage : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Burahin ang Bayarin?', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Sigurado ka bang nais mong burahin ang "${bill.title}"?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warningRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Burahin', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.deleteBill(bill.id);
      await _loadBills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('✓ Nabura ang "${bill.title}"', style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold)),
          ),
        );
      }
    }
  }

  void _showAddEditBillModal({Bill? editBill}) {
    final titleController = TextEditingController(text: editBill?.title ?? '');
    final amountController = TextEditingController(
      text: editBill != null ? editBill.amount.toStringAsFixed(2) : '',
    );
    final dueDayController = TextEditingController(
      text: editBill != null ? editBill.dueDay.toString() : '15',
    );

    BillCategory selectedCategory = editBill?.category ?? BillCategory.electricity;
    BillCutoff selectedCutoff = editBill?.cutoff ?? BillCutoff.fifteenth;

    final quickSuggestions = [
      {'title': 'Meralco', 'cat': BillCategory.electricity},
      {'title': 'Maynilad / Tubig', 'cat': BillCategory.water},
      {'title': 'Converge / PLDT', 'cat': BillCategory.internet},
      {'title': 'Upa sa Bahay', 'cat': BillCategory.rent},
      {'title': 'Netflix', 'cat': BillCategory.subscription},
      {'title': 'Spotify', 'cat': BillCategory.subscription},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.dustyOlive.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.drySage, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            editBill == null ? 'Magdagdag ng Bayarin' : 'I-edit ang Bayarin',
                            style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Quick Suggestion Chips (only on new)
                  if (editBill == null) ...[
                    const Text('Mabilisang Pagpipilian (Quick Pick):', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: quickSuggestions.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              backgroundColor: AppColors.surfaceElevated,
                              side: const BorderSide(color: AppColors.border),
                              label: Text(
                                item['title'] as String,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  titleController.text = item['title'] as String;
                                  selectedCategory = item['cat'] as BillCategory;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Bill Title
                  const Text('Pangalan ng Bayarin (Bill Name)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'hal. Meralco, Wifi, Upa...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.drySage)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Amount
                  const Text('Halaga (Amount Due)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [DecimalCurrencyFormatter()],
                    style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      prefixStyle: const TextStyle(color: AppColors.drySage, fontSize: 16, fontWeight: FontWeight.bold),
                      hintText: '0.00',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.drySage)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Category Selector
                  const Text('Kategorya (Category)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BillCategory.values.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(cat), size: 14, color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(cat.displayName, style: TextStyle(color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        selectedColor: AppColors.dustyOlive,
                        backgroundColor: AppColors.surfaceElevated,
                        side: BorderSide(color: isSelected ? AppColors.drySage : AppColors.border),
                        onSelected: (_) => setModalState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Kinsenas Cutoff Allocation
                  const Text('Kailan Babayaran? (Kinsenas Cutoff)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _buildCutoffOption('15th Cutoff', BillCutoff.fifteenth, selectedCutoff, (c) => setModalState(() => selectedCutoff = c)),
                        _buildCutoffOption('30th Cutoff', BillCutoff.thirtieth, selectedCutoff, (c) => setModalState(() => selectedCutoff = c)),
                        _buildCutoffOption('Hati (50/50)', BillCutoff.bothSplit, selectedCutoff, (c) => setModalState(() => selectedCutoff = c)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Due Day of Month
                  const Text('Petsa ng Due Date (Araw ng Buwan: 1 - 31)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: dueDayController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'hal. 15',
                      suffixText: 'ng buwan',
                      suffixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.drySage)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Submit Button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dustyOlive,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final cleanAmt = amountController.text.replaceAll(',', '').replaceAll(' ', '').trim();
                      final amt = double.tryParse(cleanAmt) ?? 0.0;
                      if (amt <= 0) return;

                      final dueDay = int.tryParse(dueDayController.text.trim())?.clamp(1, 31) ?? 15;

                      Navigator.pop(ctx);

                      if (editBill == null) {
                        final newBill = Bill(
                          id: 'bill_${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          amount: amt,
                          category: selectedCategory,
                          dueDay: dueDay,
                          cutoff: selectedCutoff,
                          isPaid: false,
                          createdAt: DateTime.now(),
                        );
                        await DatabaseService.instance.addBill(newBill);
                      } else {
                        final updated = editBill.copyWith(
                          title: title,
                          amount: amt,
                          category: selectedCategory,
                          dueDay: dueDay,
                          cutoff: selectedCutoff,
                        );
                        await DatabaseService.instance.updateBill(updated);
                      }

                      await _loadBills();
                    },
                    child: Text(
                      editBill == null ? 'Idagdag ang Bayarin' : 'I-save ang Pagbabago',
                      style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCutoffOption(
    String label,
    BillCutoff cutoff,
    BillCutoff selected,
    ValueChanged<BillCutoff> onSelect,
  ) {
    final isSelected = cutoff == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(cutoff),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.dustyOlive : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  List<Bill> _getFilteredBills() {
    switch (_activeFilter) {
      case BillFilter.all:
        return _bills;
      case BillFilter.fifteenth:
        return _bills.where((b) => b.cutoff == BillCutoff.fifteenth || b.cutoff == BillCutoff.bothSplit).toList();
      case BillFilter.thirtieth:
        return _bills.where((b) => b.cutoff == BillCutoff.thirtieth || b.cutoff == BillCutoff.bothSplit).toList();
      case BillFilter.unpaid:
        return _bills.where((b) => !b.isPaid).toList();
      case BillFilter.paid:
        return _bills.where((b) => b.isPaid).toList();
    }
  }

  static IconData _getCategoryIcon(BillCategory cat) {
    switch (cat) {
      case BillCategory.electricity:
        return Icons.bolt_rounded;
      case BillCategory.water:
        return Icons.water_drop_rounded;
      case BillCategory.internet:
        return Icons.wifi_rounded;
      case BillCategory.rent:
        return Icons.home_work_rounded;
      case BillCategory.subscription:
        return Icons.subscriptions_rounded;
      case BillCategory.other:
        return Icons.receipt_long_rounded;
    }
  }

  static Color _getCategoryColor(BillCategory cat) {
    switch (cat) {
      case BillCategory.electricity:
        return const Color(0xFFE09F3E);
      case BillCategory.water:
        return const Color(0xFF4A90E2);
      case BillCategory.internet:
        return AppColors.drySage;
      case BillCategory.rent:
        return AppColors.ashBrown;
      case BillCategory.subscription:
        return AppColors.warningRed;
      case BillCategory.other:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalBills = 0.0;
    double total15 = 0.0;
    double total30 = 0.0;
    double totalPaid = 0.0;
    int paidCount = 0;

    for (var b in _bills) {
      totalBills += b.amount;
      if (b.cutoff == BillCutoff.fifteenth) {
        total15 += b.amount;
      } else if (b.cutoff == BillCutoff.thirtieth) {
        total30 += b.amount;
      } else {
        total15 += (b.amount / 2);
        total30 += (b.amount / 2);
      }

      if (b.isPaid) {
        totalPaid += b.amount;
        paidCount++;
      }
    }

    final double paidPct = totalBills > 0 ? (totalPaid / totalBills).clamp(0.0, 1.0) : 0.0;
    final filteredBills = _getFilteredBills();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mga Bayarin',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteSmoke),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dustyOlive,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _showAddEditBillModal(),
              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.whiteSmoke),
              label: const Text(
                'Magdagdag',
                style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.drySage))
          : RefreshIndicator(
              color: AppColors.drySage,
              backgroundColor: AppColors.surface,
              onRefresh: _loadBills,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Total Monthly Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KABUUANG MGA BAYARIN (MONTHLY BILLS)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₱${totalBills.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.whiteSmoke,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cutoff Split Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderMuted),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('15th Cutoff', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('₱${total15.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.drySage, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderMuted),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('30th Cutoff', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('₱${total30.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.drySage, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Paid Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bayad na: $paidCount of ${_bills.length} (${(paidPct * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₱${totalPaid.toStringAsFixed(2)} / ₱${totalBills.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.drySage, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: paidPct,
                            minHeight: 6,
                            backgroundColor: AppColors.inputFill,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.dustyOlive),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Lahat (${_bills.length})', BillFilter.all),
                        _buildFilterChip('15th Cutoff', BillFilter.fifteenth),
                        _buildFilterChip('30th Cutoff', BillFilter.thirtieth),
                        _buildFilterChip('Di Pa Bayad', BillFilter.unpaid),
                        _buildFilterChip('Bayad Na', BillFilter.paid),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bills List or Empty State
                  if (filteredBills.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.dustyOlive.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.drySage, size: 28),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Walang Nakalistang Bayarin',
                            style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ilista ang mga buwanang bayarin tulad ng kuryente, tubig, upa, o internet para madaling i-budget sa kinsenas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.dustyOlive,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showAddEditBillModal(),
                            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.whiteSmoke),
                            label: const Text('Magdagdag ng Bayarin', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredBills.map((bill) => _buildBillCard(bill)),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, BillFilter filter) {
    final isSelected = _activeFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        selectedColor: AppColors.dustyOlive,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: isSelected ? AppColors.drySage : AppColors.border),
        onSelected: (_) => setState(() => _activeFilter = filter),
      ),
    );
  }

  Widget _buildBillCard(Bill bill) {
    final cutoffLabel = bill.cutoff == BillCutoff.fifteenth
        ? '15th Cutoff'
        : (bill.cutoff == BillCutoff.thirtieth ? '30th Cutoff' : 'Hati (50/50)');

    final categoryColor = _getCategoryColor(bill.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bill.isPaid ? AppColors.dustyOlive.withValues(alpha: 0.5) : AppColors.border,
          width: bill.isPaid ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Category Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
            ),
            child: Icon(_getCategoryIcon(bill.category), color: categoryColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Bill Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bill.title,
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: bill.isPaid ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Due: ${bill.dueDay}th • $cutoffLabel',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount and Status Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${bill.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: bill.isPaid ? AppColors.drySage : AppColors.whiteSmoke,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tactile Pay/Unpay button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _togglePaid(bill),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bill.isPaid
                              ? AppColors.dustyOlive.withValues(alpha: 0.3)
                              : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: bill.isPaid ? AppColors.drySage : AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              bill.isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 13,
                              color: bill.isPaid ? AppColors.drySage : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bill.isPaid ? 'Bayad Na' : 'Bayaran',
                              style: TextStyle(
                                color: bill.isPaid ? AppColors.drySage : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Edit Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showAddEditBillModal(editBill: bill),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Delete Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _deleteBill(bill),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0x20E07A5F),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x60E07A5F)),
                        ),
                        child: const Center(
                          child: Icon(Icons.delete_outline_rounded, color: AppColors.warningRed, size: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
