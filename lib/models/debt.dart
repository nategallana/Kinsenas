enum DebtType { payable, receivable }

class Debt {
  final String id;
  final String title;
  final DebtType type; // payable (I owe) or receivable (They owe me)
  final double totalAmount;
  final double remainingAmount;
  final double? monthlyPayment;
  final int totalTerms;
  final int paidTerms;
  final int? dueDayOfMonth;
  final DateTime createdAt;

  Debt({
    required this.id,
    required this.title,
    required this.type,
    required this.totalAmount,
    required this.remainingAmount,
    this.monthlyPayment,
    this.totalTerms = 1,
    this.paidTerms = 0,
    this.dueDayOfMonth,
    required this.createdAt,
  });

  bool get isFullyPaid => remainingAmount <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'total_amount': totalAmount,
      'remaining_amount': remainingAmount,
      'monthly_payment': monthlyPayment,
      'total_terms': totalTerms,
      'paid_terms': paidTerms,
      'due_day_of_month': dueDayOfMonth,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as String,
      title: map['title'] as String,
      type: DebtType.values.byName(map['type'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      remainingAmount: (map['remaining_amount'] as num).toDouble(),
      monthlyPayment: map['monthly_payment'] != null ? (map['monthly_payment'] as num).toDouble() : null,
      totalTerms: map['total_terms'] as int? ?? 1,
      paidTerms: map['paid_terms'] as int? ?? 0,
      dueDayOfMonth: map['due_day_of_month'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Debt copyWith({
    String? id,
    String? title,
    DebtType? type,
    double? totalAmount,
    double? remainingAmount,
    double? monthlyPayment,
    int? totalTerms,
    int? paidTerms,
    int? dueDayOfMonth,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      totalTerms: totalTerms ?? this.totalTerms,
      paidTerms: paidTerms ?? this.paidTerms,
      dueDayOfMonth: dueDayOfMonth ?? this.dueDayOfMonth,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DebtPayment {
  final String id;
  final String debtId;
  final double amountPaid;
  final DateTime paymentDate; // Supports backdating!
  final String? note;

  DebtPayment({
    required this.id,
    required this.debtId,
    required this.amountPaid,
    required this.paymentDate,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'note': note,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] as String,
      debtId: map['debt_id'] as String,
      amountPaid: (map['amount_paid'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      note: map['note'] as String?,
    );
  }
}
