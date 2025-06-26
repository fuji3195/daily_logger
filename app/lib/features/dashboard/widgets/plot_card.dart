// lib/features/dashboard/widgets/plot_card.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/repo/entry_repository.dart';

enum PlotType { line, bar, heat }
enum PlotLabel { date, dateTime }
enum MovingAvg {none, d7, d15, d30}

class PlotCard extends ConsumerStatefulWidget {
  const PlotCard({super.key, required this.cat});
  final Category cat;

  @override
  ConsumerState<PlotCard> createState() => _PlotCardState();
}

class _PlotCardState extends ConsumerState<PlotCard>
    with SingleTickerProviderStateMixin {
  static const double _plotHeight = 200;
  PlotType _type = PlotType.line;
  PlotLabel _label = PlotLabel.date;
  MovingAvg _ma = MovingAvg.none;
  bool _showAxes = false;
  bool _collapsed = false;
  double? _goal;

  @override
  Widget build(BuildContext context) {
    final stream = ref.read(entryRepoProvider).watchDaily(widget.cat.id, 30);

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
              /* ───── ヘッダ 1 段目 ───── */
              Row(
                children: [
                  Expanded(
                    child: Text(widget.cat.name,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  // 折りたたみ
                  IconButton(
                    icon: Icon(_collapsed
                        ? Icons.visibility
                        : Icons.visibility_off),
                    tooltip: _collapsed ? '表示' : '非表示',
                    onPressed: () =>
                        setState(() => _collapsed = !_collapsed),
                  ),
                  // 軸トグル
                  IconButton(
                    icon: Icon(
                        _showAxes ? Icons.grid_on : Icons.grid_off),
                    tooltip: '軸表示',
                    onPressed: () =>
                        setState(() => _showAxes = !_showAxes),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              /* ───── ヘッダ 2 段目 ───── */
              Row(
                children: [
                  // 目標値ライン
                  IconButton(
                    icon: const Icon(Icons.flag),
                    tooltip: '目標値',
                    onPressed: _showGoalDialog,
                  ),
                  const SizedBox(width: 4),
                  // グラフ種別
                  DropdownButton<PlotType>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(
                          value: PlotType.line, child: Text('Line')),
                      DropdownMenuItem(
                          value: PlotType.bar, child: Text('Bar')),
                      DropdownMenuItem(
                          value: PlotType.heat, child: Text('Heat')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(width: 8),
                  // ラベル形式
                  DropdownButton<PlotLabel>(
                    value: _label,
                    items: const [
                      DropdownMenuItem(
                          value: PlotLabel.date, child: Text('Date')),
                      DropdownMenuItem(
                          value: PlotLabel.dateTime,
                          child: Text('Date+Time')),
                    ],
                    onChanged: (v) => setState(() => _label = v!),
                  ),
                  const SizedBox(width: 8),
                  if (_type == PlotType.line)
                    DropdownButton<MovingAvg>(
                      value: _ma,
                      items: const [
                        DropdownMenuItem(
                            value: MovingAvg.none, child: Text('MA-None')),
                        DropdownMenuItem(
                            value: MovingAvg.d7, child: Text('MA-7')),
                        DropdownMenuItem(
                            value: MovingAvg.d15, child: Text('MA-15')),
                        DropdownMenuItem(
                            value: MovingAvg.d30, child: Text('MA-30')),
                      ],
                      onChanged: (v) => setState(() => _ma = v!),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              /* ───── グラフ本体 ───── */
              Visibility(
                visible: !_collapsed,
                child: StreamBuilder(
                  stream: stream,
                  builder: (_, snap) {
                    final data = snap.data ?? [];
                    if (data.isEmpty) {
                      return const SizedBox(
                          height: _plotHeight,
                          child: Center(child: Text('データなし')));
                    }
                    switch (_type) {
                      case PlotType.line:
                        return _buildLine(data);
                      case PlotType.bar:
                        return _buildBar(data);
                      case PlotType.heat:
                        return _buildHeatPlaceholder();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /* ───────── グラフ描画 ───────── */
  Widget _buildLine(List<EntryDaily> d) {
    // 1. 線形補間した連続データ列生成
    final full = _fillMissing(d);
    // 2. moving averageを計算
    final maSpots = _ma == MovingAvg.none
        ? <FlSpot>[]
        : _calcMovingAvg(full, _maWindow());

    // 3. 元データスポット
    final base = d.first.day.millisecondsSinceEpoch.toDouble();
    final spots = [
      for (var e in full)
        FlSpot((e.day.millisecondsSinceEpoch - base) / 3.6e6, e.avg)
    ];

    // min / max (目標含む)
    double minVal =
        [...full.map((e) => e.avg), if (_goal != null) _goal!].reduce(
            (a, b) => a < b ? a : b);
    double maxVal =
        [...full.map((e) => e.avg), if (_goal != null) _goal!].reduce(
            (a, b) => a > b ? a : b);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;
    minVal -= range * 0.1;
    maxVal += range * 0.1;

    // ラベル関数
    final tStyle = TextStyle(fontSize: 10, color: Colors.grey[600]);
    String fmt(double v) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          base.toInt() + (v * 3.6e6).round());
      return _label == PlotLabel.date
          ? DateFormat('MM/dd').format(dt)
          : DateFormat('MM/dd\nHH:mm').format(dt);
    }

    // ラベル関数は変えずに…

    return SizedBox(
      height: _plotHeight,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.last.x,
          minY: minVal,
          maxY: maxVal,
          extraLinesData: ExtraLinesData(horizontalLines: [
            if (_goal != null)
              HorizontalLine(
                y: _goal!,
                strokeWidth: 2,
                color: Colors.redAccent,
                dashArray: [6, 4],
              ),
          ]),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            // 移動平均
            if (maSpots.isNotEmpty)
              LineChartBarData(
                spots: maSpots,
                isCurved: true,
                barWidth: 2,
                color: Colors.orange,
                dotData: const FlDotData(show: false),
              ),
          ],
          titlesData: _axisTitles( tStyle, fmt, spots.last.x, maxVal),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }


  Widget _buildBar(List<EntryDaily> d) {
    final base = d.first.day.millisecondsSinceEpoch.toDouble();
    final groups = [
      for (var e in d)
        BarChartGroupData(
          x: ((e.day.millisecondsSinceEpoch - base) / 3.6e6).round(),
          barRods: [BarChartRodData(toY: e.avg)],
        )
    ];
    double minVal =
        [...d.map((e) => e.avg), if (_goal != null) _goal!].reduce(
            (a, b) => a < b ? a : b);
    double maxVal =
        [...d.map((e) => e.avg), if (_goal != null) _goal!].reduce(
            (a, b) => a > b ? a : b);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;
    minVal -= range * 0.1;
    maxVal += range * 0.1;

    final tStyle = TextStyle(fontSize: 10, color: Colors.grey[600]);
    String fmt(double v) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          base.toInt() + (v * 3.6e6).round());
      return _label == PlotLabel.date
          ? DateFormat('MM/dd').format(dt)
          : DateFormat('MM/dd\nHH:mm').format(dt);
    }

    return SizedBox(
      height: _plotHeight,
      child: BarChart(
        BarChartData(
          minY: minVal,
          maxY: maxVal,
          barGroups: groups,
          extraLinesData: ExtraLinesData(horizontalLines: [
            if (_goal != null)
              HorizontalLine(
                y: _goal!,
                strokeWidth: 2,
                color: Colors.redAccent,
                dashArray: [6, 4],
              ),
          ]),
          titlesData: _axisTitles( tStyle, fmt, groups.last.x.toDouble(), maxVal),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

/* ────── 補助メソッド ────── */

  // 欠損日の線形補完
  List<EntryDaily> _fillMissing(List<EntryDaily> src) {
    if (src.length < 2) return src;
    final filled = <EntryDaily>[];
    for (var i = 0; i < src.length - 1; i++) {
      final cur = src[i];
      final next = src[i + 1];
      filled.add(cur);
      var day = cur.day.add(const Duration(days: 1));
      while (day.isBefore(next.day)) {
        // 線形補完
        final t = day.difference(cur.day).inDays /
            next.day.difference(cur.day).inDays;
        final v = cur.avg + (next.avg - cur.avg) * t;
        filled.add(EntryDaily(day: day, avg: v));
        day = day.add(const Duration(days: 1));
      }
    }
    filled.add(src.last);
    return filled;
  }

  // MA の window サイズ
  int _maWindow() => switch (_ma) {
        MovingAvg.d7 => 7,
        MovingAvg.d15 => 15,
        MovingAvg.d30 => 30,
        _ => 0
      };

  // 移動平均計算
  List<FlSpot> _calcMovingAvg(List<EntryDaily> src, int win) {
    if (win <= 1) return [];
    final base = src.first.day.millisecondsSinceEpoch.toDouble();
    final averages = <FlSpot>[];
    for (var i = 0; i <= src.length - win; i++) {
      final slice = src.sublist(i, i + win);
      final avg = slice.map((e) => e.avg).reduce((a, b) => a + b) / win;
      averages.add(FlSpot(
          (slice.last.day.millisecondsSinceEpoch - base) / 3.6e6, avg));
    }
    return averages;
  }

  FlTitlesData _axisTitles(
          TextStyle style, String Function(double) fmt, double maxX, double maxY) =>
      FlTitlesData(
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: _showAxes,
            reservedSize: _label == PlotLabel.date ? 22 : 36,
            interval: maxX / 3,
            getTitlesWidget: (v, _) =>
                Text(fmt(v), textAlign: TextAlign.center, style: style),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: _showAxes,
            reservedSize: 32,
            interval: maxY / 3,
            getTitlesWidget: (v, _) =>
                Text(v.toStringAsFixed(0), style: style),
          ),
        ),
      );

  Widget _buildHeatPlaceholder() => const SizedBox(
        height: 140,
        child: Center(child: Text('HeatMap TBD')),
      );

  /* ───────── 目標ダイアログ ───────── */
  Future<void> _showGoalDialog() async {
    final ctrl = TextEditingController(
        text: _goal != null ? _goal!.toString() : '');
    final result = await showDialog<double?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('目標値を入力'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '例: 70.0'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('キャンセル')),
          ElevatedButton(
              onPressed: () => Navigator.pop(
                  context, double.tryParse(ctrl.text)),
              child: const Text('保存')),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _goal = result);
    }
  }
}
