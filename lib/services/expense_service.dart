import 'package:image_picker/image_picker.dart';
import 'package:expense_tracker/services/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // Get all expenses stream
  Stream<List<ExpenseModel>> getExpenses() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Add expense
  Future<void> addExpense(ExpenseModel expense) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toMap());
  }

  // Delete expense
  Future<void> deleteExpense(String id) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('expenses')
        .doc(id)
        .delete();
  }

  // Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toMap());
  }
}
