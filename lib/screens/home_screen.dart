import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/screens/history_screen.dart';
import 'package:expense_tracker/screens/reports_screen.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/services/recurring_expense_service.dart';
import 'package:expense_tracker/screens/recurring_expense_screen.dart';
import 'package:expense_tracker/screens/goals_screen.dart';
import 'package:expense_tracker/services/sms_service.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _expenseService = ExpenseService();
  int _currentIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    RecurringExpenseService().processDueExpenses();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getUserName();
    setState(() => _userName = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          const HistoryScreen(),
          const ReportsScreen(),
          const RecurringExpenseScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
                setState(() {});
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildHomePage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hamburger menu
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $_userName! 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Total Spending Card
            StreamBuilder<List<ExpenseModel>>(
              stream: _expenseService.getExpenses(),
              builder: (context, snapshot) {
                final expenses = snapshot.data ?? [];
                final now = DateTime.now();

                final monthExpenses = expenses
                    .where(
                      (e) =>
                          e.date.month == now.month && e.date.year == now.year,
                    )
                    .toList();

                final todayExpenses = expenses
                    .where(
                      (e) =>
                          e.date.day == now.day &&
                          e.date.month == now.month &&
                          e.date.year == now.year,
                    )
                    .toList();

                final monthExpenseTotal = monthExpenses
                    .where((e) => e.isExpense)
                    .fold(0.0, (sum, e) => sum + e.amount);
                final monthIncomeTotal = monthExpenses
                    .where((e) => e.isIncome)
                    .fold(0.0, (sum, e) => sum + e.amount);
                final monthTotal = monthExpenseTotal;
                final monthlySavings = monthIncomeTotal - monthExpenseTotal;
                final todayTotal = todayExpenses
                    .where((e) => e.isExpense)
                    .fold(0.0, (sum, e) => sum + e.amount);

                return Column(
                  children: [
                    // Month Total Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This Month',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Income vs Expense Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '💸 Expense',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '₹${monthExpenseTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '💰 Income',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '₹${monthIncomeTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFF86EFAC),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Savings
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🏦 Savings: ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '₹${monthlySavings.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: monthlySavings >= 0
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFFCA5A5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildMiniStat(
                                'Today',
                                '₹${todayTotal.toStringAsFixed(0)}',
                              ),
                              const SizedBox(width: 24),
                              _buildMiniStat(
                                'Transactions',
                                '${monthExpenses.length}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Budget Alert ← ADD FROM HERE
                    _buildBudgetAlert(monthTotal),
                    const SizedBox(height: 8),

                    // ← ADD UNTIL HERE
                    _buildCategorySummary(monthExpenses),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _currentIndex = 1),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    expenses.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: expenses
                                .take(5)
                                .map((e) => _buildExpenseCard(e))
                                .toList(),
                          ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySummary(List<ExpenseModel> expenses) {
    Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    if (categoryTotals.isEmpty) return const SizedBox();
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: top.map((entry) {
            final cat = AppCategories.categories.firstWhere(
              (c) => c['name'] == entry.key,
              orElse: () => AppCategories.categories.last,
            );
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final allCats = [
      ...AppCategories.categories,
      ...IncomeCategories.categories,
    ];
    final cat = allCats.firstWhere(
      (c) => c['name'] == expense.category,
      orElse: () => AppCategories.categories.last,
    );
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text('Delete "${expense.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await _expenseService.deleteExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted!'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(cat['icon'], style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 15,
                    ),
                  ),
                  if (expense.note.isNotEmpty)
                    Text(
                      expense.note,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    '${expense.category} • ${DateFormat('MMM d').format(expense.date)}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  expense.isIncome
                      ? '+₹${expense.amount.toStringAsFixed(2)}'
                      : '-₹${expense.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: expense.isIncome
                        ? AppColors.secondary
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                // Edit button
                GestureDetector(
                  onTap: () => _showEditDialog(expense),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(ExpenseModel expense) async {
    final titleController = TextEditingController(text: expense.title);
    final amountController = TextEditingController(
      text: expense.amount.toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: expense.note);
    String selectedCategory = expense.category;
    String selectedIcon = expense.categoryIcon;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Edit Expense",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: "Note",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text) ?? expense.amount;
                  final updated = ExpenseModel(
                    id: expense.id,
                    userId: expense.userId,
                    title: titleController.text.trim().isEmpty
                        ? expense.title
                        : titleController.text.trim(),
                    amount: amount,
                    category: selectedCategory,
                    categoryIcon: selectedIcon,
                    note: noteController.text.trim(),
                    date: expense.date,
                    createdAt: expense.createdAt,
                  );
                  await _expenseService.updateExpense(updated);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Expense updated! ✅"),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: const [
          SizedBox(height: 40),
          Text('💸', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text(
            'No expenses yet!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + to add your first expense',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlert(double monthTotal) {
    return FutureBuilder<double>(
      future: _getBudget(),
      builder: (context, snapshot) {
        final budget = snapshot.data ?? 0.0;
        if (budget <= 0) return const SizedBox();

        final percentage = monthTotal / budget;
        final remaining = budget - monthTotal;

        Color alertColor;
        String alertMessage;
        IconData alertIcon;

        if (percentage >= 1.0) {
          alertColor = AppColors.error;
          alertMessage =
              '⚠️ Budget exceeded by ₹${(monthTotal - budget).toStringAsFixed(0)}!';
          alertIcon = Icons.warning_rounded;
        } else if (percentage >= 0.8) {
          alertColor = AppColors.warning;
          alertMessage =
              '🔔 80% of budget used! ₹${remaining.toStringAsFixed(0)} remaining';
          alertIcon = Icons.notifications_active;
        } else {
          alertColor = AppColors.secondary;
          alertMessage =
              '✅ On track! ₹${remaining.toStringAsFixed(0)} remaining this month';
          alertIcon = Icons.check_circle_outline;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: alertColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: alertColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(alertIcon, color: alertColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alertMessage,
                      style: TextStyle(
                        color: alertColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage > 1.0 ? 1.0 : percentage,
                        backgroundColor: alertColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(alertColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${monthTotal.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: alertColor.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<double> _getBudget() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_authService.currentUser!.uid)
          .get();
      return (doc['monthlyBudget'] ?? 0.0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _showSmsScanDialog() async {
    final smsService = SmsService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Scanning SMS...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Reading last 7 days of SMS'),
          ],
        ),
      ),
    );

    final detected = await smsService.scanRecentSms();
    Navigator.pop(context);

    if (detected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bank transactions found in SMS')),
      );
      return;
    }

    // Show detected transactions
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selected = List<bool>.filled(detected.length, true);
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Found ${detected.length} transactions'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: detected.length,
                itemBuilder: (context, index) {
                  final tx = detected[index];
                  return CheckboxListTile(
                    value: selected[index],
                    onChanged: (val) =>
                        setDialogState(() => selected[index] = val ?? true),
                    title: Text(tx['title']),
                    subtitle: Text(
                      '₹${tx['amount']} • ${tx['type']} • ${tx['category']}',
                    ),
                    secondary: Text(
                      tx['type'] == 'income' ? '💰' : '💸',
                      style: const TextStyle(fontSize: 24),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  int count = 0;
                  for (int i = 0; i < detected.length; i++) {
                    if (selected[i]) {
                      final tx = detected[i];
                      final expense = ExpenseModel(
                        id: const Uuid().v4(),
                        userId: _authService.currentUser!.uid,
                        title: tx['title'],
                        amount: tx['amount'],
                        category: tx['category'],
                        categoryIcon: '📱',
                        note: 'Auto-detected from SMS',
                        date: tx['date'],
                        createdAt: DateTime.now(),
                        type: tx['type'],
                        paymentMode: tx['paymentMode'],
                      );
                      await _expenseService.addExpense(expense);
                      count++;
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count transactions added! ✅'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Add Selected'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Smart Expense Tracker',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    index: 0,
                    color: AppColors.primary,
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: 'History',
                    index: 1,
                    color: const Color(0xFF8B5CF6),
                  ),
                  _buildDrawerItem(
                    icon: Icons.pie_chart_rounded,
                    title: 'Reports',
                    index: 2,
                    color: AppColors.secondary,
                  ),
                  _buildDrawerItem(
                    icon: Icons.repeat_rounded,
                    title: 'Recurring Expenses',
                    index: 3,
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecurringExpenseScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.sms_rounded,
                    title: 'Scan SMS',
                    index: -1,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      _showSmsScanDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.flag_rounded,
                    title: 'Savings Goals',
                    index: -1,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GoalsScreen()),
                      );
                    },
                  ),

                  const Divider(indent: 16, endIndent: 16),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    index: 4,
                    color: Colors.grey,
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    index: -1,
                    color: AppColors.error,
                    onTap: () async {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _authService.logout();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Smart Expense Tracker v1.0.0\n🇮🇳 Made in India',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : null,
          ),
        ),
        onTap:
            onTap ??
            () {
              setState(() => _currentIndex = index);
              Navigator.pop(context);
            },
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Recurring'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
