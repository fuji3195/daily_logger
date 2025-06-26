import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repo/category_repository.dart';
import '../../../core/repo/entry_repository.dart';
import '../widgets/metric_overview_card.dart';

class DashboardCardsTab extends ConsumerWidget {
  const DashboardCardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catStream = ref.watch(categoryRepoProvider).watchAll();

    return StreamBuilder(
      stream: catStream,
      builder: (_, catSnap) {
        if (!catSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cats = catSnap.data!;
        return ListView.builder(
          itemCount: cats.length,
          itemBuilder: (_, i) {
            final c = cats[i];
            return MetricOverviewCard(
              catId: c.id,
              catName: c.name,
              unit: c.unit,
            );
          },
        );
      },
    );
  }
}
