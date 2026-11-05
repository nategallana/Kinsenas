enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final String accountId;
  final String category;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? note;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.category,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'category': category,
      'type': type.name,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      category: map['category'] as String,
      type: TransactionType.values.byName(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}
