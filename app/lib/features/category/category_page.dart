import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_logger/core/repo/category_repository.dart';

/// カテゴリ管理画面
class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(categoryRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('カテゴリー管理')),
      body: StreamBuilder(
        stream: repo.watchAll(),
        builder: (_, snapshot) {
          final cats = snapshot.data ?? [];
          return ListView.separated(
            itemCount: cats.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final cat = cats[i];
              final color = Color(int.parse(cat.colorHex.replaceFirst('#', '0xff')));
              return ListTile(
                leading: CircleAvatar(backgroundColor: color),
                title: Text(cat.name),
                subtitle: Text(cat.unit ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => repo.deleteCategory(cat.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => _AddCategoryDialog(repo: repo),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// カテゴリ追加ダイアログ
class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.repo});
  final CategoryRepository repo;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final nameCtrl = TextEditingController();
  final unitCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新規カテゴリ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名前')),
          TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '単位 (kg など)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            await widget.repo.addCategory(
              nameCtrl.text.trim(),
              unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
              '#0061FF',
            );

            if (mounted) Navigator.pop(context);
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}
