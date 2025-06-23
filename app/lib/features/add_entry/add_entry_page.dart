import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/repo/entry_repository.dart';

class AddEntryPage extends ConsumerStatefulWidget {
  const AddEntryPage({super.key});
  @override
  ConsumerState<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends ConsumerState<AddEntryPage> {
  final _controller = TextEditingController();
  DateTime _ts = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entryRepo = ref.read(entryRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Value'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(DateFormat('yyyy/MM/dd HH:mm').format(_ts)),
                const Spacer(),
                TextButton(
                  child: const Text('Change'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: _ts,
                    );
                    if (picked != null) {
                      setState(() => _ts = picked);
                    }
                  },
                )
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final value = double.tryParse(_controller.text);
                if (value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('数値を入力してください')),
                  );
                  return;
                }
                // TODO: カテゴリ選択を実装、いまはダミーID
                await entryRepo.addEntry(
                  categoryId: 'dummy-cat-id',
                  ts: _ts,
                  value: value,
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            )
          ],
        ),
      ),
    );
  }
}
