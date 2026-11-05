import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../models/debt.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kinsenas.db');
    return _database!;
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
    // Accounts Table (Simple or multi-wallet)
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        is_primary INTEGER DEFAULT 0
      )
    ''');

    // Transactions Table
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

    // Goals Table
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0
      )
    ''');

    // Debts Table
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

    // Debt Payments Table (Backdated payment history)
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

    // Insert Default Primary Account ("Universal Wallet")
    await db.insert('accounts', {
      'id': 'default_wallet',
      'name': 'Total Money (Cash + Cashless)',
      'balance': 0.0,
      'is_primary': 1,
    });

    // Insert Initial Motor Goal
    await db.insert('goals', {
      'id': 'goal_motor',
      'title': 'FOR MOTOR',
      'target_amount': 60000.0,
      'current_amount': 15000.0,
    });
  }

  // Account operations
  Future<List<Account>> getAccounts() async {
    final db = await instance.database;
    final maps = await db.query('accounts');
    return maps.map((m) => Account.fromMap(m)).toList();
  }

  Future<int> updateAccountBalance(String id, double newBalance) async {
    final db = await instance.database;
    return await db.update('accounts', {'balance': newBalance}, where: 'id = ?', whereArgs: [id]);
  }

  // Goal operations
  Future<List<Goal>> getGoals() async {
    final db = await instance.database;
    final maps = await db.query('goals');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await instance.database;
    return await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<int> insertGoal(Goal goal) async {
    final db = await instance.database;
    return await db.insert('goals', goal.toMap());
  }

  // Debt operations
  Future<List<Debt>> getDebts({DebtType? filterType}) async {
    final db = await instance.database;
    final maps = (filterType != null)
        ? await db.query('debts', where: 'type = ?', whereArgs: [filterType.name])
        : await db.query('debts');
    return maps.map((m) => Debt.fromMap(m)).toList();
  }

  Future<int> insertDebt(Debt debt) async {
    final db = await instance.database;
    return await db.insert('debts', debt.toMap());
  }

  Future<int> deleteDebt(String id) async {
    final db = await instance.database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> recordDebtPayment(DebtPayment payment) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('debt_payments', payment.toMap());

      // Deduct from debt remaining amount
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
  }
}
