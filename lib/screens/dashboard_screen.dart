import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/database_service.dart';
import '../models/debt.dart';
import '../widgets/delay_payday_modal.dart';
import '../utils/decimal_currency_formatter.dart';
import 'settings_screen.dart';

class KinsenasCycleInfo {
  final DateTime targetDate;
  final int daysLeft;
  final bool isPaydayToday;
  final bool isDelayed;
  final bool isEarly;
  final bool isAwaitingConfirmation;
  final String title;
  final String subtitle;
  final String cycleKey;

  KinsenasCycleInfo({
    required this.targetDate,
    required this.daysLeft,
    required this.isPaydayToday,
    required this.isDelayed,
    this.isEarly = false,
    required this.isAwaitingConfirmation,
    required this.title,
    required this.subtitle,
    required this.cycleKey,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  double _totalCash = 0.0;
  double _totalPayables = 0.0;
  double _totalReceivables = 0.0;
  String _paydayCycle = '15_30';
  bool _isLoading = true;

  DateTime? _delayedUntilDate;
  String? _lastReceivedCycle;
  bool _showPetsaDePeligroDetails = true;
  double _savingsTarget = 200.0;
  Set<String> _checkedHacks = {};

  Future<void> loadDashboardData() => _loadDashboardData();

  final List<Map<String, dynamic>> _tipidHacks = const [
    {
      'id': 'baon',
      'title': 'Magbaon ng Pagkain / Mag-saing',
      'desc': 'Magbaon ng lunch o itlog imbes na mag-Grab o kumain sa labas.',
      'savings': 180.0,
      'icon': Icons.lunch_dining_rounded,
      'color': Color(0xFFE09F3E),
    },
    {
      'id': 'water',
      'title': 'Sariling Tumbler / No Milk Tea',
      'desc': 'Mag-refill ng tubig at iwas muna sa milk tea at iced coffee.',
      'savings': 120.0,
      'icon': Icons.local_drink_rounded,
      'color': Color(0xFF4A90E2),
    },
    {
      'id': 'commute',
      'title': 'Jeep / Tren over Grab & Taxi',
      'desc': 'Sumakay sa MRT/LRT o jeep kapag may regular na biyahe.',
      'savings': 150.0,
      'icon': Icons.directions_bus_rounded,
      'color': AppColors.drySage,
    },
    {
      'id': 'cart_freeze',
      'title': 'I-freeze ang Online Shopping Carts',
      'desc': 'Iwasang mag-checkout sa Shopee/Lazada hanggang may sahod.',
      'savings': 250.0,
      'icon': Icons.shopping_cart_outlined,
      'color': AppColors.warningRed,
    },
    {
      'id': 'carinderia',
      'title': 'Carinderia Gulay at Sabaw Diskarte',
      'desc': 'Piliin ang gulay at libreng sabaw—mas mura kaysa fast food.',
      'savings': 100.0,
      'icon': Icons.soup_kitchen_rounded,
      'color': AppColors.dustyOlive,
    },
    {
      'id': 'free_transfer',
      'title': 'Libreng InstaPay / Bank Transfers',
      'desc': 'Gamitin ang mga bangko o e-wallets na walang transfer fee.',
      'savings': 25.0,
      'icon': Icons.swap_horiz_rounded,
      'color': AppColors.ashBrown,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await DatabaseService.instance.getAccounts();
      final debts = await DatabaseService.instance.getDebts();
      final prefs = await SharedPreferences.getInstance();
      final cycle = prefs.getString('payday_cycle') ?? '15_30';
      final delayedStr = prefs.getString('payday_delayed_until');
      final lastReceived = prefs.getString('payday_last_received_cycle');
      final savedTarget = prefs.getDouble('petsa_savings_target') ?? 200.0;
      final savedHacks = prefs.getStringList('petsa_checked_hacks') ?? [];

      double cash = 0.0;
      for (var a in accounts) {
        cash += a.balance;
      }

      double payables = 0.0;
      double receivables = 0.0;
      for (var d in debts) {
        if (d.type == DebtType.payable) {
          payables += d.remainingAmount;
        } else {
          receivables += d.remainingAmount;
        }
      }

      DateTime? delayedDate;
      if (delayedStr != null) {
        try {
          delayedDate = DateTime.parse(delayedStr);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _totalCash = cash;
          _totalPayables = payables;
          _totalReceivables = receivables;
          _paydayCycle = cycle;
          _delayedUntilDate = delayedDate;
          _lastReceivedCycle = lastReceived;
          _savingsTarget = savedTarget;
          _checkedHacks = savedHacks.toSet();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  KinsenasCycleInfo _getKinsenasCycleInfo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

    int firstTarget = 15;
    int secondTarget = lastDayOfMonth >= 30 ? 30 : lastDayOfMonth;

    if (_paydayCycle == '10_25') {
      firstTarget = 10;
      secondTarget = 25;
    } else if (_paydayCycle == '5_20') {
      firstTarget = 5;
      secondTarget = 20;
    } else if (_paydayCycle == 'end_of_month') {
      firstTarget = lastDayOfMonth;
      secondTarget = lastDayOfMonth;
    }

    // 1. If user has active adjusted date (early or delayed)
    if (_delayedUntilDate != null) {
      final customDay = DateTime(_delayedUntilDate!.year, _delayedUntilDate!.month, _delayedUntilDate!.day);
      final daysDiff = customDay.difference(today).inDays;

      // Check whether this custom date is earlier or later than the regular cutoff
      final regularRef = today.isBefore(DateTime(now.year, now.month, firstTarget))
          ? DateTime(now.year, now.month, firstTarget)
          : DateTime(now.year, now.month, secondTarget);
      final isEarly = customDay.isBefore(regularRef);
      final cycleKey = '${isEarly ? "early" : "delayed"}_${customDay.year}_${customDay.month}_${customDay.day}';

      if (daysDiff == 0) {
        return KinsenasCycleInfo(
          targetDate: customDay,
          daysLeft: 0,
          isPaydayToday: true,
          isDelayed: !isEarly,
          isEarly: isEarly,
          isAwaitingConfirmation: true,
          title: isEarly ? '⚡ Maagang Sahod Day Ngayon!' : '🎉 Inaasahang Sahod Day Ngayon!',
          subtitle: isEarly ? 'Pumasok na ba ang maagang payout mo?' : 'Dumating na ba ang delayed na payout mo?',
          cycleKey: cycleKey,
        );
      } else if (daysDiff > 0) {
        return KinsenasCycleInfo(
          targetDate: customDay,
          daysLeft: daysDiff,
          isPaydayToday: false,
          isDelayed: !isEarly,
          isEarly: isEarly,
          isAwaitingConfirmation: false,
          title: isEarly ? '⚡ Maagang Sahod Schedule' : '⏳ Na-delay ang Sahod',
          subtitle: daysDiff == 1
              ? 'Inaasahang papasok bukas (${DateFormat('MMM d').format(customDay)})!'
              : 'Inaasahang papasok sa $daysDiff araw (${DateFormat('MMM d').format(customDay)})',
          cycleKey: cycleKey,
        );
      } else {
        // Date has passed and user hasn't confirmed yet
        return KinsenasCycleInfo(
          targetDate: customDay,
          daysLeft: 0,
          isPaydayToday: false,
          isDelayed: !isEarly,
          isEarly: isEarly,
          isAwaitingConfirmation: true,
          title: isEarly ? '⚡ Maagang Sahod (Lagpas na sa petsa)' : '⚠️ Delayed Sahod (Lagpas na sa petsa)',
          subtitle: 'Inaasahan noong ${DateFormat('MMM d').format(customDay)}. Dumating na ba?',
          cycleKey: cycleKey,
        );
      }
    }

    // 2. Regular cycle calculation
    final t1 = DateTime(now.year, now.month, firstTarget);
    final t2 = DateTime(now.year, now.month, secondTarget);
    final nextT1 = DateTime(now.year, now.month + 1, firstTarget);

    if (today.isBefore(t1)) {
      final daysLeft = t1.difference(today).inDays;
      final daysText = daysLeft == 1 ? 'is tomorrow (${firstTarget}th)!' : 'is in $daysLeft days (${firstTarget}th)';
      return KinsenasCycleInfo(
        targetDate: t1,
        daysLeft: daysLeft,
        isPaydayToday: false,
        isDelayed: false,
        isAwaitingConfirmation: false,
        title: 'Upcoming Kinsenas',
        subtitle: 'Next payout $daysText',
        cycleKey: '${t1.year}-${t1.month}-${t1.day}',
      );
    } else if (today.isAtSameMomentAs(t1)) {
      return KinsenasCycleInfo(
        targetDate: t1,
        daysLeft: 0,
        isPaydayToday: true,
        isDelayed: false,
        isAwaitingConfirmation: true,
        title: '🎉 Kinsenas Day Ngayon!',
        subtitle: 'Sahod payout schedule today (${firstTarget}th)!',
        cycleKey: '${t1.year}-${t1.month}-${t1.day}',
      );
    } else if (_paydayCycle != 'end_of_month' && today.isBefore(t2)) {
      final t1Key = '${t1.year}-${t1.month}-${t1.day}';
      final hasConfirmedT1 = _lastReceivedCycle == t1Key;
      final daysPastT1 = today.difference(t1).inDays;

      // If within 2 days after T1 and user hasn't confirmed receipt
      if (!hasConfirmedT1 && daysPastT1 <= 2) {
        return KinsenasCycleInfo(
          targetDate: t1,
          daysLeft: 0,
          isPaydayToday: false,
          isDelayed: false,
          isAwaitingConfirmation: true,
          title: '❓ Dumating na ba ang sahod mo?',
          subtitle: 'Nakatakda noong ${firstTarget}th. Paki-kumpirma kung natanggap na o na-delay.',
          cycleKey: t1Key,
        );
      }

      final daysLeft = t2.difference(today).inDays;
      final daysText = daysLeft == 1 ? 'is tomorrow (${secondTarget}th)!' : 'is in $daysLeft days (${secondTarget}th)';
      return KinsenasCycleInfo(
        targetDate: t2,
        daysLeft: daysLeft,
        isPaydayToday: false,
        isDelayed: false,
        isAwaitingConfirmation: false,
        title: 'Upcoming Kinsenas',
        subtitle: 'Next payout $daysText',
        cycleKey: '${t2.year}-${t2.month}-${t2.day}',
      );
    } else if (_paydayCycle != 'end_of_month' && today.isAtSameMomentAs(t2)) {
      return KinsenasCycleInfo(
        targetDate: t2,
        daysLeft: 0,
        isPaydayToday: true,
        isDelayed: false,
        isAwaitingConfirmation: true,
        title: '🎉 Kinsenas Day Ngayon!',
        subtitle: 'Sahod payout schedule today (${secondTarget}th)!',
        cycleKey: '${t2.year}-${t2.month}-${t2.day}',
      );
    } else {
      // Past T2 (or past end of month)
      final daysLeft = nextT1.difference(today).inDays;
      return KinsenasCycleInfo(
        targetDate: nextT1,
        daysLeft: daysLeft,
        isPaydayToday: false,
        isDelayed: false,
        isAwaitingConfirmation: false,
        title: 'Upcoming Kinsenas',
        subtitle: 'Next payout is in $daysLeft days (${firstTarget}th)',
        cycleKey: '${nextT1.year}-${nextT1.month}-${nextT1.day}',
      );
    }
  }

  Future<void> _confirmSahodReceived(KinsenasCycleInfo cycle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('payday_delayed_until');
    await prefs.setString('payday_last_received_cycle', cycle.cycleKey);

    setState(() {
      _delayedUntilDate = null;
      _lastReceivedCycle = cycle.cycleKey;
    });

    await _loadDashboardData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.celebration_rounded, color: AppColors.drySage, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🎉 Natanggap na ang sahod! Na-set na ang countdown para sa susunod na kinsenas.',
                  style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _openAdjustModal(KinsenasCycleInfo cycle, {PaydayAdjustMode initialMode = PaydayAdjustMode.delayed}) {
    DelayPaydayModal.show(
      context: context,
      currentScheduledDate: cycle.targetDate,
      existingDelayedDate: _delayedUntilDate,
      initialMode: initialMode,
      onInstantReceived: () => _confirmSahodReceived(cycle),
      onConfirmDate: (newDate, isEarly) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('payday_delayed_until', newDate.toIso8601String());
        setState(() => _delayedUntilDate = newDate);
        await _loadDashboardData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surface,
              content: Text(
                isEarly
                    ? '⚡ Na-set ang maagang sahod sa ${DateFormat('MMM d').format(newDate)}!'
                    : '✓ Na-adjust ang petsa sa ${DateFormat('MMM d').format(newDate)}! Na-update ang Petsa de Peligro budget.',
                style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      },
      onResetToRegular: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('payday_delayed_until');
        setState(() => _delayedUntilDate = null);
        await _loadDashboardData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.surface,
              content: Text(
                '✓ Naibalik sa regular schedule ang countdown.',
                style: TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      },
    );
  }

  void _showQuickCashDialog() {
    final controller = TextEditingController(
      text: _totalCash > 0 ? _totalCash.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppColors.drySage, size: 22),
            SizedBox(width: 10),
            Text(
              'I-update ang Cash Balance',
              style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ilagay ang kabuuang pera mo ngayon (Cash on hand + GCash/Maya/Bank). Gagamitin ito sa Petsa de Peligro allowance.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [DecimalCurrencyFormatter()],
              autofocus: true,
              style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: const TextStyle(color: AppColors.drySage, fontSize: 18, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppColors.inputFill,
                hintText: '0.00',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.drySage)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dustyOlive),
            onPressed: () async {
              final text = controller.text.replaceAll(',', '').replaceAll('₱', '').trim();
              final val = double.tryParse(text) ?? 0.0;
              Navigator.pop(ctx);

              final accounts = await DatabaseService.instance.getAccounts();
              if (accounts.isNotEmpty) {
                final target = accounts.firstWhere((a) => a.isPrimary, orElse: () => accounts.first);
                await DatabaseService.instance.updateAccountBalance(target.id, val);
              }
              await _loadDashboardData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text('✓ Na-update ang Cash sa ₱${val.toStringAsFixed(2)}!', style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold)),
                  ),
                );
              }
            },
            child: const Text('I-save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _setSavingsTarget(double val) async {
    setState(() => _savingsTarget = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('petsa_savings_target', val);
  }

  Future<void> _toggleTipidHack(String hackId) async {
    setState(() {
      if (_checkedHacks.contains(hackId)) {
        _checkedHacks.remove(hackId);
      } else {
        _checkedHacks.add(hackId);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('petsa_checked_hacks', _checkedHacks.toList());
  }

  void _showCustomTargetDialog() {
    final controller = TextEditingController(
      text: _savingsTarget > 0 ? _savingsTarget.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.savings_rounded, color: AppColors.drySage, size: 22),
            SizedBox(width: 10),
            Text(
              'Custom Savings Target',
              style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Magkano ang nais mong matira sa pera mo pagdating ng susunod na sahod (cutoff)?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [DecimalCurrencyFormatter()],
              autofocus: true,
              style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: const TextStyle(color: AppColors.drySage, fontSize: 18, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppColors.inputFill,
                hintText: '0.00',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.drySage)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dustyOlive),
            onPressed: () async {
              final text = controller.text.replaceAll(',', '').replaceAll('₱', '').trim();
              final val = double.tryParse(text) ?? 0.0;
              Navigator.pop(ctx);
              await _setSavingsTarget(val);
            },
            child: const Text('I-save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmResetAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Everything to ₱0?', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'This will reset your wallet balance to ₱0.00, clear all debts, and reset savings progress to ₱0.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warningRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.resetAllToZero();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('payday_delayed_until');
              await prefs.remove('payday_last_received_cycle');
              await prefs.remove('petsa_savings_target');
              await prefs.remove('petsa_checked_hacks');
              await _loadDashboardData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text('✓ Everything reset back to ₱0.00!', style: TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold)),
                  ),
                );
              }
            },
            child: const Text('Reset to ₱0', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double netWorth = (_totalCash + _totalReceivables) - _totalPayables;
    final cycleInfo = _getKinsenasCycleInfo();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Kinsenas', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.whiteSmoke)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ).then((_) => _loadDashboardData());
              } else if (val == 'reset') {
                _confirmResetAll();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, color: AppColors.drySage, size: 18),
                    SizedBox(width: 10),
                    Text('Settings', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, color: AppColors.warningRed, size: 18),
                    SizedBox(width: 10),
                    Text('Reset all to ₱0', style: TextStyle(color: AppColors.warningRed, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.drySage))
          : RefreshIndicator(
              color: AppColors.drySage,
              backgroundColor: AppColors.surface,
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Net Worth Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Net Worth', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          '₱${netWorth.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.whiteSmoke,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _showQuickCashDialog,
                                borderRadius: BorderRadius.circular(16),
                                child: _buildMetricTile(
                                  'Cash / Wallets',
                                  _totalCash,
                                  AppColors.drySage,
                                  editable: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile('Payables (Owed)', _totalPayables, AppColors.ashBrown),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payday Countdown Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: cycleInfo.isDelayed
                            ? [const Color(0x30E07A5F), AppColors.surface]
                            : [AppColors.surfaceElevated, AppColors.surface],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cycleInfo.isDelayed ? const Color(0x60E07A5F) : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cycleInfo.isDelayed
                                    ? const Color(0x25E07A5F)
                                    : AppColors.dustyOlive.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                cycleInfo.isDelayed
                                    ? Icons.hourglass_bottom_rounded
                                    : (cycleInfo.isEarly ? Icons.bolt_rounded : Icons.calendar_today_rounded),
                                color: cycleInfo.isDelayed ? AppColors.warningRed : AppColors.drySage,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          cycleInfo.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      if (cycleInfo.isDelayed) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0x30E07A5F),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'DELAYED',
                                            style: TextStyle(color: AppColors.warningRed, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                      if (cycleInfo.isEarly) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.dustyOlive.withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'MAAGA',
                                            style: TextStyle(color: AppColors.drySage, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    cycleInfo.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            // Quick adjust icons if not currently in confirmation mode
                            if (!cycleInfo.isAwaitingConfirmation)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Early Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _openAdjustModal(cycleInfo, initialMode: PaydayAdjustMode.early),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: cycleInfo.isEarly
                                              ? AppColors.dustyOlive.withValues(alpha: 0.3)
                                              : AppColors.inputFill,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: cycleInfo.isEarly ? AppColors.drySage : AppColors.border,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bolt_rounded, color: AppColors.drySage, size: 12),
                                            SizedBox(width: 2),
                                            Text(
                                              'Maaga',
                                              style: TextStyle(color: AppColors.drySage, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  // Delay Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _openAdjustModal(cycleInfo, initialMode: PaydayAdjustMode.delayed),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: cycleInfo.isDelayed
                                              ? const Color(0x30E07A5F)
                                              : AppColors.inputFill,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: cycleInfo.isDelayed ? AppColors.warningRed : AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              cycleInfo.isDelayed ? Icons.edit_calendar_rounded : Icons.hourglass_empty_rounded,
                                              color: cycleInfo.isDelayed ? AppColors.warningRed : AppColors.textSecondary,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              cycleInfo.isDelayed ? 'I-adjust' : 'Na-delay',
                                              style: TextStyle(
                                                color: cycleInfo.isDelayed ? AppColors.warningRed : AppColors.textSecondary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        // Action Banner if awaiting confirmation (Payday or Delay)
                        if (cycleInfo.isAwaitingConfirmation) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dumating na ba ang sahod mo sa account/wallet?',
                                  style: TextStyle(color: AppColors.whiteSmoke, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.dustyOlive,
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _confirmSahodReceived(cycleInfo),
                                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.whiteSmoke, size: 15),
                                        label: const Text(
                                          'Oo, Natanggap Na!',
                                          style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.border),
                                          backgroundColor: AppColors.surface,
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _openAdjustModal(cycleInfo, initialMode: PaydayAdjustMode.delayed),
                                        icon: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.warningRed, size: 15),
                                        label: const Text(
                                          'Hindi Pa / Na-delay',
                                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Petsa de Peligro Survival Card
                  _buildPetsaDePeligroCard(cycleInfo),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildPetsaDePeligroCard(KinsenasCycleInfo cycle) {
    final int effectiveDays = cycle.daysLeft > 0 ? cycle.daysLeft : 1;
    final double actualBuffer = _savingsTarget.clamp(0.0, _totalCash);
    final double spendableCash = (_totalCash - actualBuffer).clamp(0.0, _totalCash);
    final double dailySpendToSave = spendableCash / effectiveDays;
    final double dailyZeroOut = _totalCash / effectiveDays;
    final isDangerZone = cycle.isDelayed || cycle.daysLeft <= 3;

    double totalSavedToday = 0.0;
    for (var h in _tipidHacks) {
      if (_checkedHacks.contains(h['id'])) {
        totalSavedToday += (h['savings'] as num).toDouble();
      }
    }

    final twentyPctBuffer = (_totalCash * 0.2).roundToDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cycle.isDelayed
              ? const Color(0x70E07A5F)
              : isDangerZone
                  ? AppColors.dustyOlive
                  : AppColors.border,
          width: isDangerZone ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDangerZone ? const Color(0x35E07A5F) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: isDangerZone ? AppColors.warningRed : AppColors.drySage,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'PETSA DE PELIGRO',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.whiteSmoke,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDangerZone
                                ? const Color(0x30E07A5F)
                                : AppColors.dustyOlive.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cycle.daysLeft <= 0
                                ? 'Huling araw!'
                                : '${cycle.daysLeft} araw na lang',
                            style: TextStyle(
                              color: isDangerZone ? AppColors.warningRed : AppColors.drySage,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Plano ng Gastusin at Pag-iipon hanggang ${DateFormat('MMM d').format(cycle.targetDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _showPetsaDePeligroDetails ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPetsaDePeligroDetails = !_showPetsaDePeligroDetails),
              ),
            ],
          ),

          if (_showPetsaDePeligroDetails) ...[
            const SizedBox(height: 16),

            // 1. Savings Cushion Selector (Gusto kong matira bago mag-sahod)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.savings_outlined, color: AppColors.drySage, size: 14),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'MATITIRA SA SAHOD (SAVINGS):',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_savingsTarget > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Target: ₱${_savingsTarget.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.drySage, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Savings Target Presets Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSavingsPresetChip('₱0 (Sagad)', 0.0),
                  _buildSavingsPresetChip('₱200', 200.0),
                  _buildSavingsPresetChip('₱500', 500.0),
                  if (twentyPctBuffer > 0 && twentyPctBuffer != 200.0 && twentyPctBuffer != 500.0)
                    _buildSavingsPresetChip('20% (₱${twentyPctBuffer.toStringAsFixed(0)})', twentyPctBuffer),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: _showCustomTargetDialog,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_savingsTarget != 0.0 && _savingsTarget != 200.0 && _savingsTarget != 500.0 && _savingsTarget != twentyPctBuffer)
                              ? AppColors.dustyOlive.withValues(alpha: 0.3)
                              : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_savingsTarget != 0.0 && _savingsTarget != 200.0 && _savingsTarget != 500.0 && _savingsTarget != twentyPctBuffer)
                                ? AppColors.drySage
                                : AppColors.border,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, color: AppColors.drySage, size: 11),
                            SizedBox(width: 4),
                            Text(
                              'Iba pa',
                              style: TextStyle(color: AppColors.drySage, fontSize: 11, fontWeight: FontWeight.bold),
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

            // 2. Main Daily Spend Calculator Highlight
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderMuted),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'MAX GASTUSIN KADA ARAW',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.dustyOlive.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _savingsTarget > 0 ? 'MAY MATITIRA' : 'SAGAD SPEND',
                          style: const TextStyle(color: AppColors.drySage, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₱${dailySpendToSave.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '/ araw',
                        style: TextStyle(
                          color: AppColors.drySage,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _savingsTarget > 0
                        ? '✓ Kung ₱${dailySpendToSave.toStringAsFixed(2)} lang ang gagastusin mo kada araw, may matitira kang ₱${actualBuffer.toStringAsFixed(2)} sahod buffer pagdating ng ${DateFormat('MMM d').format(cycle.targetDate)}!'
                        : 'Saktong mauubos ang pera sa ₱0.00 pagsapit ng sahod sa ${DateFormat('MMM d').format(cycle.targetDate)}. Mag-set ng target sa itaas para may matipid.',
                    style: TextStyle(
                      color: _savingsTarget > 0 ? AppColors.whiteSmoke : AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),

                  // Three Mini Breakdown Tiles
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pwedeng Gastusin', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                            Text('₱${spendableCash.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Matitirang Ipon', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                            Text('₱${actualBuffer.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.drySage, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sagad (Zero-out)', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                            Text('₱${dailyZeroOut.toStringAsFixed(2)}/day', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Witty Filipino Survival Advice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.tips_and_updates_rounded, color: AppColors.drySage, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kinsenas Diskarte Advice:',
                          style: TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSurvivalTip(dailySpendToSave, _totalCash),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Quick Action Row: Update Cash & Adjust Date
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showQuickCashDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: AppColors.drySage, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'I-update ang Cash',
                            style: TextStyle(color: AppColors.drySage, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _openAdjustModal(cycle, initialMode: cycle.isEarly ? PaydayAdjustMode.early : PaydayAdjustMode.delayed),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                      decoration: BoxDecoration(
                        color: cycle.isDelayed
                            ? const Color(0x30E07A5F)
                            : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cycle.isDelayed ? const Color(0x60E07A5F) : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cycle.isDelayed ? Icons.edit_calendar_rounded : Icons.hourglass_bottom_rounded,
                            color: cycle.isDelayed ? AppColors.warningRed : AppColors.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cycle.isDelayed ? 'Baguhin ang Petsa' : 'Na-delay ang Sahod?',
                            style: TextStyle(
                              color: cycle.isDelayed ? AppColors.warningRed : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 4. Practical Philippine Tipid Hacks Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: AppColors.drySage, size: 18),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Paraan Para Makatipid (Tipid Hacks)',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.whiteSmoke,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (totalSavedToday > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.dustyOlive.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.drySage.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '+₱${totalSavedToday.toStringAsFixed(0)} saved!',
                            style: const TextStyle(
                              color: AppColors.drySage,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'I-check ang mga ginawa mo ngayong araw upang makaraos nang may naiwang pera:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 10),

                  // Interactive Checklist of Tipid Hacks
                  ...List.generate(_tipidHacks.length, (idx) {
                    final hack = _tipidHacks[idx];
                    final isChecked = _checkedHacks.contains(hack['id'] as String);
                    final color = hack['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _toggleTipidHack(hack['id'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppColors.dustyOlive.withValues(alpha: 0.25)
                                : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isChecked ? AppColors.drySage : AppColors.borderMuted,
                              width: isChecked ? 1.2 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(hack['icon'] as IconData, color: color, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hack['title'] as String,
                                      style: TextStyle(
                                        color: isChecked ? AppColors.whiteSmoke : AppColors.textSecondary,
                                        fontWeight: isChecked ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      hack['desc'] as String,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isChecked
                                          ? AppColors.dustyOlive
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+₱${(hack['savings'] as num).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isChecked ? AppColors.whiteSmoke : AppColors.drySage,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Icon(
                                    isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    size: 15,
                                    color: isChecked ? AppColors.drySage : AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingsPresetChip(String label, double value) {
    final isSelected = (_savingsTarget - value).abs() < 0.01;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        selectedColor: AppColors.dustyOlive,
        backgroundColor: AppColors.inputFill,
        side: BorderSide(color: isSelected ? AppColors.drySage : AppColors.border),
        onSelected: (_) => _setSavingsTarget(value),
      ),
    );
  }

  String _getSurvivalTip(double daily, double totalCash) {
    if (totalCash <= 0) {
      return '🚨 Alert! ₱0 na ang cash. Mag-water therapy muna at magbaon ng kanin. Kapit lang, malapit na ang payout!';
    } else if (daily < 80) {
      return '🍜 Siomai rice at pancit canton mode muna! Iwasan ang checkout sa Shopee/Lazada hanggang may sahod.';
    } else if (daily < 250) {
      return '🍛 Carinderia at lutong-bahay muna. Huwag muna mag-food delivery para umabot hanggang kinsenas.';
    } else if (daily < 500) {
      return '☕ Keri pa! Safe ang allowance mo, pero hinay-hinay muna sa spontaneous milk tea at kape.';
    } else {
      return '✨ Relax! May sapat kang budget bawat araw hanggang sahod nang hindi kinakapos.';
    }
  }

  Widget _buildMetricTile(String label, double amount, Color accentColor, {bool editable = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              if (editable)
                const Icon(Icons.edit_rounded, color: AppColors.drySage, size: 12),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₱${amount.toStringAsFixed(2)}',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
