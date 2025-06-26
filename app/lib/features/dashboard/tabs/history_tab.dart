import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repo/category_repository.dart';
import '../../../core/repo/entry_repository.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // すべてのカテゴリ
    final catsStream = ref.watch(categoryRepoProvider).watchAll();

    return StreamBuilder(
      stream: catsStream,
      builder: (_, catSnap) {
        final cats = catSnap.data ?? [];
        if (cats.isEmpty) {
          return const Center(child: Text('カテゴリがありません'));
        }

        return ListView.separated(
          itemCount: cats.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) {
            final c = cats[i];

            // 各カテゴリの最新エントリ 1 件を取得
            final latestStream =
                ref.read(entryRepoProvider).watchLatest(c.id);

            return StreamBuilder(
              stream: latestStream,
              builder: (_, entrySnap) {
                final latest = entrySnap.data?.isNotEmpty == true
                    ? entrySnap.data!.first
                    : null;

                final latestTxt = latest != null
                    ? DateFormat('yyyy/MM/dd').format(latest.ts)
                    : '--';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                        int.parse(c.colorHex.replaceFirst('#', '0xff'))),
                  ),
                  title: Text(c.name),
                  subtitle: Text('最終入力: $latestTxt'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/history/${c.id}'),
                );
              },
            );
          },
        );
      },
    );
  }
}
