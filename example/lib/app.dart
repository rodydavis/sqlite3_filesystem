import 'package:flutter/material.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite_fs/sqlite_fs.dart';

import 'home.dart';

class App extends StatelessWidget {
  App({
    super.key,
    required this.fs,
    required this.db,
    this.seedColor = Colors.blue,
  });

  final SqliteFileSystem fs;
  final CommonDatabase db;
  final Color seedColor;

  late final lightColorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );
  late final darkColorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );
  late final lightTheme = ThemeData.light().copyWith(
    colorScheme: lightColorScheme,
  );
  late final darkTheme = ThemeData.dark().copyWith(
    colorScheme: darkColorScheme,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(fs: fs, db: db),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
