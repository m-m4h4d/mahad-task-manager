import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahad_task_manager/features/tasks/presentation/task_list_screen.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        taskListProvider.overrideWith((ref) async => [
              task('Buy milk', id: 1),
              task('Book flights', id: 2, status: 'completed'),
              task('Call the bank', id: 3),
            ]),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<List<String>> titles() async {
    await container.read(taskListProvider.future);
    return container.read(filteredTasksProvider).requireValue.map((t) => t.title).toList();
  }

  test('shows every task by default', () async {
    expect(await titles(), ['Buy milk', 'Book flights', 'Call the bank']);
  });

  test('filters by status', () async {
    container.read(filterStatusProvider.notifier).state = 'Completed';
    expect(await titles(), ['Book flights']);

    container.read(filterStatusProvider.notifier).state = 'In_progress';
    expect(await titles(), ['Buy milk', 'Call the bank']);
  });

  test('searches titles case-insensitively', () async {
    container.read(searchQueryProvider.notifier).state = 'BO';
    expect(await titles(), ['Book flights']);
  });

  test('combines search and status filter', () async {
    container.read(searchQueryProvider.notifier).state = 'b';
    expect(await titles(), ['Buy milk', 'Book flights', 'Call the bank']);

    container.read(filterStatusProvider.notifier).state = 'Completed';
    expect(await titles(), ['Book flights']);
  });
}
