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

  // Every operation is scoped to [userId]: inserts are stamped with it, and
  // reads, updates and deletes only see that user's tasks.
  static const String _ownedBy = '${DatabaseHelper.columnId} = ? AND ${DatabaseHelper.columnUserId} = ?';

  Future<int> insert(TaskModel task, String userId) async {
    final owned = task.copyWith(userId: userId);
    if (kIsWeb) {
      final newTask = owned.copyWith(id: _nextWebId);
      _webTasks.insert(0, newTask);
      await _saveWebTasks();
      return newTask.id!;
    }
    final db = await dbHelper.database;
    return await db.insert(DatabaseHelper.tableTasks, owned.toMap());
  }

  Future<List<TaskModel>> getAllTasks(String userId) async {
    await _claimUnownedTasks(userId);
    if (kIsWeb) {
      return _webTasks.where((t) => t.userId == userId).toList();
    }
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      where: '${DatabaseHelper.columnUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
    );
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<int> update(TaskModel task, String userId) async {
    final owned = task.copyWith(userId: userId);
    if (kIsWeb) {
      final index = _webTasks.indexWhere((t) => t.id == task.id && t.userId == userId);
      if (index != -1) {
        _webTasks[index] = owned;
        await _saveWebTasks();
        return 1;
      }
      return 0;
    }
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.tableTasks,
      owned.toMap(),
      where: _ownedBy,
      whereArgs: [task.id, userId],
    );
  }

  Future<int> delete(int id, String userId) async {
    if (kIsWeb) {
      final initialLength = _webTasks.length;
      _webTasks.removeWhere((t) => t.id == id && t.userId == userId);
      final removed = initialLength - _webTasks.length;
      if (removed > 0) await _saveWebTasks();
      return removed;
    }
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableTasks,
      where: _ownedBy,
      whereArgs: [id, userId],
    );
  }

  /// Tasks saved before tasks were scoped to users have no owner. Hand them
  /// to the first user who loads their tasks so they aren't lost.
  Future<void> _claimUnownedTasks(String userId) async {
    if (kIsWeb) {
      var claimed = false;
      for (var i = 0; i < _webTasks.length; i++) {
        if (_webTasks[i].userId == null) {
          _webTasks[i] = _webTasks[i].copyWith(userId: userId);
          claimed = true;
        }
      }
      if (claimed) await _saveWebTasks();
      return;
    }
    final db = await dbHelper.database;
    await db.update(
      DatabaseHelper.tableTasks,
      {DatabaseHelper.columnUserId: userId},
      where: '${DatabaseHelper.columnUserId} IS NULL',
    );
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(sharedPreferencesProvider));
});
