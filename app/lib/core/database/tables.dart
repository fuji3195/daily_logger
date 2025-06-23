import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get unit => text().nullable()();
  TextColumn get colorHex => text().withLength(min: 7, max: 7)();
  TextColumn get periodType =>
      text().withDefault(const Constant('daily'))(); // hourly, weekly...

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get ts => dateTime()();
  RealColumn get valueNum => real()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
