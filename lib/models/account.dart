class Account {
  final String id;
  final String name;
  final double balance;
  final bool isPrimary;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    this.isPrimary = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'is_primary': isPrimary ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      isPrimary: (map['is_primary'] as int) == 1,
    );
  }

  Account copyWith({
    String? id,
    String? name,
    double? balance,
    bool? isPrimary,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
