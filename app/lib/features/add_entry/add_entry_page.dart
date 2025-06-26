import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repo/category_repository.dart';
import '../../core/repo/entry_repository.dart';

class AddEntryPage extends ConsumerStatefulWidget {
  const AddEntryPage({super.key, this.fixedCatId});
  final String? fixedCatId; // ← 固定カテゴリで呼び出すときに渡す

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
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('エラー: $err')), // ★ 追加
        data: (cats) {
          if (cats.isEmpty) {
            return const Center(child: Text('先にカテゴリを作成してください'));
          }

          // ─── カテゴリ決定 ───
          if (widget.fixedCatId != null) {
            _selectedCatId = widget.fixedCatId; // 固定
          } else {
            // 初期値
            _selectedCatId ??= cats.first.id;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ─── ドロップダウン（固定時は非表示） ───
                if (widget.fixedCatId == null)
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

                // ─── 値入力 ───
                TextField(
                  controller: _valueCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '値 (数値)'),
                ),

                const SizedBox(height: 12),

                // ─── 日時表示 + 変更 ───
                Row(
                  children: [
                    Text(
                      _ts.toLocal().toString().substring(0, 16),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    TextButton(
                      child: const Text('時間変更'),
                      onPressed: _showPicker,
                    ),
                  ],
                ),

                const Spacer(),

                // ─── 保存 ───
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /* ───────── ヘルパー ───────── */

  Future<void> _showPicker() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _ts,
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_ts),
    );
    if (t == null) return;
    setState(() {
      _ts = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _save() async {
    final v = double.tryParse(_valueCtrl.text);
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数値を入力してください')),
      );
      return;
    }
    await ref.read(entryRepoProvider).addEntry(
          categoryId: _selectedCatId!,
          ts: _ts,
          value: v,
        );
    if (mounted) Navigator.pop(context);
  }
}
