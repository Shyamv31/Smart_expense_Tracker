class RecurringExpenseModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final String categoryIcon;
  final String note;
  final String frequency; // daily, weekly, monthly
  final DateTime startDate;
  final DateTime nextDueDate;
  final bool isActive;

  RecurringExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    required this.note,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'amount': amount,
    'category': category,
    'categoryIcon': categoryIcon,
    'note': note,
    'frequency': frequency,
    'startDate': startDate.toIso8601String(),
    'nextDueDate': nextDueDate.toIso8601String(),
    'isActive': isActive,
  };

  factory RecurringExpenseModel.fromMap(Map<String, dynamic> map) =>
      RecurringExpenseModel(
        id: map['id'],
        userId: map['userId'],
        title: map['title'],
        amount: map['amount'].toDouble(),
        category: map['category'],
        categoryIcon: map['categoryIcon'],
        note: map['note'] ?? '',
        frequency: map['frequency'],
        startDate: DateTime.parse(map['startDate']),
        nextDueDate: DateTime.parse(map['nextDueDate']),
        isActive: map['isActive'] ?? true,
      );

  RecurringExpenseModel copyWith({bool? isActive, DateTime? nextDueDate}) =>
      RecurringExpenseModel(
        id: id,
        userId: userId,
        title: title,
        amount: amount,
        category: category,
        categoryIcon: categoryIcon,
        note: note,
        frequency: frequency,
        startDate: startDate,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        isActive: isActive ?? this.isActive,
      );
}
