import 'package:intl/intl.dart';

class GoalDeposit {
  final String id;
  final String goalId;
  final double amount;
  final DateTime createdAt;

  GoalDeposit({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.createdAt,
  });

  String get formattedMessage {
    final formatter = (amount % 1 == 0)
        ? NumberFormat('#,##0')
        : NumberFormat('#,##0.00');
    final amtStr = formatter.format(amount);
    return 'You added $amtStr pesos on your goal!';
  }

  String get formattedDate {
    return DateFormat('MMM. d, yyyy').format(createdAt);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalDeposit.fromMap(Map<String, dynamic> map) {
    return GoalDeposit(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
