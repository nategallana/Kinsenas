import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/payroll_engine.dart';

class SalarySplitterScreen extends StatefulWidget {
  const SalarySplitterScreen({super.key});

  @override
  State<SalarySplitterScreen> createState() => _SalarySplitterScreenState();
}

class _SalarySplitterScreenState extends State<SalarySplitterScreen> {
  WageType _wageType = WageType.monthly;
  final TextEditingController _amountController = TextEditingController();
  double _savingsRate = 20.0;
  DeductionTiming _timing = DeductionTiming.bothSplit;

  double _parseAmount(String text) {
    if (text.trim().isEmpty) return 0.0;
    final clean = text.replaceAll(',', '').replaceAll('₱', '').replaceAll(' ', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final double baseAmount = _parseAmount(_amountController.text);
    final result = PayrollEngine.calculate(
      wageType: _wageType,
      baseAmount: baseAmount,
      savingsRatePct: _savingsRate,
      timing: _timing,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sahod Splitter', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteSmoke)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Wage Mode Switcher (Monthly vs Daily/Arawan)
          Container(
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
                    onTap: () {
                      setState(() {
                        _wageType = WageType.monthly;
                        _amountController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _wageType == WageType.monthly ? AppColors.dustyOlive : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Monthly Salary',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _wageType == WageType.monthly ? AppColors.whiteSmoke : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _wageType = WageType.daily;
                        _amountController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _wageType == WageType.daily ? AppColors.dustyOlive : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Daily (Arawan)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _wageType == WageType.daily ? AppColors.whiteSmoke : AppColors.textSecondary,
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

          const SizedBox(height: 18),

          // Income Field (Supports commas and dots like 20,000 or 20,000.50)
          Text(
            _wageType == WageType.monthly ? 'Monthly Gross Pay' : 'Daily Wage (Rate per day)',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _wageType == WageType.monthly ? '35,000' : '610',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.normal),
              prefixText: '₱ ',
              prefixStyle: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold, fontSize: 16),
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.drySage),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Savings Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target Ipon (Savings)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(
                '${_savingsRate.toInt()}% (₱${result.monthlyIpon.toStringAsFixed(2)})',
                style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Slider(
            value: _savingsRate,
            min: 0,
            max: 50,
            divisions: 10,
            activeColor: AppColors.drySage,
            inactiveColor: AppColors.border,
            onChanged: (val) => setState(() => _savingsRate = val),
          ),

          const SizedBox(height: 14),

          // Deduction Timing Selector
          const Text('When does employer deduct taxes & contributions?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTimingBtn('Both (50/50)', DeductionTiming.bothSplit),
              const SizedBox(width: 8),
              _buildTimingBtn('15th Only', DeductionTiming.fifteenthOnly),
              const SizedBox(width: 8),
              _buildTimingBtn('30th Only', DeductionTiming.thirtiethOnly),
            ],
          ),

          const SizedBox(height: 20),

          // Deduction Breakdown Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Deductions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      '-₱${result.totalDeductions.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.ashBrown, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 20),
                _buildDeductionRow('SSS Contribution', result.sss),
                _buildDeductionRow('PhilHealth (2.5%)', result.philhealth),
                _buildDeductionRow('Pag-IBIG Fund', result.pagibig),
                _buildDeductionRow(
                  result.isTaxExempt ? 'TRAIN Tax (Minimum Wage Exempt)' : 'TRAIN Withholding Tax',
                  result.tax,
                ),
                const SizedBox(height: 16),

                // Kinsenas Split Box
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
                            const Text('15th Net Payout', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              '₱${result.net15.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text('Ipon: ₱${(result.monthlyIpon / 2).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
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
                            const Text('30th Net Payout', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              '₱${result.net30.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text('Ipon: ₱${(result.monthlyIpon / 2).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingBtn(String label, DeductionTiming timing) {
    final isSelected = _timing == timing;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _timing = timing),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.dustyOlive : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.drySage : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeductionRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          Text('₱${val.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 11)),
        ],
      ),
    );
  }
}
