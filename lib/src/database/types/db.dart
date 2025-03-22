part of '../db.dart';

class DB {
  final CommonDatabase db;
  static bool autoMigrate = true;
  DB(this.db) {
    if (autoMigrate) migrate();
  }

  void migrate([bool upgrade = true]) {
    final version = db.userVersion;
    if (_schema.containsKey(version)) {
      var (up, down) = _schema[version]!;
      if (upgrade) {
        db.execute(up);
      } else {
        db.execute(down);
      }
      db.userVersion = upgrade ? version + 1 : version - 1;
    }
  }

  Selectable<Row> select(String sql, [List<Object?> args = const []]) {
    return Selectable<Row>(db, sql, args, (row) => row);
  }

  List<DatabaseFile> files(String sql, [List<Object?> args = const []]) {
    return select(sql, args).map((row) => row as DatabaseFile).getAll();
  }

  DatabaseFile? file(String path) {
    return select('SELECT * FROM files WHERE path = ?', [
      path,
    ]).map((row) => row as DatabaseFile).getSingleOrNull();
  }

  void deleteFile(String path) {
    db.execute('DELETE FROM files WHERE path = ?', [path]);
  }

  void execute(String sql, [List<Object?> args = const []]) {
    db.execute(sql, args);
  }

  void close() {
    db.dispose();
  }
}

