import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'category_repository.dart';
import 'package:drift/drift.dart';

class EntryRepository {
  EntryRepository(this.db);
  final AppDatabase db;
  final _uuid = const Uuid();

  Future<void> addEntry({
    required String categoryId,
    required DateTime ts,
    required double value,
    String? memo,
  }) {
    return db.into(db.entries).insert(
      EntriesCompanion.insert(
        id: _uuid.v4(),
        categoryId: categoryId,
        ts: ts,
        valueNum: value,
        memo: Value(memo),
      ),
    );
  }

  /// カテゴリ別・直近 30 件
  Stream<List<Entry>> watchLatest(String categoryId) =>
      (db.select(db.entries)
            ..where((t) => t.categoryId.equals(categoryId))
            ..orderBy([(t) => OrderingTerm.desc(t.ts)])
            ..limit(30))
          .watch();
}

final entryRepoProvider =
    Provider<EntryRepository>((ref) => EntryRepository(ref.read(dbProvider)));

extension EntryRepositoryAgg on EntryRepository {
  /// 直近 N 日の日次平均を返す
  Stream<List<EntryDaily>> watchDaily(String catId, int days) {
    final from = DateTime.now().subtract(Duration(days: days));
    final query = (db.select(db.entries)
          ..where((t) => t.categoryId.equals(catId) & t.ts.isBiggerOrEqualValue(from)))
        .watch();

    return query.map((rows) {
      final byDay = <DateTime, List<Entry>>{};
      for (final r in rows) {
        final day = DateTime(r.ts.year, r.ts.month, r.ts.day);
        byDay.putIfAbsent(day, () => []).add(r);
      }
      return byDay.entries
          .map((e) => EntryDaily(
                day: e.key,
                avg: e.value.map((r) => r.valueNum).reduce((a, b) => a + b) /
                    e.value.length,
              ))
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day));
    });
  }
}

class EntryDaily {
  EntryDaily({required this.day, required this.avg});
  final DateTime day;
  final double avg;
}

extension EntryRepositoryRange on EntryRepository {
  /// 指定期間 [from]-[to] の全エントリ
  Stream<List<Entry>> watchRange(String catId, DateTime from, DateTime to) =>
      (db.select(db.entries)
            ..where((t) =>
                t.categoryId.equals(catId) &
                t.ts.isBiggerOrEqualValue(from) &
                t.ts.isSmallerOrEqualValue(to))
            ..orderBy([(t) => OrderingTerm.desc(t.ts)]))
          .watch();
}
