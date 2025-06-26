import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/repo/entry_repository.dart';

enum PlotType { line, bar, heat }

class PlotCard extends ConsumerStatefulWidget {
  const PlotCard({super.key, required this.cat});
  final Category cat;

  @override
  ConsumerState<PlotCard> createState() => _PlotCardState();
}

class _PlotCardState extends ConsumerState<PlotCard> {
  PlotType _type = PlotType.line;

  @override
  Widget build(BuildContext context) {
    final stream =
        ref.read(entryRepoProvider).watchDaily(widget.cat.id, 30);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ヘッダ ──
            Row(
              children: [
                Text(widget.cat.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
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
              ],
            ),
            const SizedBox(height: 8),

            // ── グラフ ──
            StreamBuilder(
              stream: stream,
              builder: (_, snap) {
                final data = snap.data ?? [];
                if (data.isEmpty) {
                  return const SizedBox(
                      height: 120,
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
          ],
        ),
      ),
    );
  }

  /* ────── 描画メソッド ────── */

  Widget _buildLine(List<EntryDaily> d) => SizedBox(
        height: 120,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < d.length; i++)
                    FlSpot(i.toDouble(), d[i].avg)
                ],
                isCurved: true,
                dotData: const FlDotData(show: false),
                barWidth: 3,
              )
            ],
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      );

  Widget _buildBar(List<EntryDaily> d) => SizedBox(
        height: 120,
        child: BarChart(
          BarChartData(
            barGroups: [
              for (var i = 0; i < d.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [BarChartRodData(toY: d[i].avg)],
                )
            ],
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      );

  Widget _buildHeatPlaceholder() => const SizedBox(
        height: 120,
        child: Center(child: Text('HeatMap TBD')),
      );
}
