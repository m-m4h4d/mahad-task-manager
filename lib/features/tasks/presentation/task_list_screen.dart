import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/task_model.dart';
import '../data/task_repository.dart';
import 'task_controller.dart';

final taskListProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getAllTasks();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class FilterStatusNotifier extends Notifier<String> {
  @override
  String build() => 'All';
}

final filterStatusProvider = NotifierProvider<FilterStatusNotifier, String>(
  FilterStatusNotifier.new,
);

final filteredTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsyncValue = ref.watch(taskListProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final filterStatus = ref.watch(filterStatusProvider);

  return tasksAsyncValue.whenData((tasks) {
    return tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(searchQuery);
      final matchesStatus =
          filterStatus == 'All' || task.status == filterStatus.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  });
});

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTasksAsync = ref.watch(filteredTasksProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).state = value,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Pending', 'In_progress', 'Completed'].map((
                    status,
                  ) {
                    final currentFilter = ref.watch(filterStatusProvider);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(status.replaceAll('_', ' ')),
                        selected: currentFilter == status,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(filterStatusProvider.notifier).state =
                                status;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredTasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return const EmptyTaskState();
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Dismissible(
                    key: Key(task.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      if (task.id != null) {
                        ref
                            .read(taskControllerProvider.notifier)
                            .deleteTask(task.id!);
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.status == 'completed',
                          onChanged: (value) {
                            if (value != null && task.id != null) {
                              final newStatus = value ? 'completed' : 'in_progress';
                              ref.read(taskControllerProvider.notifier).updateTask(
                                task.copyWith(status: newStatus),
                              );
                            }
                          },
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
                            color: task.status == 'completed' ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          task.description ?? 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Chip(
                          label: Text(
                            task.status,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          context.push('/add-task', extra: task);
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

class EmptyTaskState extends StatelessWidget {
  const EmptyTaskState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No tasks yet!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first task.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
