import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'tabs/dashboard_cards_tab.dart';
import 'tabs/plot_tab.dart';
import 'tabs/history_tab.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.view_agenda), text: 'カード'),
              Tab(icon: Icon(Icons.show_chart), text: 'Plot'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/category'),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            DashboardCardsTab(), // 直接入力できる既存カード
            PlotTab(),           // 新しいグラフタブ
            HistoryTab(),        // History プレースホルダ
          ],
        ),
      ),
    );
  }
}
