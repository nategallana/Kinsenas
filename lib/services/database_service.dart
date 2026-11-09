import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../models/debt.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // In-memory fallback (used on Web or if native SQLite is unavailable)
  final List<Account> _memAccounts = [
    Account(
      id: 'default_wallet',
      name: 'Total Money (Cash + Cashless)',
      balance: 15450.0,
      isPrimary: true,
    ),
  ];

  final List<Goal> _memGoals = [
    Goal(
      id: 'goal_motor',
      title: 'FOR MOTOR',
      targetAmount: 60000.0,
      currentAmount: 35000.0,
    ),
    Goal(
      id: 'goal_emergency',
      title: 'EMERGENCY FUND',
      targetAmount: 50000.0,
      currentAmount: 12000.0,
    ),
  ];

  final List<Debt> _memDebts = [
    Debt(
      id: 'd1',
      title: 'SPayLater (Phone Installment)',
      type: DebtType.payable,
      totalAmount: 7500,
      remainingAmount: 5000,
      monthlyPayment: 1250,
      totalTerms: 6,
      paidTerms: 2,
      dueDayOfMonth: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Debt(
      id: 'd2',
      title: 'Kuya Mark (Personal loan)',
      type: DebtType.payable,
      totalAmount: 3000,
      remainingAmount: 3000,
      dueDayOfMonth: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Debt(
      id: 'r1',
      title: 'Carl (Friday Lunch split)',
      type: DebtType.receivable,
      totalAmount: 450,
      remainingAmount: 450,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Debt(
      id: 'r2',
      title: 'Tita Ellen',
      type: DebtType.receivable,
      totalAmount: 5000,
      remainingAmount: 3500,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  final List<DebtPayment> _memPayments = [];

  DatabaseService._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('kinsenas.db');
      return _database!;
    } catch (_) {
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        is_primary INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        total_amount REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        monthly_payment REAL,
        total_terms INTEGER DEFAULT 1,
        paid_terms INTEGER DEFAULT 0,
        due_day_of_month INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE debt_payments (
        id TEXT PRIMARY KEY,
        debt_id TEXT NOT NULL,
        amount_paid REAL NOT NULL,
        payment_date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (debt_id) REFERENCES debts(id)
      )
    ''');

    for (var a in _memAccounts) {
      await db.insert('accounts', a.toMap());
    }
    for (var g in _memGoals) {
      await db.insert('goals', g.toMap());
    }
    for (var d in _memDebts) {
      await db.insert('debts', d.toMap());
    }
  }

  // Account operations
  Future<List<Account>> getAccounts() async {
    try {
      final db = await database;
      if (db != null) {
        final maps = await db.query('accounts');
        if (maps.isNotEmpty) {
          return maps.map((m) => Account.fromMap(m)).toList();
        }
      }
    } catch (_) {}
    return List.from(_memAccounts);
  }

  Future<int> updateAccountBalance(String id, double newBalance) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.update('accounts', {'balance': newBalance}, where: 'id = ?', whereArgs: [id]);
      }
    } catch (_) {}
    final idx = _memAccounts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _memAccounts[idx] = _memAccounts[idx].copyWith(balance: newBalance);
    }
    return 1;
  }

  // Goal operations
  Future<List<Goal>> getGoals() async {
    try {
      final db = await database;
      if (db != null) {
        final maps = await db.query('goals');
        if (maps.isNotEmpty) {
          return maps.map((m) => Goal.fromMap(m)).toList();
        }
      }
    } catch (_) {}
    return List.from(_memGoals);
  }

  Future<int> insertGoal(Goal goal) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.insert('goals', goal.toMap());
      }
    } catch (_) {}
    _memGoals.add(goal);
    return 1;
  }

  Future<int> updateGoal(Goal goal) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
      }
    } catch (_) {}
    final idx = _memGoals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _memGoals[idx] = goal;
    }
    return 1;
  }

  Future<int> deleteGoal(String id) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
      }
    } catch (_) {}
    _memGoals.removeWhere((g) => g.id == id);
    return 1;
  }

  // Debt operations
  Future<List<Debt>> getDebts({DebtType? filterType}) async {
    try {
      final db = await database;
      if (db != null) {
        final maps = (filterType != null)
            ? await db.query('debts', where: 'type = ?', whereArgs: [filterType.name])
            : await db.query('debts');
        if (maps.isNotEmpty) {
          return maps.map((m) => Debt.fromMap(m)).toList();
        }
      }
    } catch (_) {}
    if (filterType != null) {
      return _memDebts.where((d) => d.type == filterType).toList();
    }
    return List.from(_memDebts);
  }

  Future<int> insertDebt(Debt debt) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.insert('debts', debt.toMap());
      }
    } catch (_) {}
    _memDebts.add(debt);
    return 1;
  }

  Future<int> deleteDebt(String id) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
      }
    } catch (_) {}
    _memDebts.removeWhere((d) => d.id == id);
    return 1;
  }

  Future<void> recordDebtPayment(DebtPayment payment) async {
    try {
      final db = await database;
      if (db != null) {
        await db.transaction((txn) async {
          await txn.insert('debt_payments', payment.toMap());
          final debtMap = await txn.query('debts', where: 'id = ?', whereArgs: [payment.debtId], limit: 1);
          if (debtMap.isNotEmpty) {
            final currentDebt = Debt.fromMap(debtMap.first);
            final newRemaining = (currentDebt.remainingAmount - payment.amountPaid).clamp(0.0, double.infinity);
            final newPaidTerms = currentDebt.paidTerms + 1;
            await txn.update(
              'debts',
              {
                'remaining_amount': newRemaining,
                'paid_terms': newPaidTerms,
              },
              where: 'id = ?',
              whereArgs: [payment.debtId],
            );
          }
        });
        return;
      }
    } catch (_) {}

    _memPayments.add(payment);
    final idx = _memDebts.indexWhere((d) => d.id == payment.debtId);
    if (idx != -1) {
      final currentDebt = _memDebts[idx];
      final newRemaining = (currentDebt.remainingAmount - payment.amountPaid).clamp(0.0, double.infinity);
      final newPaidTerms = currentDebt.paidTerms + 1;
      _memDebts[idx] = currentDebt.copyWith(
        remainingAmount: newRemaining,
        paidTerms: newPaidTerms,
      );
    }
  }
}
