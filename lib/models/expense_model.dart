class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final String categoryIcon;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final String type; // 'expense' or 'income'
  final String paymentMode; // cash, card, upi, netbanking

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    this.note = '',
    required this.date,
    required this.createdAt,
    this.type = 'expense',
    this.paymentMode = 'cash',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'categoryIcon': categoryIcon,
      'note': note,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'paymentMode': paymentMode,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      categoryIcon: map['categoryIcon'],
      note: map['note'] ?? '',
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
      type: map['type'] ?? 'expense',
      paymentMode: map['paymentMode'] ?? 'cash',
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
