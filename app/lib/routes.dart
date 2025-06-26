import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/add_entry/add_entry_page.dart';
import 'features/history/history_page.dart';
import 'features/category/category_page.dart';
import 'features/settings/settings_page.dart';
import 'features/dashboard/dashboard_tabs_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute( path: '/'          , name: 'dashboard', builder: (_, __) => const DashboardPage(),),
      GoRoute( path: '/category'  , name: 'category' , builder: (_, __) => const CategoryPage(),),
      GoRoute( path: '/settings'  , name: 'settings' , builder: (_, __) => const SettingsPage(),),
      GoRoute( path: '/add/:catId', name: 'addCat'   , builder: (context, state) => AddEntryPage(fixedCatId: state.pathParameters['catId']!),),
      GoRoute(
        path: '/history/:catId',
        name: 'history',
        builder: (context, state) {
          final catId = state.pathParameters['catId'];
          if (catId == null || catId.isEmpty) {
            // パラメータが無い／空の場合はエラーページを表示
            return const Scaffold(
              body: Center(child: Text('カテゴリ ID が取得できません')),
            );
          }
          return HistoryPage(catId: catId);
        },
      ),

    ],
  );
});
