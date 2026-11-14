enum BillCutoff { fifteenth, thirtieth, bothSplit }

enum BillCategory {
  electricity,
  water,
  internet,
  rent,
  subscription,
  other;

  String get displayName {
    switch (this) {
      case BillCategory.electricity:
        return 'Kuryente';
      case BillCategory.water:
        return 'Tubig';
      case BillCategory.internet:
        return 'Internet / Wifi';
      case BillCategory.rent:
        return 'Upa / Bahay';
      case BillCategory.subscription:
        return 'Subscription';
      case BillCategory.other:
        return 'Iba Pa';
    }
  }
}

class Bill {
  final String id;
  final String title;
  final double amount;
  final BillCategory category;
  final int dueDay; // 1 to 31
  final BillCutoff cutoff;
  final bool isPaid;
  final DateTime? lastPaidDate;
  final DateTime createdAt;

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.dueDay = 15,
    this.cutoff = BillCutoff.fifteenth,
    this.isPaid = false,
    this.lastPaidDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'due_day': dueDay,
      'cutoff': cutoff.name,
      'is_paid': isPaid ? 1 : 0,
      'last_paid_date': lastPaidDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: BillCategory.values.byName(map['category'] as String? ?? 'other'),
      dueDay: map['due_day'] as int? ?? 15,
      cutoff: BillCutoff.values.byName(map['cutoff'] as String? ?? 'fifteenth'),
      isPaid: (map['is_paid'] as int? ?? 0) == 1,
      lastPaidDate: map['last_paid_date'] != null
          ? DateTime.tryParse(map['last_paid_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Bill copyWith({
    String? id,
    String? title,
    double? amount,
    BillCategory? category,
    int? dueDay,
    BillCutoff? cutoff,
    bool? isPaid,
    DateTime? lastPaidDate,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDay: dueDay ?? this.dueDay,
      cutoff: cutoff ?? this.cutoff,
      isPaid: isPaid ?? this.isPaid,
      lastPaidDate: lastPaidDate ?? this.lastPaidDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
