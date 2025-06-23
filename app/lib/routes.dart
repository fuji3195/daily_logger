import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/dashboard/dashboard_page.dart';
import 'features/add_entry/add_entry_page.dart';
import 'features/history/history_page.dart';
import 'features/category/category_page.dart';
import 'features/settings/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (_, __) => const DashboardPage(),
      ),
      GoRoute(
        path: '/add',
        name: 'add',
        builder: (_, __) => const AddEntryPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (_, __) => const HistoryPage(),
      ),
      GoRoute(
        path: '/category',
        name: 'category',
        builder: (_, __) => const CategoryPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsPage(),
      ),
    ],
  );
});
