import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repo/category_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryRepoProvider).watchAll();
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: StreamBuilder(
        stream: categoriesAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cats = snapshot.data!;
          return ListView.builder(
            itemCount: cats.length,
            itemBuilder: (_, i) => ListTile(title: Text(cats[i].name)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 仮: テストデータを1件挿入
          ref.read(categoryRepoProvider).addCategory(
                '体重',
                'kg',
                '#0061FF',
              );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
