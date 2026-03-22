class GoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;
  final String icon;
  final String color;
  final String note;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
    required this.icon,
    required this.color,
    this.note = '',
    required this.createdAt,
  });

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => targetAmount - savedAmount;
  bool get isCompleted => savedAmount >= targetAmount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'deadline': deadline.toIso8601String(),
    'icon': icon,
    'color': color,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
    savedAmount: (map['savedAmount'] ?? 0.0).toDouble(),
    deadline: DateTime.parse(map['deadline']),
    icon: map['icon'] ?? '🎯',
    color: map['color'] ?? '0xFF2563EB',
    note: map['note'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
  );

  GoalModel copyWith({double? savedAmount}) => GoalModel(
    id: id,
    userId: userId,
    name: name,
    targetAmount: targetAmount,
    savedAmount: savedAmount ?? this.savedAmount,
    deadline: deadline,
    icon: icon,
    color: color,
    note: note,
    createdAt: createdAt,
  );
}
