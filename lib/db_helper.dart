import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'transaction_model.dart';

class DBHelper {
  static Database? _db;

  // Singleton pattern
  static final DBHelper instance = DBHelper._privateConstructor();
  DBHelper._privateConstructor();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'moneyge.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        date TEXT NOT NULL
      )
    ''');

    // Tabel untuk menyimpan status transfer per bulan
    await db.execute('''
      CREATE TABLE month_transfer_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL UNIQUE,
        transfer_rejected INTEGER DEFAULT 0,
        created_date TEXT NOT NULL
      )
    ''');

    // Tabel untuk transfer antar saldo
    await db.execute('''
      CREATE TABLE transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_method TEXT NOT NULL,
        to_method TEXT NOT NULL,
        amount INTEGER NOT NULL,
        description TEXT,
        date TEXT NOT NULL
      )
    ''');

    // Tabel untuk target pengeluaran harian
    await db.execute('''
      CREATE TABLE daily_expense_target (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_amount INTEGER NOT NULL,
        created_date TEXT NOT NULL,
        updated_date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE month_transfer_status (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          month TEXT NOT NULL UNIQUE,
          transfer_rejected INTEGER DEFAULT 0,
          created_date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'cash'
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE transfers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          from_method TEXT NOT NULL,
          to_method TEXT NOT NULL,
          amount INTEGER NOT NULL,
          description TEXT,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE daily_expense_target (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          target_amount INTEGER NOT NULL,
          created_date TEXT NOT NULL,
          updated_date TEXT NOT NULL
        )
      ''');
    }
  }

  // Insert transaction (income or expense)
  Future<int> insertTransaction(TransactionModel transaction) async {
    final dbClient = await db;
    return await dbClient.insert('transactions', transaction.toMap());
  }

  // Get all transactions
  Future<List<TransactionModel>> getTransactions() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  // Get expenses only
  Future<List<TransactionModel>> getExpenses() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ?',
      whereArgs: ['expense'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  // Get income only
  Future<List<TransactionModel>> getIncome() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ?',
      whereArgs: ['income'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  // Get cash income only
  Future<List<TransactionModel>> getCashIncome() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ? AND payment_method = ?',
      whereArgs: ['income', 'cash'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  // Get cashless income only
  Future<List<TransactionModel>> getCashlessIncome() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ? AND payment_method = ?',
      whereArgs: ['income', 'cashless'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  // Delete transaction
  Future<int> deleteTransaction(int id) async {
    final dbClient = await db;
    return await dbClient.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update transaction
  Future<int> updateTransaction(TransactionModel transaction) async {
    final dbClient = await db;
    return await dbClient.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Get total expenses
  Future<int> getTotalExpenses() async {
    final expenses = await getExpenses();
    int total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  // Get total income
  Future<int> getTotalIncome() async {
    final income = await getIncome();
    int total = 0;
    for (var item in income) {
      total += item.amount;
    }
    return total;
  }

  // Get total cash income
  Future<int> getTotalCashIncome() async {
    final income = await getCashIncome();
    int total = 0;
    for (var item in income) {
      total += item.amount;
    }
    return total;
  }

  // Get total cashless income
  Future<int> getTotalCashlessIncome() async {
    final income = await getCashlessIncome();
    int total = 0;
    for (var item in income) {
      total += item.amount;
    }
    return total;
  }

  // Get cash expenses only
  Future<List<TransactionModel>> getCashExpenses() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ? AND payment_method = ?',
      whereArgs: ['expense', 'cash'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  // Get cashless expenses only
  Future<List<TransactionModel>> getCashlessExpenses() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ? AND payment_method = ?',
      whereArgs: ['expense', 'cashless'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  // Get total cash expenses
  Future<int> getTotalCashExpenses() async {
    final expenses = await getCashExpenses();
    int total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  // Get total cashless expenses
  Future<int> getTotalCashlessExpenses() async {
    final expenses = await getCashlessExpenses();
    int total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  // Get monthly cash income for specific month
  Future<int> getMonthlyCashIncome(String month) async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ? AND payment_method = ? AND date LIKE ?',
      whereArgs: ['income', 'cash', '$month%'],
    );

    int total = 0;
    for (var map in maps) {
      total += map['amount'] as int;
    }
    return total;
  }

  // Get monthly cashless income for specific month
  Future<int> getMonthlyCashlessIncome(String month) async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ? AND payment_method = ? AND date LIKE ?',
      whereArgs: ['income', 'cashless', '$month%'],
    );

    int total = 0;
    for (var map in maps) {
      total += map['amount'] as int;
    }
    return total;
  }

  // Get monthly expenses for specific month
  Future<int> getMonthlyExpenses(String month) async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ? AND date LIKE ?',
      whereArgs: ['expense', '$month%'],
    );

    int total = 0;
    for (var map in maps) {
      total += map['amount'] as int;
    }
    return total;
  }

  // Get daily expenses for specific date
  Future<int> getDailyExpenses(String date) async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'transactions',
      where: 'type = ? AND date LIKE ?',
      whereArgs: ['expense', '$date%'],
    );

    int total = 0;
    for (var map in maps) {
      total += map['amount'] as int;
    }
    return total;
  }

  // Fungsi baru: Tandai bahwa transfer untuk bulan ini sudah ditolak
  Future<void> markTransferRejected(String month) async {
    final dbClient = await db;
    await dbClient.insert('month_transfer_status', {
      'month': month,
      'transfer_rejected': 1,
      'created_date': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Fungsi baru: Cek apakah transfer untuk bulan ini sudah ditolak
  Future<bool> isTransferRejected(String month) async {
    final dbClient = await db;
    final result = await dbClient.query(
      'month_transfer_status',
      where: 'month = ? AND transfer_rejected = 1',
      whereArgs: [month],
    );
    return result.isNotEmpty;
  }

  // Fungsi baru: Delete transfer yang sudah ditolak (untuk cleanup)
  Future<int> deleteTransferredBalanceAndMarkRejected(
    int transactionId,
    String month,
  ) async {
    final dbClient = await db;

    // Hapus transaksi
    final deleteResult = await dbClient.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    // Tandai bahwa transfer untuk bulan ini sudah ditolak
    await markTransferRejected(month);

    return deleteResult;
  }

  // Transfer from cashless to cash (NEW METHOD)
  Future<int> transferCashlessToCash(int amount, String description) async {
    final dbClient = await db;

    // Insert ke tabel transfers saja, tidak ke transactions
    await dbClient.insert('transfers', {
      'from_method': 'cashless',
      'to_method': 'cash',
      'amount': amount,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    });

    return amount;
  }

  // Transfer from cash to cashless (NEW METHOD)
  Future<int> transferCashToCashless(int amount, String description) async {
    final dbClient = await db;

    // Insert ke tabel transfers saja, tidak ke transactions
    await dbClient.insert('transfers', {
      'from_method': 'cash',
      'to_method': 'cashless',
      'amount': amount,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    });

    return amount;
  }

  // Get all transfers
  Future<List<Map<String, dynamic>>> getTransfers() async {
    final dbClient = await db;
    return await dbClient.query('transfers', orderBy: 'date DESC');
  }

  // Get transfers for specific month
  Future<List<Map<String, dynamic>>> getMonthlyTransfers(String month) async {
    final dbClient = await db;
    return await dbClient.query(
      'transfers',
      where: 'date LIKE ?',
      whereArgs: ['$month%'],
      orderBy: 'date DESC',
    );
  }

  // Calculate net transfer amount for cash/cashless
  Future<int> getNetTransferAmount(String method, String month) async {
    final transfers = await getMonthlyTransfers(month);
    int netAmount = 0;

    for (var transfer in transfers) {
      if (transfer['to_method'] == method) {
        netAmount += transfer['amount'] as int;
      } else if (transfer['from_method'] == method) {
        netAmount -= transfer['amount'] as int;
      }
    }

    return netAmount;
  }

  // Delete transfer
  Future<int> deleteTransfer(int id) async {
    final dbClient = await db;
    return await dbClient.delete('transfers', where: 'id = ?', whereArgs: [id]);
  }

  // === DAILY EXPENSE TARGET METHODS ===

  // Set or update daily expense target
  Future<void> setDailyExpenseTarget(int targetAmount) async {
    final dbClient = await db;

    // Check if target already exists
    final existing = await dbClient.query('daily_expense_target', limit: 1);

    if (existing.isEmpty) {
      // Insert new target
      await dbClient.insert('daily_expense_target', {
        'target_amount': targetAmount,
        'created_date': DateTime.now().toIso8601String(),
        'updated_date': DateTime.now().toIso8601String(),
      });
    } else {
      // Update existing target
      await dbClient.update(
        'daily_expense_target',
        {
          'target_amount': targetAmount,
          'updated_date': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  // Get daily expense target
  Future<int?> getDailyExpenseTarget() async {
    final dbClient = await db;
    final result = await dbClient.query('daily_expense_target', limit: 1);

    if (result.isEmpty) return null;
    return result.first['target_amount'] as int?;
  }

  // Delete daily expense target
  Future<void> deleteDailyExpenseTarget() async {
    final dbClient = await db;
    await dbClient.delete('daily_expense_target');
  }
}
