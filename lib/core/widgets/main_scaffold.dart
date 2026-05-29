import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/providers/alert_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/profile/presentation/profile_screen.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    if (authState.value == null) {
      return Scaffold(body: child);
    }

    final role = ref.watch(userProfileProvider).value?.role ?? 'student';
    final unreadAlerts = ref.watch(unreadAlertsProvider);

    Widget alertIcon({required bool active}) {
      return Badge(
        isLabelVisible: unreadAlerts > 0,
        label: Text('$unreadAlerts'),
        child: Icon(
          active
              ? Icons.notifications_active
              : Icons.notifications_none_outlined,
        ),
      );
    }

    late final List<BottomNavigationBarItem> items;
    late final List<String> tabRoutes;

    if (role == 'admin') {
      items = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_outlined),
          activeIcon: const Icon(Icons.dashboard),
          label: tr('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.group_outlined),
          activeIcon: const Icon(Icons.group),
          label: tr('manage_users_short'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.menu_book_outlined),
          activeIcon: const Icon(Icons.menu_book),
          label: tr('subjects'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment_outlined),
          activeIcon: const Icon(Icons.assignment),
          label: tr('exams'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.summarize_outlined),
          activeIcon: const Icon(Icons.summarize),
          label: tr('reports'),
        ),
        BottomNavigationBarItem(
          icon: alertIcon(active: false),
          activeIcon: alertIcon(active: true),
          label: tr('alerts'),
        ),
      ];
      tabRoutes = [
        '/admin-dashboard',
        '/admin/manage-users',
        '/admin/manage-subjects',
        '/admin/exams',
        '/admin/reports',
        '/alerts',
      ];
    } else if (role == 'teacher') {
      items = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_outlined),
          activeIcon: const Icon(Icons.dashboard),
          label: tr('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.groups_outlined),
          activeIcon: const Icon(Icons.groups),
          label: tr('students'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment_outlined),
          activeIcon: const Icon(Icons.assignment),
          label: tr('exams'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart_outlined),
          activeIcon: const Icon(Icons.bar_chart),
          label: tr('results'),
        ),
        BottomNavigationBarItem(
          icon: alertIcon(active: false),
          activeIcon: alertIcon(active: true),
          label: tr('alerts'),
        ),
      ];
      tabRoutes = [
        '/prof-dashboard',
        '/prof-dashboard/students',
        '/prof-dashboard/exams',
        '/prof-dashboard/results',
        '/alerts',
      ];
    } else {
      items = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_outlined),
          activeIcon: const Icon(Icons.dashboard),
          label: tr('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_toggle_off_rounded),
          activeIcon: const Icon(Icons.history),
          label: tr('history'),
        ),
        BottomNavigationBarItem(
          icon: alertIcon(active: false),
          activeIcon: alertIcon(active: true),
          label: tr('alerts'),
        ),
      ];
      tabRoutes = ['/home', '/history', '/alerts'];
    }

    final location = GoRouterState.of(context).uri.toString();
    var currentIndex = -1;
    var currentMatchLength = -1;
    for (var index = 0; index < tabRoutes.length; index++) {
      final route = tabRoutes[index];
      if (location.startsWith(route) && route.length > currentMatchLength) {
        currentIndex = index;
        currentMatchLength = route.length;
      }
    }
    if (currentIndex == -1) currentIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.school_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(tr('app_name')),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('alerts'),
            onPressed: () => context.go('/alerts'),
            icon: Badge(
              isLabelVisible: unreadAlerts > 0,
              label: Text('$unreadAlerts'),
              child: const Icon(Icons.notifications_none_outlined),
            ),
          ),
          IconButton(
            tooltip: tr('profile'),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(tabRoutes[index]),
        items: items,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
