class TaskModel {
  final int? id;
  final String title;
  final String? description;
  final String? category;
  final String? tags;
  final String status;
  final String priority;
  final String? dueDate;
  final String createdAt;
  final String updatedAt;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    this.category,
    this.tags,
    this.status = 'in_progress',
    this.priority = 'medium',
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'status': status,
      'priority': priority,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'],
      tags: map['tags'],
      status: map['status'] ?? 'in_progress',
      priority: map['priority'] ?? 'medium',
      dueDate: map['dueDate'],
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? tags,
    String? status,
    String? priority,
    String? dueDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
