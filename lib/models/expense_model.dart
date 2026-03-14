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
  });

  // Convert to Firestore map
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
    };
  }

  // Get from Firestore map
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
    );
  }
}