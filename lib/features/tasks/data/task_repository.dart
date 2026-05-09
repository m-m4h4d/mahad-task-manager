import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../domain/task_model.dart';

class TaskRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insert(TaskModel task) async {
    final db = await dbHelper.database;
    return await db.insert(DatabaseHelper.tableTasks, task.toMap());
  }

  Future<List<TaskModel>> getAllTasks() async {
    final db = await dbHelper.database;
    final maps = await db.query(DatabaseHelper.tableTasks, orderBy: '${DatabaseHelper.columnCreatedAt} DESC');
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<int> update(TaskModel task) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.tableTasks,
      task.toMap(),
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableTasks,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});
