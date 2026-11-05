enum WageType { monthly, daily }
enum DeductionTiming { bothSplit, fifteenthOnly, thirtiethOnly }

class PayrollResult {
  final double grossMonthly;
  final double sss;
  final double philhealth;
  final double pagibig;
  final double tax;
  final double totalDeductions;
  final double monthlyNet;
  final double net15;
  final double net30;
  final double monthlyIpon;
  final bool isTaxExempt;

  PayrollResult({
    required this.grossMonthly,
    required this.sss,
    required this.philhealth,
    required this.pagibig,
    required this.tax,
    required this.totalDeductions,
    required this.monthlyNet,
    required this.net15,
    required this.net30,
    required this.monthlyIpon,
    required this.isTaxExempt,
  });
}

class PayrollEngine {
  /// Calculates exact Philippine statutory deductions & Kinsenas distribution
  static PayrollResult calculate({
    required WageType wageType,
    required double baseAmount,
    int daysPerMonth = 26,
    int daysPerKinsenas = 13,
    required double savingsRatePct,
    required DeductionTiming timing,
  }) {
    // 1. Compute Monthly Gross
    final double grossMonthly = (wageType == WageType.monthly)
        ? baseAmount
        : (baseAmount * daysPerMonth);

    // 2. SSS (2024–2026 guidelines: 4.5% up to ₱30,000 MSC max)
    final double msc = grossMonthly.clamp(4000.0, 30000.0);
    final double sss = msc * 0.045;

    // 3. PhilHealth (5% premium, 2.5% employee share, ceiling at ₱100k, floor at ₱10k)
    final double philhealthBasis = grossMonthly.clamp(10000.0, 100000.0);
    final double philhealth = philhealthBasis * 0.025;

    // 4. Pag-IBIG (₱200 cap)
    final double pagibig = grossMonthly > 1500 ? 200.0 : 100.0;

    // 5. Withholding Tax (TRAIN Law)
    // Statutory Minimum Wage Earners (SMWE) are 100% tax-exempt under RA 9504
    final bool isMinimumWageExempt = (wageType == WageType.daily && baseAmount <= 645);
    final double taxableIncome = (grossMonthly - (sss + philhealth + pagibig)).clamp(0.0, double.infinity);

    double tax = 0.0;
    if (!isMinimumWageExempt && taxableIncome > 20833.33) {
      if (taxableIncome <= 33333.33) {
        tax = (taxableIncome - 20833.33) * 0.15;
      } else if (taxableIncome <= 66666.67) {
        tax = 1875 + (taxableIncome - 33333.33) * 0.20;
      } else if (taxableIncome <= 166666.67) {
        tax = 8541.67 + (taxableIncome - 66666.67) * 0.25;
      } else {
        tax = 33541.67 + (taxableIncome - 166666.67) * 0.30;
      }
    }

    final double totalDeductions = sss + philhealth + pagibig + tax;
    final double monthlyNet = (grossMonthly - totalDeductions).clamp(0.0, double.infinity);
    final double monthlyIpon = grossMonthly * (savingsRatePct / 100);

    // 6. Kinsenas Distribution (15th vs 30th)
    final double gross15 = (wageType == WageType.monthly) ? (grossMonthly / 2) : (baseAmount * daysPerKinsenas);
    final double gross30 = grossMonthly - gross15;

    double net15 = 0;
    double net30 = 0;

    switch (timing) {
      case DeductionTiming.bothSplit:
        net15 = gross15 - (totalDeductions / 2);
        net30 = gross30 - (totalDeductions / 2);
        break;
      case DeductionTiming.fifteenthOnly:
        net15 = gross15 - totalDeductions;
        net30 = gross30;
        break;
      case DeductionTiming.thirtiethOnly:
        net15 = gross15;
        net30 = gross30 - totalDeductions;
        break;
    }

    return PayrollResult(
      grossMonthly: grossMonthly,
      sss: sss,
      philhealth: philhealth,
      pagibig: pagibig,
      tax: tax,
      totalDeductions: totalDeductions,
      monthlyNet: monthlyNet,
      net15: net15.clamp(0.0, double.infinity),
      net30: net30.clamp(0.0, double.infinity),
      monthlyIpon: monthlyIpon,
      isTaxExempt: isMinimumWageExempt,
    );
  }
}
