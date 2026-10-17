import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/shared_prefs_service.dart';
import '../domain/task_model.dart';

class TaskRepository {
  final dbHelper = DatabaseHelper.instance;
  final SharedPreferences _prefs;

  // sqflite has no web backend, so on web tasks are persisted as JSON in
  // SharedPreferences (localStorage) and cached in memory.
  static const String _webTasksKey = 'web_tasks';
  late final List<TaskModel> _webTasks = _loadWebTasks();

  TaskRepository(this._prefs);

  List<TaskModel> _loadWebTasks() {
    final raw = _prefs.getString(_webTasksKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Failed to load saved tasks: $e');
      return [];
    }
  }

  Future<void> _saveWebTasks() async {
    await _prefs.setString(
      _webTasksKey,
      jsonEncode(_webTasks.map((t) => t.toMap()).toList()),
    );
  }

  int get _nextWebId => _webTasks.fold<int>(
        0,
        (maxId, t) => (t.id ?? 0) > maxId ? t.id! : maxId,
      ) + 1;

  Future<int> insert(TaskModel task) async {
    if (kIsWeb) {
      final newTask = task.copyWith(id: _nextWebId);
      _webTasks.insert(0, newTask);
      await _saveWebTasks();
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
        await _saveWebTasks();
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
      final removed = initialLength - _webTasks.length;
      if (removed > 0) await _saveWebTasks();
      return removed;
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
  return TaskRepository(ref.watch(sharedPreferencesProvider));
});
