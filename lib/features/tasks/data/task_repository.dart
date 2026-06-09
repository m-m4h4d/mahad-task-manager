import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../domain/task_model.dart';

class TaskRepository {
  final dbHelper = DatabaseHelper.instance;

  // In-memory list for web support
  final List<TaskModel> _webTasks = [];
  int _nextWebId = 1;

  Future<int> insert(TaskModel task) async {
    if (kIsWeb) {
      final newTask = task.copyWith(id: _nextWebId++);
      _webTasks.insert(0, newTask);
      return newTask.id!;
    }
    final db = await dbHelper.database;
    return await db.insert(DatabaseHelper.tableTasks, task.toMap());
  }

  Future<List<TaskModel>> getAllTasks() async {
    if (kIsWeb) {
      return List.from(_webTasks);
    }
    final db = await dbHelper.database;
    final maps = await db.query(DatabaseHelper.tableTasks, orderBy: '${DatabaseHelper.columnCreatedAt} DESC');
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<int> update(TaskModel task) async {
    if (kIsWeb) {
      final index = _webTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _webTasks[index] = task;
        return 1;
      }
      return 0;
    }
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.tableTasks,
      task.toMap(),
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int id) async {
    if (kIsWeb) {
      final initialLength = _webTasks.length;
      _webTasks.removeWhere((t) => t.id == id);
      return initialLength - _webTasks.length;
    }
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
