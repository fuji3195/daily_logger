import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';   // ← Entry / Category 型
import '../../core/repo/entry_repository.dart';
import '../../core/repo/category_repository.dart'; // watchAllCategoriesProvider もここ

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key, required this.catId});
  final String catId;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with SingleTickerProviderStateMixin {
  late DateTime _from;
  late DateTime _to;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _to = DateTime.now();
    _from = _to.subtract(const Duration(days: 30));
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // ★ AsyncValue<List<Category>>
    final catAsync = ref.watch(watchAllCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.list),      text: 'リスト'),
            Tab(icon: Icon(Icons.bar_chart), text: '棒'),
            Tab(icon: Icon(Icons.grid_on),   text: 'ヒート'),
          ],
        ),
      ),
      body: catAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ERR: $e')),
        data: (cats) {
          // 該当カテゴリ取得
          final cat = cats.firstWhere((c) => c.id == widget.catId);
          // 期間ストリーム
          final rangeStream = ref
              .read(entryRepoProvider)
              .watchRange(cat.id, _from, _to);

          return Column(
            children: [
              // 日付レンジピッカー
              Padding(
                padding: const EdgeInsets.all(8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                      '${DateFormat('yyyy/MM/dd').format(_from)} – ${DateFormat('MM/dd').format(_to)}'),
                  onPressed: _pickRange,
                ),
              ),
              const Divider(height: 0),

              // タブビュー
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildList(rangeStream, cat),
                    _buildBar(rangeStream, cat),
                    _buildHeatPlaceholder(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /* ───── ビュー部品 ───── */

  // リスト
  Widget _buildList(Stream<List<Entry>> stream, Category cat) {
    return StreamBuilder(
      stream: stream,
      builder: (_, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('データがありません'));
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) => ListTile(
            leading: Text('${list[i].valueNum} ${cat.unit ?? ''}'),
            title: Text(DateFormat('yyyy/MM/dd HH:mm')
                .format(list[i].ts.toLocal())),
          ),
        );
      },
    );
  }

  // 棒グラフ
  Widget _buildBar(Stream<List<Entry>> stream, Category cat) {
    return StreamBuilder(
      stream: stream,
      builder: (_, snap) {
        final rows = snap.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Text('データがありません'));
        }
        // 日別平均
        final dayMap = <String, double>{};
        for (var r in rows) {
          final k = DateFormat('MM/dd').format(r.ts);
          dayMap.update(k, (v) => (v + r.valueNum) / 2,
              ifAbsent: () => r.valueNum);
        }
        final groups = <BarChartGroupData>[
          for (var i = 0; i < dayMap.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: dayMap.values.elementAt(i))],
            )
        ];
        return Padding(
          padding: const EdgeInsets.all(12),
          child: BarChart(
            BarChartData(
              barGroups: groups,
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }

  // ヒートマップ（後で実装）
  Widget _buildHeatPlaceholder() =>
      const Center(child: Text('ヒートマップは今後実装予定'));

  /* ───── 日付レンジ選択 ───── */
  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }
}

