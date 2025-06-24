import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/repo/category_repository.dart';
import '../../core/repo/entry_repository.dart';

/// 数値入力ページ
class AddEntryPage extends ConsumerStatefulWidget {
  const AddEntryPage({super.key});

  @override
  ConsumerState<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends ConsumerState<AddEntryPage> {
  final _valueCtrl = TextEditingController();
  DateTime _ts = DateTime.now();
  String? _selectedCatId;

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(watchAllCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('数値を記録')),
      // AsyncValueのwhenを使って、loading/error/dataの状態をきれいにハンドリング
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
        data: (cats) {
          // カテゴリが無い場合はガイド表示
          if (cats.isEmpty) {
            return const Center(child: Text('先にカテゴリを作成してください'));
          }

          // _selectedCatIdがnull、または現在のカテゴリリストに存在しないIDの場合、先頭のIDをセットする
          // これにより、カテゴリが削除された場合などにも対応できる
          final catIds = cats.map((c) => c.id).toList();
          if (_selectedCatId == null || !catIds.contains(_selectedCatId)) {
            // buildメソッド内での状態変更は避けるべきですが、この場合は初期化と
            // データの不整合を解消するためのものです。
            // WidgetsBinding.instance.addPostFrameCallbackを使うとより安全です。
            _selectedCatId = cats.first.id;
          }


          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCatId,
                  items: cats
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCatId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _valueCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '値 (数値)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(child: const Text('時間変更'), onPressed: _showPicker),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                  onPressed: _save,
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPicker() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _ts,
    );
    if (d != null) {
      // 時刻はそのまま残す
      setState(
          () => _ts = DateTime(d.year, d.month, d.day, _ts.hour, _ts.minute));
    }
  }

  Future<void> _save() async {
    // onPressed内ではref.readを使う
    final entryRepo = ref.read(entryRepoProvider);
    final v = double.tryParse(_valueCtrl.text);
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数値を入力してください')),
      );
      return;
    }
    // _selectedCatIdは、buildメソッド内のロジックでnullでないことが保証されている
    await entryRepo.addEntry(
      categoryId: _selectedCatId!,
      ts: _ts,
      value: v,
    );
    if (mounted) context.pop(); // 戻る
  }
}
