import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/account.dart';
import '../models/debt.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalCash = 0.0;
  double _totalPayables = 0.0;
  double _totalReceivables = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final accounts = await DatabaseService.instance.getAccounts();
    final debts = await DatabaseService.instance.getDebts();

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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double netWorth = (_totalCash + _totalReceivables) - _totalPayables;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Kinsenas', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF43F5E)))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Net Worth Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14151B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Net Worth', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        '₱${netWorth.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile('Cash / Wallets', _totalCash, const Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile('Payables (Owed)', _totalPayables, const Color(0xFFF43F5E)),
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
                      colors: [Color(0xFF1E222B), Color(0xFF14151B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFF43F5E), size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Upcoming Kinsenas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Next payout is in 10 days (15th)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricTile(String label, double amount, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0C0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
