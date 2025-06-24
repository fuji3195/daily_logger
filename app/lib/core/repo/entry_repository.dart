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
