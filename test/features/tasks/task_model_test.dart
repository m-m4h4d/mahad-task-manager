import 'package:flutter_test/flutter_test.dart';
import 'package:mahad_task_manager/features/tasks/domain/task_model.dart';

void main() {
  final full = TaskModel(
    id: 7,
    userId: 'alice@example.com',
    title: 'Write report',
    description: 'Quarterly numbers',
    category: 'Work',
    tags: 'q3,finance',
    status: 'completed',
    priority: 'high',
    dueDate: '2026-02-01',
    createdAt: '2026-01-01T09:00:00.000',
    updatedAt: '2026-01-02T09:00:00.000',
  );

  test('toMap and fromMap round-trip every field', () {
    final copy = TaskModel.fromMap(full.toMap());
    expect(copy.toMap(), full.toMap());
  });

  test('toMap omits id when it is not set', () {
    final map = full.copyWith().toMap()..remove('id');
    expect(TaskModel.fromMap(map).toMap().containsKey('id'), isFalse);
  });

  test('fromMap applies defaults for missing fields', () {
    final model = TaskModel.fromMap({'title': 'Bare'});
    expect(model.id, isNull);
    expect(model.userId, isNull);
    expect(model.status, 'in_progress');
    expect(model.priority, 'medium');
    expect(model.createdAt, '');
  });

  test('copyWith replaces only the given fields', () {
    final updated = full.copyWith(status: 'in_progress', title: 'Rewrite report');
    expect(updated.status, 'in_progress');
    expect(updated.title, 'Rewrite report');
    expect(updated.id, full.id);
    expect(updated.userId, full.userId);
    expect(updated.priority, full.priority);
  });
}
