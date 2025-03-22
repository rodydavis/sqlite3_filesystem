import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_fs/sqlite_fs.dart';

import 'app.dart';

void main() {
  final db = sqlite3.openInMemory();
  final fs = SqliteFileSystem.fromDb(db);
  runApp(App(fs: fs, db: db));
}
