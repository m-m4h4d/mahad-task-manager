import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahad_task_manager/features/tasks/domain/task_model.dart';

/// Fresh in-memory SharedPreferences seeded with [values].
Future<SharedPreferences> mockPrefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

TaskModel task(
  String title, {
  int? id,
  String status = 'in_progress',
  String createdAt = '2026-01-01T00:00:00.000',
}) {
  return TaskModel(
    id: id,
    title: title,
    status: status,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
