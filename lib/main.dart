import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'db_helper.dart';
import 'transaction_model.dart';
import 'currency_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MoneygeApp());
}

class MoneygeApp extends StatelessWidget {
  const MoneygeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moneyge',
      theme: _buildModernTheme(),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

ThemeData _buildModernTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1A1B4B),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF6366F1),
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF8B5CF6),
    onSecondary: Colors.white,
    tertiary: Color(0xFF06B6D4),
    onTertiary: Colors.white,
    error: Color(0xFFEF4444),
    onError: Colors.white,
    background: Color(0xFFF8FAFC),
    onBackground: Color(0xFF1E293B),
    surface: Colors.white,
    onSurface: Color(0xFF1E293B),
    surfaceVariant: Color(0xFFF1F5F9),
    outline: Color(0xFFE2E8F0),
  );

  final baseTextTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    textTheme: baseTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onBackground,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onBackground,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      prefixIconColor: colorScheme.onSurface.withOpacity(0.7),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();
  final TextEditingController _transferAmountController =
      TextEditingController();
  final TextEditingController _transferDescriptionController =
      TextEditingController();

  List<TransactionModel> expenses = [];
  List<TransactionModel> incomeList = [];
  // Tambahkan setelah variabel yang sudah ada
  List<Map<String, dynamic>> transfers = [];
  int totalIncome = 0;
  int totalExpenses = 0;
  String currentMonth = '';
  String currentMonthIndonesian = '';
  int _selectedTabIndex = 0;

  // Tambahkan setelah variabel yang sudah ada
  int totalCashIncome = 0;
  int totalCashlessIncome = 0;
  String _selectedPaymentMethod = 'cash'; // untuk dropdown payment method

  // Tambahkan setelah variabel yang sudah ada
  int totalCashExpenses = 0;
  int totalCashlessExpenses = 0;
  String _selectedExpensePaymentMethod =
      'cash'; // untuk dropdown payment method expense

  int? dailyExpenseTarget;
  bool hasShownDailyWarning = false;

  late AnimationController _balanceAnimationController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _balanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _balanceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _balanceAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _setCurrentMonth();
    _checkAndTransferPreviousBalance();
    _loadDailyExpenseTarget(); // Tambahkan ini
    _loadData();
  }

  void _showTransferDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Transfer Saldo',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info Saldo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo Cash:',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        CurrencyHelper.formatRupiah(
                          totalCashIncome - totalCashExpenses,
                        ),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo Cashless:',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        CurrencyHelper.formatRupiah(
                          totalCashlessIncome - totalCashlessExpenses,
                        ),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _transferAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah Transfer',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.swap_horiz),
              ),
            ),
          ],
        ),
        actions: [
          // Baris pertama - tombol batal
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ),
          const SizedBox(height: 8),
          // Baris kedua - tombol transfer
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _transferCashlessToCash(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cashless ke Cash',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _transferCashToCashless(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cash ke Cashless',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setCurrentMonth() {
    final now = DateTime.now();
    currentMonth = DateFormat('yyyy-MM').format(now);
    currentMonthIndonesian = _getIndonesianMonth(now.month, now.year);
  }

  String _getIndonesianMonth(int month, int year) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[month - 1]} $year';
  }

  // Tambahkan method baru ini
  Future<void> _loadDailyExpenseTarget() async {
    try {
      final target = await DBHelper.instance.getDailyExpenseTarget();
      setState(() {
        dailyExpenseTarget = target;
        hasShownDailyWarning = false;
      });
    } catch (e) {
      print('Error loading daily target: $e');
    }
  }

  Future<void> _checkDailyExpenseTarget() async {
    if (dailyExpenseTarget == null) return;

    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final todayExpenses = await DBHelper.instance.getDailyExpenses(today);

      // Check SharedPreferences untuk last warning date
      final prefs = await SharedPreferences.getInstance();
      final lastWarningDate = prefs.getString('last_warning_date') ?? '';

      // Tampilkan warning jika belum ditampilkan hari ini dan sudah melebihi target
      if (todayExpenses > dailyExpenseTarget! && lastWarningDate != today) {
        // Simpan tanggal warning
        await prefs.setString('last_warning_date', today);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFFFEF2F2),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Peringatan!',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anda sudah melewati target pengeluaran harian!',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target Harian:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                            Text(
                              CurrencyHelper.formatRupiah(dailyExpenseTarget!),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pengeluaran Hari Ini:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                            Text(
                              CurrencyHelper.formatRupiah(todayExpenses),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selisih:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                            Text(
                              CurrencyHelper.formatRupiah(
                                todayExpenses - dailyExpenseTarget!,
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Mengerti'),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking daily target: $e');
    }
  }

  void _showSetDailyTargetDialog() {
    final controller = TextEditingController(
      text: dailyExpenseTarget != null
          ? CurrencyHelper.formatRupiahWithoutSymbol(dailyExpenseTarget!)
          : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Target Pengeluaran Harian',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tetapkan batas maksimal pengeluaran per hari. Anda akan mendapat peringatan jika melebihi target.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Target Harian',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.flag),
              ),
            ),
          ],
        ),
        actions: [
          if (dailyExpenseTarget != null)
            TextButton(
              onPressed: () async {
                await DBHelper.instance.deleteDailyExpenseTarget();
                await _loadDailyExpenseTarget();
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Target harian dihapus');
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
              ),
              child: const Text('Hapus Target'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                _showSnackBar('Masukkan jumlah target', isError: true);
                return;
              }

              try {
                final amount = CurrencyHelper.parseRupiah(controller.text);
                if (amount <= 0) {
                  _showSnackBar('Masukkan jumlah yang valid', isError: true);
                  return;
                }

                await DBHelper.instance.setDailyExpenseTarget(amount);
                await _loadDailyExpenseTarget();

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Target harian berhasil disimpan');
                }
              } catch (e) {
                _showSnackBar('Error: ${e.toString()}', isError: true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransfer(int id) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Hapus',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus riwayat transfer ini?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await DBHelper.instance.deleteTransfer(id);
        await _loadData();
        _balanceAnimationController.reset();
        _balanceAnimationController.forward();
        _showSnackBar('Riwayat transfer berhasil dihapus');
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _transferCashlessToCash() async {
    if (_transferAmountController.text.isEmpty) {
      _showSnackBar('Masukkan jumlah transfer', isError: true);
      return;
    }

    try {
      final amount = CurrencyHelper.parseRupiah(_transferAmountController.text);
      if (amount <= 0) {
        _showSnackBar('Masukkan jumlah yang valid', isError: true);
        return;
      }

      final availableCashless = totalCashlessIncome - totalCashlessExpenses;
      if (amount > availableCashless) {
        _showSnackBar('Saldo cashless tidak mencukupi', isError: true);
        return;
      }

      await DBHelper.instance.transferCashlessToCash(amount, 'Transfer Manual');

      _transferAmountController.clear();

      await _loadData();

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Transfer berhasil: Cashless → Cash');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _transferCashToCashless() async {
    if (_transferAmountController.text.isEmpty) {
      _showSnackBar('Masukkan jumlah transfer', isError: true);
      return;
    }

    try {
      final amount = CurrencyHelper.parseRupiah(_transferAmountController.text);
      if (amount <= 0) {
        _showSnackBar('Masukkan jumlah yang valid', isError: true);
        return;
      }

      final availableCash = totalCashIncome - totalCashExpenses;
      if (amount > availableCash) {
        _showSnackBar('Saldo cash tidak mencukupi', isError: true);
        return;
      }

      await DBHelper.instance.transferCashToCashless(amount, 'Transfer Manual');

      _transferAmountController.clear();

      await _loadData();

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Transfer berhasil: Cash → Cashless');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _checkAndTransferPreviousBalance() async {
    try {
      bool isRejected = await DBHelper.instance.isTransferRejected(
        currentMonth,
      );
      if (isRejected) {
        print(
          'Transfer untuk bulan $currentMonth sudah ditolak, tidak akan dibuat lagi',
        );
        return;
      }

      final allIncome = await DBHelper.instance.getIncome();
      final allExpenses = await DBHelper.instance.getExpenses();

      bool hasTransferredThisMonth = allIncome.any(
        (income) =>
            income.title.startsWith('Sisa') &&
            income.date.startsWith(currentMonth),
      );

      if (hasTransferredThisMonth) return;
      if (allIncome.isEmpty && allExpenses.isEmpty) return;

      Map<String, int> monthlyCashIncome = {};
      Map<String, int> monthlyCashlessIncome = {};
      Map<String, int> monthlyExpenses = {};

      // Hitung pendapatan cash per bulan
      for (var income in allIncome) {
        String month = income.date.substring(0, 7);
        if (!income.title.startsWith('Sisa')) {
          if (income.paymentMethod == 'cash') {
            monthlyCashIncome[month] =
                (monthlyCashIncome[month] ?? 0) + income.amount;
          } else if (income.paymentMethod == 'cashless') {
            monthlyCashlessIncome[month] =
                (monthlyCashlessIncome[month] ?? 0) + income.amount;
          }
        }
      }

      // Hitung pengeluaran per bulan
      for (var expense in allExpenses) {
        String month = expense.date.substring(0, 7);
        monthlyExpenses[month] = (monthlyExpenses[month] ?? 0) + expense.amount;
      }

      // Ambil bulan sebelumnya yang memiliki data
      Set<String> allMonths = {
        ...monthlyCashIncome.keys,
        ...monthlyCashlessIncome.keys,
      };
      List<String> previousMonths = allMonths
          .where((month) => month.compareTo(currentMonth) < 0)
          .toList();

      if (previousMonths.isEmpty) return;

      previousMonths.sort((a, b) => b.compareTo(a));

      for (String prevMonth in previousMonths) {
        int prevCashIncome = monthlyCashIncome[prevMonth] ?? 0;
        int prevCashlessIncome = monthlyCashlessIncome[prevMonth] ?? 0;
        int prevExpenses = monthlyExpenses[prevMonth] ?? 0;

        int totalPrevIncome = prevCashIncome + prevCashlessIncome;
        int balance = totalPrevIncome - prevExpenses;

        if (balance > 0) {
          // Hitung proporsi cash dan cashless dari total income
          double cashRatio = totalPrevIncome > 0
              ? prevCashIncome / totalPrevIncome
              : 0;
          double cashlessRatio = totalPrevIncome > 0
              ? prevCashlessIncome / totalPrevIncome
              : 0;

          // Transfer proportional balance untuk cash
          if (cashRatio > 0) {
            int cashBalance = (balance * cashRatio).round();
            if (cashBalance > 0) {
              final transferCashTransaction = TransactionModel(
                title: 'Sisa Cash ${_getIndonesianMonthFromString(prevMonth)}',
                amount: cashBalance,
                type: 'income',
                paymentMethod: 'cash',
                date: DateTime.now().toIso8601String(),
              );
              await DBHelper.instance.insertTransaction(
                transferCashTransaction,
              );
            }
          }

          // Transfer proportional balance untuk cashless
          if (cashlessRatio > 0) {
            int cashlessBalance = (balance * cashlessRatio).round();
            if (cashlessBalance > 0) {
              final transferCashlessTransaction = TransactionModel(
                title:
                    'Sisa Cashless ${_getIndonesianMonthFromString(prevMonth)}',
                amount: cashlessBalance,
                type: 'income',
                paymentMethod: 'cashless',
                date: DateTime.now().toIso8601String(),
              );
              await DBHelper.instance.insertTransaction(
                transferCashlessTransaction,
              );
            }
          }
          break;
        }
      }
    } catch (e) {
      print('Error checking previous balance: $e');
    }
  }

  String _getIndonesianDayName(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[date.weekday - 1];
  }

  String _getFormattedTodayDate() {
    final now = DateTime.now();
    final dayName = _getIndonesianDayName(now);
    final day = now.day;
    final month = _getIndonesianMonth(now.month, now.year).split(' ')[0];
    final year = now.year;

    return '$dayName, $day $month $year';
  }

  String _getIndonesianMonthFromString(String monthString) {
    List<String> parts = monthString.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    return _getIndonesianMonth(month, year);
  }

  Future<void> _loadData() async {
    await _loadExpenses();
    await _loadIncome();
    await _loadTransfers();

    // Reset daily warning saat load data baru (awal hari)
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final prefs = await SharedPreferences.getInstance();
    final lastWarningDate = prefs.getString('last_warning_date') ?? '';

    if (lastWarningDate != today) {
      setState(() {
        hasShownDailyWarning = false;
      });
    }

    _balanceAnimationController.forward();
  }

  Future<void> _loadTransfers() async {
    try {
      final data = await DBHelper.instance.getMonthlyTransfers(currentMonth);
      setState(() {
        transfers = data;
      });
    } catch (e) {
      print('Error loading transfers: $e');
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await DBHelper.instance.getExpenses();
      final currentMonthExpenses = data
          .where((expense) => expense.date.startsWith(currentMonth))
          .toList();

      final cashExpenses = currentMonthExpenses
          .where((expense) => expense.paymentMethod == 'cash')
          .fold(0, (sum, item) => sum + item.amount);

      final cashlessExpenses = currentMonthExpenses
          .where((expense) => expense.paymentMethod == 'cashless')
          .fold(0, (sum, item) => sum + item.amount);

      setState(() {
        expenses = currentMonthExpenses;
        totalExpenses = currentMonthExpenses.fold(
          0,
          (sum, item) => sum + item.amount,
        );
        totalCashExpenses = cashExpenses;
        totalCashlessExpenses = cashlessExpenses;
      });
    } catch (e) {
      print('Error loading expenses: $e');
    }
  }

  Future<void> _loadIncome() async {
    try {
      final data = await DBHelper.instance.getIncome();
      final currentMonthIncome = data
          .where((income) => income.date.startsWith(currentMonth))
          .toList();

      final cashIncome = currentMonthIncome
          .where((income) => income.paymentMethod == 'cash')
          .fold(0, (sum, item) => sum + item.amount);

      final cashlessIncome = currentMonthIncome
          .where((income) => income.paymentMethod == 'cashless')
          .fold(0, (sum, item) => sum + item.amount);

      // Tambahkan net transfer amount
      final netCashTransfer = await DBHelper.instance.getNetTransferAmount(
        'cash',
        currentMonth,
      );
      final netCashlessTransfer = await DBHelper.instance.getNetTransferAmount(
        'cashless',
        currentMonth,
      );

      setState(() {
        incomeList = currentMonthIncome;
        totalIncome = currentMonthIncome.fold(
          0,
          (sum, item) => sum + item.amount,
        );
        totalCashIncome = cashIncome + netCashTransfer; // tambah net transfer
        totalCashlessIncome =
            cashlessIncome + netCashlessTransfer; // tambah net transfer
      });
    } catch (e) {
      print('Error loading income: $e');
    }
  }

  Future<void> _addIncome() async {
    if (_incomeController.text.isEmpty) return;

    try {
      final amount = CurrencyHelper.parseRupiah(_incomeController.text);
      if (amount <= 0) {
        _showSnackBar('Masukkan jumlah yang valid', isError: true);
        return;
      }

      final transaction = TransactionModel(
        title: 'Pendapatan $_selectedPaymentMethod $currentMonthIndonesian',
        amount: amount,
        type: 'income',
        paymentMethod:
            _selectedPaymentMethod, // gunakan payment method yang dipilih
        date: DateTime.now().toIso8601String(),
      );

      await DBHelper.instance.insertTransaction(transaction);
      _incomeController.clear();
      await _loadIncome();
      _balanceAnimationController.reset();
      _balanceAnimationController.forward();

      _showSnackBar('Pendapatan berhasil ditambahkan');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _addExpense() async {
    if (_expenseNameController.text.isEmpty ||
        _expenseAmountController.text.isEmpty) {
      _showSnackBar('Mohon isi semua field', isError: true);
      return;
    }

    try {
      final amount = CurrencyHelper.parseRupiah(_expenseAmountController.text);
      if (amount <= 0) {
        _showSnackBar('Masukkan jumlah yang valid', isError: true);
        return;
      }

      final transaction = TransactionModel(
        title: _expenseNameController.text,
        amount: amount,
        type: 'expense',
        paymentMethod: _selectedExpensePaymentMethod,
        date: DateTime.now().toIso8601String(),
      );

      await DBHelper.instance.insertTransaction(transaction);
      _expenseNameController.clear();
      _expenseAmountController.clear();
      await _loadExpenses();
      _balanceAnimationController.reset();
      _balanceAnimationController.forward();

      _showSnackBar('Pengeluaran berhasil ditambahkan');

      // Check daily target after adding expense
      await _checkDailyExpenseTarget();
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  int get remainingBalance => totalIncome - totalExpenses;
  int get remainingCashBalance => totalCashIncome - totalCashExpenses;
  int get remainingCashlessBalance =>
      totalCashlessIncome - totalCashlessExpenses;

  Widget _buildBalanceCard() {
    return AnimatedBuilder(
      animation: _balanceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _balanceAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: remainingBalance >= 0
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color:
                      (remainingBalance >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        remainingBalance >= 0
                            ? Icons.account_balance_wallet
                            : Icons.warning,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currentMonthIndonesian,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Saldo',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyHelper.formatRupiah(remainingBalance),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Saldo Cash dan Cashless
                Row(
                  children: [
                    _buildBalanceTypeStat(
                      'Saldo Cash',
                      totalCashIncome - totalCashExpenses,
                      Icons.money,
                    ),
                    const SizedBox(width: 12),
                    _buildBalanceTypeStat(
                      'Saldo Cashless',
                      totalCashlessIncome - totalCashlessExpenses,
                      Icons.credit_card,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total Income dan Expense
                Row(
                  children: [
                    _buildMiniStat(
                      'Total Pendapatan',
                      totalIncome,
                      Icons.trending_up,
                    ),
                    const SizedBox(width: 16),
                    _buildMiniStat(
                      'Pengeluaran',
                      totalExpenses,
                      Icons.trending_down,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Transfer Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showTransferDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    label: Text(
                      'Transfer Saldo',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Daily Target Info & Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getFormattedTodayDate(),
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Harian',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dailyExpenseTarget != null
                                      ? CurrencyHelper.formatRupiah(
                                          dailyExpenseTarget!,
                                        )
                                      : 'Belum diatur',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (dailyExpenseTarget != null) ...[
                            FutureBuilder<int>(
                              future: DBHelper.instance.getDailyExpenses(
                                DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              ),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                final todayExpenses = snapshot.data!;
                                final isOverBudget =
                                    todayExpenses > dailyExpenseTarget!;
                                final percentage = dailyExpenseTarget! > 0
                                    ? (todayExpenses /
                                              dailyExpenseTarget! *
                                              100)
                                          .clamp(0, 100)
                                    : 0.0;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOverBudget
                                        ? const Color(
                                            0xFFEF4444,
                                          ).withOpacity(0.9)
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyHelper.formatRupiah(
                                          todayExpenses,
                                        ),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showSetDailyTargetDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            dailyExpenseTarget != null ? Icons.edit : Icons.add,
                            size: 18,
                          ),
                          label: Text(
                            dailyExpenseTarget != null
                                ? 'Ubah Target'
                                : 'Atur Target Harian',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceTypeStat(String label, int amount, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              CurrencyHelper.formatRupiah(amount),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int amount, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              CurrencyHelper.formatRupiah(amount),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: 'Pengeluaran',
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 24,
                    color: _selectedTabIndex == 0
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Tooltip(
              message: 'Pendapatan',
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 1
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 24,
                    color: _selectedTabIndex == 1
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Tooltip(
              message: 'Transfer',
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 2
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    size: 24,
                    color: _selectedTabIndex == 2
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Moneyge',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              Text(
                'by azril',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Balance Card
              _buildBalanceCard(),
              const SizedBox(height: 24),

              // Segmented Control
              _buildModernSegmentedControl(),
              const SizedBox(height: 24),

              // Content based on selected tab
              if (_selectedTabIndex == 0) ...[
                _buildExpenseSection(),
              ] else if (_selectedTabIndex == 1) ...[
                _buildIncomeSection(),
              ] else ...[
                _buildTransferSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Saldo dengan layout yang lebih rapi
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Transfer Saldo',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Saldo Info
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.money,
                                color: Colors.white.withOpacity(0.9),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cash',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            CurrencyHelper.formatRupiah(
                              totalCashIncome - totalCashExpenses,
                            ),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.credit_card,
                                color: Colors.white.withOpacity(0.9),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cashless',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            CurrencyHelper.formatRupiah(
                              totalCashlessIncome - totalCashlessExpenses,
                            ),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form Transfer
              TextField(
                controller: _transferAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsSeparatorInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Jumlah Transfer',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _transferDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (Opsional)',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),

              // Transfer Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _transferCashlessToCash,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Cashless ke Cash',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _transferCashToCashless,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Cash ke Cashless',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Transfer History
        if (transfers.isNotEmpty) ...[
          Text(
            'Riwayat Transfer',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          ...transfers.map((transfer) => _buildTransferCard(transfer)),
        ] else ...[
          _buildEmptyState('Belum ada transfer bulan ini', Icons.swap_horiz),
        ],
      ],
    );
  }

  Widget _buildTransferCard(Map<String, dynamic> transfer) {
    final isFromCash = transfer['from_method'] == 'cash';
    final fromMethod = isFromCash ? 'Cash' : 'Cashless';
    final toMethod = isFromCash ? 'Cashless' : 'Cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.swap_horiz,
              color: Theme.of(context).colorScheme.tertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer $fromMethod ke $toMethod',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (transfer['description'] != null &&
                    transfer['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transfer['description'].toString(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(DateTime.parse(transfer['date'])),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyHelper.formatRupiah(transfer['amount']),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _deleteTransfer(transfer['id']),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.delete,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Expense Form
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_shopping_cart,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tambah Pengeluaran',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  TextField(
                    controller: _expenseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pengeluaran',
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _expenseAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedExpensePaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Metode Pembayaran',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(
                        value: 'cashless',
                        child: Text('Cashless'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedExpensePaymentMethod = newValue ?? 'cash';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addExpense,
                  child: const Text('Tambah Pengeluaran'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Expenses List
        if (expenses.isNotEmpty) ...[
          Text(
            'Pengeluaran Bulan Ini',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          ...expenses.map((expense) => _buildTransactionCard(expense, false)),
        ] else ...[
          _buildEmptyState(
            'Belum ada pengeluaran bulan ini',
            Icons.shopping_cart_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildIncomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Income Form
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_card,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tambah Pendapatan',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Pendapatan',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Pendapatan',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(
                        value: 'cashless',
                        child: Text('Cashless'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPaymentMethod = newValue ?? 'cash';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: const Text('Tambah Pendapatan'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Income List
        if (incomeList.isNotEmpty) ...[
          Text(
            'Pendapatan Bulan Ini',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          ...incomeList.map((income) => _buildTransactionCard(income, true)),
        ] else ...[
          _buildEmptyState(
            'Belum ada pendapatan bulan ini',
            Icons.account_balance_wallet_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction, bool isIncome) {
    // Cek apakah ini adalah transfer saldo dari bulan sebelumnya
    bool isTransferredBalance = transaction.title.startsWith('Sisa');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  (isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
              color: isIncome
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(DateTime.parse(transaction.date)),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyHelper.formatRupiah(transaction.amount),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isIncome
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tampilkan tombol edit hanya untuk expense yang bukan transfer
                  if (!isIncome && !isTransferredBalance) ...[
                    InkWell(
                      onTap: () => _editExpense(transaction),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Tombol delete selalu ada tapi dengan konfirmasi khusus untuk transfer
                  InkWell(
                    onTap: () => isIncome
                        ? _deleteIncome(transaction.id!, isTransferredBalance)
                        : _deleteExpense(transaction.id!),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.delete,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    final expense = expenses.firstWhere((item) => item.id == id);

    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Hapus',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus pengeluaran ini?',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyHelper.formatRupiah(expense.amount),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await DBHelper.instance.deleteTransaction(id);
        await _loadExpenses();
        _balanceAnimationController.reset();
        _balanceAnimationController.forward();
        _showSnackBar('Pengeluaran berhasil dihapus');

        // Reset warning karena pengeluaran berkurang
        setState(() {
          hasShownDailyWarning = false;
        });
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  // Method yang diperbarui untuk menangani penghapusan transfer dengan benar
  Future<void> _deleteIncome(int id, bool isTransferredBalance) async {
    final income = incomeList.firstWhere((item) => item.id == id);

    String confirmationMessage = isTransferredBalance
        ? 'Apakah Anda yakin ingin menghapus sisa saldo dari bulan sebelumnya?\n\nPerhatian: Saldo ini tidak akan otomatis muncul kembali jika dihapus.'
        : 'Apakah Anda yakin ingin menghapus pendapatan ini?';

    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Hapus',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(confirmationMessage, style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    income.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyHelper.formatRupiah(income.amount),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        if (isTransferredBalance) {
          // Untuk transfer balance, gunakan method khusus yang menandai penolakan
          await DBHelper.instance.deleteTransferredBalanceAndMarkRejected(
            id,
            currentMonth,
          );
        } else {
          // Untuk income biasa, hapus seperti biasa
          await DBHelper.instance.deleteTransaction(id);
        }

        await _loadIncome();
        _balanceAnimationController.reset();
        _balanceAnimationController.forward();
        _showSnackBar(
          isTransferredBalance
              ? 'Sisa saldo berhasil dihapus dan tidak akan muncul lagi'
              : 'Pendapatan berhasil dihapus',
        );
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _editExpense(TransactionModel expense) async {
    final nameController = TextEditingController(text: expense.title);
    final amountController = TextEditingController(
      text: CurrencyHelper.formatRupiahWithoutSymbol(expense.amount),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Pengeluaran',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pengeluaran',
                prefixIcon: Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'ujunmkagi',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  amountController.text.isEmpty) {
                _showSnackBar('Mohon isi semua field', isError: true);
                return;
              }

              try {
                final amount = CurrencyHelper.parseRupiah(
                  amountController.text,
                );
                if (amount <= 0) {
                  _showSnackBar('Masukkan jumlah yang valid', isError: true);
                  return;
                }

                final updatedExpense = TransactionModel(
                  id: expense.id,
                  title: nameController.text,
                  amount: amount,
                  type: 'expense',
                  date: expense.date,
                );

                await DBHelper.instance.updateTransaction(updatedExpense);
                await _loadExpenses();
                _balanceAnimationController.reset();
                _balanceAnimationController.forward();

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Pengeluaran berhasil diupdate');
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Error: ${e.toString()}', isError: true);
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    _transferAmountController.dispose();
    _transferDescriptionController.dispose(); // tambah baris ini
    _balanceAnimationController.dispose();
    super.dispose();
  }
}

// Input formatter untuk menambahkan titik sebagai pemisah ribuan
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final formatter = NumberFormat('#,##0', 'id_ID');
    final formattedText = formatter.format(int.parse(digitsOnly));

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
