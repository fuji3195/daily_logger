import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';

final uuid = Uuid();

class CategoryRepository {
  CategoryRepository(this.db);
  final AppDatabase db;

  Future<void> addCategory(String name, String? unit, String color) {
    return db.into(db.categories).insert(
      CategoriesCompanion.insert(
        id: uuid.v4(),
        name: name,
        unit: (unit == null) ? const Value.absent():Value(unit),
        colorHex: color,
      ),
    );
  }

  Stream<List<Category>> watchAll() =>
      (db.select(db.categories)
            ..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .watch();  Future<void> deleteCategory(String id) =>
      (db.delete(db.categories)..where((tbl) => tbl.id.equals(id))).go();
}

final dbProvider = Provider<AppDatabase>((_) => AppDatabase());
final categoryRepoProvider =
    Provider<CategoryRepository>((ref) => CategoryRepository(ref.read(dbProvider)));

final watchAllCategoriesProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(categoryRepoProvider).watchAll();
});