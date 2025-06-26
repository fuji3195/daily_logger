import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/repo/entry_repository.dart';
import 'package:go_router/go_router.dart';

class MetricOverviewCard extends ConsumerStatefulWidget {
  const MetricOverviewCard({
    super.key,
    required this.catId,
    required this.catName,
    required this.unit,
  });

  final String catId;
  final String catName;
  final String? unit;

  @override
  ConsumerState<MetricOverviewCard> createState() =>
      _MetricOverviewCardState();
}

class _MetricOverviewCardState extends ConsumerState<MetricOverviewCard>
    with SingleTickerProviderStateMixin {
  bool _showValue = true;   // 値マスク
  bool _editing = false;    // 入力フォーム展開
  final _ctrl = TextEditingController();
  DateTime _ts = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entryRepo = ref.read(entryRepoProvider);

    return StreamBuilder(
      stream: entryRepo.watchLatest(widget.catId),
      builder: (_, snap) {
        final entries = snap.data ?? [];
        final latest = entries.isNotEmpty ? entries.first : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ───── ヘッダ（カテゴリ名＋アイコン類） ─────
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.catName,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(                               // 👁 マスク
                        icon: Icon(_showValue
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _showValue = !_showValue),
                      ),
                      IconButton(                               // ✎ 編集
                        icon: Icon(_editing ? Icons.close : Icons.edit),
                        onPressed: () => setState(() => _editing = !_editing),
                      ),
                      IconButton(                               // 🕑 履歴
                        icon: const Icon(Icons.history),
                        tooltip: '履歴',
                        onPressed: () =>
                            context.push('/history/${widget.catId}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ───── 最新値表示 ─────
                  Text(
                    latest == null
                        ? '--'
                        : _showValue
                            ? '${latest.valueNum} ${widget.unit ?? ''}'
                            : '***',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),

                  // ───── 入力フォーム（展開時のみ） ─────
                  if (_editing) ...[
                    const Divider(height: 24),
                    TextField(
                      controller: _ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(labelText: '値 (数値)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          DateFormat('yyyy/MM/dd HH:mm').format(_ts),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        TextButton(
                          child: const Text('時間変更'),
                          onPressed: _pickDateTime,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('保存'),
                        onPressed: () async {
                          final v = double.tryParse(_ctrl.text);
                          if (v == null) return;
                          await entryRepo.addEntry(
                            categoryId: widget.catId,
                            ts: _ts,
                            value: v,
                          );
                          if (mounted) {
                            setState(() {
                              _editing = false;
                              _ctrl.clear();
                              _ts = DateTime.now();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /* ────────────── Helper ────────────── */

  Future<void> _pickDateTime() async {
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
}
