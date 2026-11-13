import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/database_service.dart';
import '../models/debt.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalCash = 0.0;
  double _totalPayables = 0.0;
  double _totalReceivables = 0.0;
  String _paydayCycle = '15_30';
  bool _isLoading = true;

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

      if (mounted) {
        setState(() {
          _totalCash = cash;
          _totalPayables = payables;
          _totalReceivables = receivables;
          _paydayCycle = cycle;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, String> _getUpcomingKinsenasInfo() {
    final now = DateTime.now();
    final day = now.day;
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

    if (_paydayCycle == 'end_of_month') {
      if (day < lastDayOfMonth) {
        final daysLeft = lastDayOfMonth - day;
        final daysText = daysLeft == 1 ? 'is tomorrow (${lastDayOfMonth}th)!' : 'is in $daysLeft days (${lastDayOfMonth}th)';
        return {
          'title': 'Upcoming Kinsenas',
          'subtitle': 'Next payout $daysText',
        };
      } else {
        return {
          'title': '🎉 Kinsenas Day!',
          'subtitle': 'Sahod payout is today (Katapusan)!',
        };
      }
    }

    if (day < firstTarget) {
      final daysLeft = firstTarget - day;
      final daysText = daysLeft == 1 ? 'is tomorrow (${firstTarget}th)!' : 'is in $daysLeft days (${firstTarget}th)';
      return {
        'title': 'Upcoming Kinsenas',
        'subtitle': 'Next payout $daysText',
      };
    } else if (day == firstTarget) {
      return {
        'title': '🎉 Kinsenas Day!',
        'subtitle': 'Sahod payout is today (${firstTarget}th)!',
      };
    } else if (day < secondTarget) {
      final daysLeft = secondTarget - day;
      final daysText = daysLeft == 1 ? 'is tomorrow (${secondTarget}th)!' : 'is in $daysLeft days (${secondTarget}th)';
      return {
        'title': 'Upcoming Kinsenas',
        'subtitle': 'Next payout $daysText',
      };
    } else if (day == secondTarget || (secondTarget == 30 && day == lastDayOfMonth)) {
      return {
        'title': '🎉 Kinsenas Day!',
        'subtitle': 'Sahod payout is today (${day}th)!',
      };
    } else {
      final nextFirstTarget = DateTime(now.year, now.month + 1, firstTarget);
      final daysLeft = nextFirstTarget.difference(DateTime(now.year, now.month, day)).inDays;
      return {
        'title': 'Upcoming Kinsenas',
        'subtitle': 'Next payout is in $daysLeft days (${firstTarget}th)',
      };
    }
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
                    Text('Mga Setting (Settings)', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13)),
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
                              child: _buildMetricTile('Cash / Wallets', _totalCash, AppColors.drySage),
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

                  const SizedBox(height: 20),

                  // Payday Countdown Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.surfaceElevated, AppColors.surface],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.dustyOlive.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calendar_today_rounded, color: AppColors.drySage, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final kinsenasInfo = _getUpcomingKinsenasInfo();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kinsenasInfo['title'] ?? 'Upcoming Kinsenas',
                                    style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    kinsenasInfo['subtitle'] ?? '',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile(String label, double amount, Color accentColor) {
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
