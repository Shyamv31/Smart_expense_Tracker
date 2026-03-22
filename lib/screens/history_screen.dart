import 'package:flutter/material.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _expenseService = ExpenseService();
  String _selectedCategory = 'All';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'All'),
            Tab(icon: Icon(Icons.arrow_upward_rounded), text: 'Expense'),
            Tab(icon: Icon(Icons.arrow_downward_rounded), text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionList('all'),
          _buildTransactionList('expense'),
          _buildTransactionList('income'),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String type) {
    return Column(
      children: [
        Container(
          color: AppColors.primary,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                if (type == 'all' || type == 'expense')
                  ...AppCategories.categories.map(
                    (c) => _buildFilterChip(c['name']),
                  ),
                if (type == 'income')
                  ...IncomeCategories.categories.map(
                    (c) => _buildFilterChip(c['name']),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ExpenseModel>>(
            stream: _expenseService.getExpenses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allExpenses = snapshot.data ?? [];
              var expenses = type == 'all'
                  ? allExpenses
                  : allExpenses.where((e) => e.type == type).toList();
              if (_selectedCategory != 'All') {
                expenses = expenses
                    .where((e) => e.category == _selectedCategory)
                    .toList();
              }
              if (expenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        type == 'income' ? '💰' : '💸',
                        style: const TextStyle(fontSize: 50),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        type == 'income'
                            ? 'No income records found'
                            : 'No transactions found',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                );
              }
              Map<String, List<ExpenseModel>> grouped = {};
              for (var e in expenses) {
                final key = DateFormat('MMM d, yyyy').format(e.date);
                grouped[key] = [...(grouped[key] ?? []), e];
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final date = grouped.keys.elementAt(index);
                  final dayExpenses = grouped[date]!;
                  final dayIncome = dayExpenses
                      .where((e) => e.isIncome)
                      .fold(0.0, (sum, e) => sum + e.amount);
                  final dayExpenseTotal = dayExpenses
                      .where((e) => e.isExpense)
                      .fold(0.0, (sum, e) => sum + e.amount);
                  final dayTotal = dayIncome - dayExpenseTotal;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              date,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              type == 'income'
                                  ? '+₹${dayIncome.toStringAsFixed(2)}'
                                  : type == 'expense'
                                  ? '-₹${dayExpenseTotal.toStringAsFixed(2)}'
                                  : '${dayTotal >= 0 ? '+' : ''}₹${dayTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: type == 'income'
                                    ? AppColors.secondary
                                    : type == 'expense'
                                    ? AppColors.error
                                    : dayTotal >= 0
                                    ? AppColors.secondary
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...dayExpenses.map(
                        (expense) => _buildExpenseCard(expense),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
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
              'Edit Transaction',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
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
                      labelText: 'Amount (₹)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Note',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        [
                          ...AppCategories.categories,
                          ...IncomeCategories.categories,
                        ].map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['name'] as String,
                            child: Text('${cat['icon']} ${cat['name']}'),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedCategory = value;
                          final allCats = [
                            ...AppCategories.categories,
                            ...IncomeCategories.categories,
                          ];
                          selectedIcon = allCats.firstWhere(
                            (c) => c['name'] == value,
                            orElse: () => AppCategories.categories.last,
                          )['icon'];
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
                    type: expense.type,
                  );
                  await _expenseService.updateExpense(updated);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction updated! ✅'),
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
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getPaymentIcon(String mode) {
    switch (mode) {
      case 'card':
        return '💳 Card';
      case 'upi':
        return '📱 UPI';
      case 'netbanking':
        return '🏦 Net Banking';
      default:
        return '💵 Cash';
    }
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
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
            title: const Text('Delete Transaction'),
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
            content: Text('Transaction deleted!'),
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
                    '${expense.category} • ${DateFormat('MMM d').format(expense.date)} • ${_getPaymentIcon(expense.paymentMode)}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
                if (expense.note != 'Auto-detected from SMS')
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
}
