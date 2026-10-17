@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mahad_task_manager/features/tasks/data/task_repository.dart';

import '../../helpers/test_helpers.dart';

// DatabaseHelper keeps one open database per test isolate, so the tests in
// this file share a database and use distinct users to stay independent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TaskRepository repo;

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('taskpulse_test');
    addTearDown(() => dir.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // A database created by version 1 of the schema, before tasks had owners.
    final v1 = await openDatabase(
      p.join(dir.path, 'TaskPulse.db'),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          category TEXT,
          tags TEXT,
          status TEXT NOT NULL DEFAULT 'in_progress',
          priority TEXT NOT NULL DEFAULT 'medium',
          dueDate TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      '''),
    );
    await v1.insert('tasks', task('Legacy task').toMap()..remove('userId'));
    await v1.close();

    repo = TaskRepository(await mockPrefs());
  });

  test('upgrading from v1 keeps old tasks and gives them to the first user', () async {
    final tasks = await repo.getAllTasks('first@example.com');
    expect(tasks.map((t) => t.title), ['Legacy task']);
    expect(tasks.single.userId, 'first@example.com');
    expect(await repo.getAllTasks('second@example.com'), isEmpty);
  });

  test('insert stamps the owner and lists newest first', () async {
    await repo.insert(task('Older', createdAt: '2026-01-01T00:00:00.000'), 'alice');
    await repo.insert(task('Newer', createdAt: '2026-01-02T00:00:00.000'), 'alice');

    final tasks = await repo.getAllTasks('alice');
    expect(tasks.map((t) => t.title), ['Newer', 'Older']);
    expect(tasks.every((t) => t.userId == 'alice'), isTrue);
  });

  test('update and delete only affect the owner\'s tasks', () async {
    final id = await repo.insert(task('Bob\'s task'), 'bob');

    expect(await repo.update(task('Hijacked', id: id), 'mallory'), 0);
    expect(await repo.delete(id, 'mallory'), 0);
    expect((await repo.getAllTasks('bob')).single.title, 'Bob\'s task');

    expect(await repo.update(task('Done', id: id, status: 'completed'), 'bob'), 1);
    final updated = (await repo.getAllTasks('bob')).single;
    expect(updated.title, 'Done');
    expect(updated.status, 'completed');

    expect(await repo.delete(id, 'bob'), 1);
    expect(await repo.getAllTasks('bob'), isEmpty);
  });
}
