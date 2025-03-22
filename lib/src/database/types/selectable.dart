part of '../db.dart';

class Selectable<T extends Row> {
  final CommonDatabase db;
  final String sql;
  final List<Object?> args;
  final T Function(Row) mapper;

  Selectable(this.db, this.sql, this.args, this.mapper);

  Selectable<R> map<R extends Row>(R Function(Row) f) {
    return Selectable<R>(db, sql, args, f);
  }

  List<T> getAll() {
    final rows = db.select(sql, args);
    return rows.map(mapper).toList();
  }

  T? getSingleOrNull() {
    final row = db.select(sql, args).firstOrNull;
    if (row == null) return null;
    return mapper(row);
  }

  T getSingle() {
    final row = db.select(sql, args).first;
    return mapper(row);
  }

  Stream<List<T>> watch(Set<String> tables) async* {
    yield getAll();
    await for (final event in db.updates) {
      if (tables.contains(event.tableName)) {
        yield getAll();
      }
    }
  }

  Stream<T?> watchSingleOrNull(Set<String> tables) async* {
    yield getSingleOrNull();
    await for (final event in db.updates) {
      if (tables.contains(event.tableName)) {
        yield getSingleOrNull();
      }
    }
  }

  Stream<T> watchSingle(Set<String> tables) async* {
    yield getSingle();
    await for (final event in db.updates) {
      if (tables.contains(event.tableName)) {
        yield getSingle();
      }
    }
  }
}
