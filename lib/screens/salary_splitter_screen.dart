import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/payroll_engine.dart';
import '../utils/decimal_currency_formatter.dart';

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

  String _savedMonthlyAmount = '';
  String _savedDailyAmount = '';

  bool _showSavedIndicator = false;
  Timer? _savedBadgeTimer;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _savedBadgeTimer?.cancel();
    _debounceTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWageType = prefs.getString('splitter_wage_type');
      final savedMonthly = prefs.getString('splitter_monthly_amount') ?? '';
      final savedDaily = prefs.getString('splitter_daily_amount') ?? '';
      final savedSavingsRate = prefs.getDouble('splitter_savings_rate');
      final savedTiming = prefs.getString('splitter_timing');

      if (mounted) {
        setState(() {
          _savedMonthlyAmount = savedMonthly;
          _savedDailyAmount = savedDaily;

          if (savedWageType == 'daily') {
            _wageType = WageType.daily;
            _amountController.text = savedDaily;
          } else {
            _wageType = WageType.monthly;
            _amountController.text = savedMonthly;
          }

          if (savedSavingsRate != null) {
            _savingsRate = savedSavingsRate.clamp(0.0, 50.0);
          }

          if (savedTiming != null) {
            if (savedTiming == 'fifteenthOnly') {
              _timing = DeductionTiming.fifteenthOnly;
            } else if (savedTiming == 'thirtiethOnly') {
              _timing = DeductionTiming.thirtiethOnly;
            } else {
              _timing = DeductionTiming.bothSplit;
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _autoSave({bool triggerFeedback = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('splitter_wage_type', _wageType == WageType.daily ? 'daily' : 'monthly');
      if (_wageType == WageType.monthly) {
        _savedMonthlyAmount = _amountController.text;
        await prefs.setString('splitter_monthly_amount', _amountController.text);
      } else {
        _savedDailyAmount = _amountController.text;
        await prefs.setString('splitter_daily_amount', _amountController.text);
      }
      await prefs.setDouble('splitter_savings_rate', _savingsRate);
      await prefs.setString('splitter_timing', _timing.name);

      if (triggerFeedback && mounted) {
        _triggerSavedFeedback();
      }
    } catch (_) {}
  }

  void _triggerSavedFeedback() {
    _savedBadgeTimer?.cancel();
    setState(() => _showSavedIndicator = true);
    _savedBadgeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSavedIndicator = false);
      }
    });
  }

  void _onAmountChanged(String val) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _autoSave(triggerFeedback: true);
    });
  }

  void _switchWageType(WageType type) {
    if (_wageType == type) return;
    setState(() {
      if (_wageType == WageType.monthly) {
        _savedMonthlyAmount = _amountController.text;
      } else {
        _savedDailyAmount = _amountController.text;
      }

      _wageType = type;
      _amountController.text = type == WageType.monthly ? _savedMonthlyAmount : _savedDailyAmount;
    });
    _autoSave(triggerFeedback: true);
  }

  void _selectTiming(DeductionTiming timing) {
    setState(() => _timing = timing);
    _autoSave(triggerFeedback: true);
  }

  void _onSavingsRateChanged(double val) {
    setState(() => _savingsRate = val);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _autoSave(triggerFeedback: true);
    });
  }

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
        title: Row(
          children: [
            const Text(
              'Sahod Splitter',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteSmoke),
            ),
            const SizedBox(width: 10),
            AnimatedOpacity(
              opacity: _showSavedIndicator ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.dustyOlive.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.drySage.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 12, color: AppColors.drySage),
                    SizedBox(width: 4),
                    Text(
                      'Autosaved',
                      style: TextStyle(
                        color: AppColors.drySage,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                    onTap: () => _switchWageType(WageType.monthly),
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
                    onTap: () => _switchWageType(WageType.daily),
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
            style: const TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [DecimalCurrencyFormatter()],
            style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16),
            onChanged: _onAmountChanged,
            decoration: InputDecoration(
              hintText: _wageType == WageType.monthly ? '₱ 35,000' : '₱ 610',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.normal),
              prefixText: _amountController.text.isNotEmpty ? '₱ ' : null,
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
              const Text(
                'Target Ipon (Savings)',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            onChanged: _onSavingsRateChanged,
          ),

          const SizedBox(height: 14),

          // Deduction Timing Selector
          const Text(
            'When does employer deduct taxes & contributions?',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                    const Text(
                      'Total Deductions',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                            const Text(
                              '15th Net Payout',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                            const Text(
                              '30th Net Payout',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
        onTap: () => _selectTiming(timing),
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
          Text('₱${val.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
