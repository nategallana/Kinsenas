class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
  });

  double get progressRatio => (targetAmount > 0) ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get progressPercentage => progressRatio * 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
    );
  }

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
    );
  }
}
