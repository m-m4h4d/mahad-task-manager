import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../tasks/presentation/task_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TaskListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('TaskPulse', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: !kIsWeb,
        actions: kIsWeb
            ? [
                TextButton.icon(
                  onPressed: () => setState(() => _currentIndex = 0),
                  icon: Icon(
                    _currentIndex == 0 ? Icons.task : Icons.task_outlined,
                    color: _currentIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                  ),
                  label: Text(
                    'Tasks',
                    style: TextStyle(
                      color: _currentIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      fontWeight: _currentIndex == 0 ? FontWeight.bold : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: Icon(
                    _currentIndex == 1 ? Icons.person : Icons.person_outline,
                    color: _currentIndex == 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                  ),
                  label: Text(
                    'Profile',
                    style: TextStyle(
                      color: _currentIndex == 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      fontWeight: _currentIndex == 1 ? FontWeight.bold : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ref.read(themeControllerProvider.notifier).toggleTheme(),
                  icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                ),
                const SizedBox(width: 16),
              ]
            : null,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: kIsWeb
          ? null
          : NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            ref.read(themeControllerProvider.notifier).toggleTheme();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            label: 'Theme',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-task');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ) : null,
    );
  }
}
