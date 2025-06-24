import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repo/entry_repository.dart';
import '../../core/repo/category_repository.dart';

/// 履歴画面  ── 選択したカテゴリのエントリ一覧
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key, required this.catId});

  final String catId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // カテゴリ情報（名前・単位）を取得
    final catAsync = ref.watch(categoryRepoProvider).watchAll();
    final entryStream = ref.read(entryRepoProvider).watchLatest(catId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
      ),
      body: StreamBuilder(
        stream: catAsync,
        builder: (_, catSnap) {
          if (!catSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cat = catSnap.data!.firstWhere((c) => c.id == catId);

          return StreamBuilder(
            stream: entryStream,
            builder: (_, entrySnap) {
              final entries = entrySnap.data ?? [];
              if (entries.isEmpty) {
                return const Center(child: Text('まだデータがありません'));
              }

              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return ListTile(
                    leading: Text(
                      '${e.valueNum} ${cat.unit ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    title: Text(
                      e.ts.toLocal().toString().substring(0, 16),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
