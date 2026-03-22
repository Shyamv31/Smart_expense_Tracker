import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/recurring_expense_model.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:uuid/uuid.dart';

class RecurringExpenseService {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  final _expenseService = ExpenseService();

  String get _uid => _authService.currentUser!.uid;

  CollectionReference get _collection =>
      _firestore.collection('users').doc(_uid).collection('recurring_expenses');

  Stream<List<RecurringExpenseModel>> getRecurringExpenses() {
    return _collection.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) => RecurringExpenseModel.fromMap(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Future<void> addRecurringExpense(RecurringExpenseModel expense) async {
    await _collection.doc(expense.id).set(expense.toMap());
  }

  Future<void> deleteRecurringExpense(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> toggleActive(RecurringExpenseModel expense) async {
    await _collection.doc(expense.id).update({'isActive': !expense.isActive});
  }

  // Check and add due recurring expenses
  Future<void> processDueExpenses() async {
    final snap = await _collection.where('isActive', isEqualTo: true).get();

    final now = DateTime.now();
    for (final doc in snap.docs) {
      final recurring = RecurringExpenseModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );
      if (recurring.nextDueDate.isBefore(now) ||
          _isSameDay(recurring.nextDueDate, now)) {
        // Add as regular expense
        final expense = ExpenseModel(
          id: const Uuid().v4(),
          userId: _uid,
          title: recurring.title,
          amount: recurring.amount,
          category: recurring.category,
          categoryIcon: recurring.categoryIcon,
          note: '🔄 Recurring: ${recurring.note}',
          date: now,
          createdAt: now,
        );
        await _expenseService.addExpense(expense);

        // Update next due date
        final nextDue = _getNextDueDate(
          recurring.nextDueDate,
          recurring.frequency,
        );
        await _collection.doc(recurring.id).update({
          'nextDueDate': nextDue.toIso8601String(),
        });
      }
    }
  }

  DateTime _getNextDueDate(DateTime current, String frequency) {
    switch (frequency) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(current.year, current.month + 1, current.day);
      default:
        return current.add(const Duration(days: 30));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
