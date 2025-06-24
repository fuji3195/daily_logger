import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/repo/category_repository.dart';
import '../../core/repo/entry_repository.dart';

/// ダッシュボード ―― カテゴリごとの “最新値” を一覧表示
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catStream = ref.watch(categoryRepoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/category'), // カテゴリ管理へ
          ),
        ],
      ),

      /// ───── カテゴリ一覧 + 最新値 ─────
      body: StreamBuilder(
        stream: catStream,
        builder: (_, catSnap) {
          if (!catSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cats = catSnap.data!;

          return ListView.builder(
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final cat = cats[i];

              /// ★ 各カテゴリごとに「最新エントリ」を監視
              return StreamBuilder(
                stream: ref
                    .read(entryRepoProvider)
                    .watchLatest(cat.id), // 直近 30件 → first が最新
                builder: (_, entrySnap) {
                  final latest = entrySnap.data?.isNotEmpty == true
                      ? entrySnap.data!.first
                      : null;

                  final valueText = latest != null
                      ? '${latest.valueNum} ${cat.unit ?? ''}'
                      : '---';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                          int.parse(cat.colorHex.replaceFirst('#', '0xff'))),
                    ),
                    title: Text(cat.name),
                    trailing: Text(valueText),
                    onTap: () => context.push('/history/${cat.id}'), // ← 履歴画面予定
                  );
                },
              );
            },
          );
        },
      ),

      /// ───── 数値入力へ ─────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
