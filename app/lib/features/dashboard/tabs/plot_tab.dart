import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repo/category_repository.dart';
import '../widgets/plot_card.dart';

class PlotTab extends ConsumerWidget {
  const PlotTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsStream = ref.watch(categoryRepoProvider).watchAll();

    return StreamBuilder(
      stream: catsStream,
      builder: (_, snap) {
        final cats = snap.data ?? [];
        if (cats.isEmpty) {
          return const Center(child: Text('カテゴリがありません'));
        }
        return ListView.builder(
          itemCount: cats.length,
          itemBuilder: (_, i) => PlotCard(cat: cats[i]),
        );
      },
    );
  }
}
