import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task_model.dart';
import '../data/task_repository.dart';
import 'task_list_screen.dart'; // To invalidate the list provider

class TaskController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> addTask(TaskModel task) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.insert(task);
      ref.invalidate(taskListProvider);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.update(task);
      ref.invalidate(taskListProvider);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.delete(id);
      ref.invalidate(taskListProvider);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final taskControllerProvider = NotifierProvider<TaskController, AsyncValue<void>>(TaskController.new);
