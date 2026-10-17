// Runs only in a browser: flutter test --platform chrome
@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahad_task_manager/features/tasks/data/task_repository.dart';

import '../../helpers/test_helpers.dart';

void main() {
  test('tasks persist across reloads, scoped to their owner', () async {
    final prefs = await mockPrefs({
      // Saved by a version that predates task owners.
      'web_tasks': jsonEncode([task('Legacy task', id: 1).toMap()..remove('userId')]),
    });

    final repo = TaskRepository(prefs);
    expect((await repo.getAllTasks('alice')).map((t) => t.title), ['Legacy task']);
    final bobId = await repo.insert(task('Bob\'s task'), 'bob');
    expect(bobId, 2);
    expect(await repo.delete(bobId, 'alice'), 0);

    // A new repository on the same storage behaves like a page reload.
    final reloaded = TaskRepository(prefs);
    expect((await reloaded.getAllTasks('alice')).map((t) => t.title), ['Legacy task']);
    expect((await reloaded.getAllTasks('bob')).map((t) => t.title), ['Bob\'s task']);
    expect(await reloaded.insert(task('Next'), 'bob'), 3);
  });
}
