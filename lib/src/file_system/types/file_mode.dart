part of '../fs.dart';

/// The modes in which a [File] can be opened.
class SqliteFileMode implements FileMode {
  /// The mode for opening a file only for reading.
  static const read = SqliteFileMode._internal(0);

  /// Mode for opening a file for reading and writing. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const write = SqliteFileMode._internal(1);

  /// Mode for opening a file for reading and writing to the
  /// end of it. The file is created if it does not already exist.
  static const append = SqliteFileMode._internal(2);

  /// Mode for opening a file for writing *only*. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const writeOnly = SqliteFileMode._internal(3);

  /// Mode for opening a file for writing *only* to the
  /// end of it. The file is created if it does not already exist.
  static const writeOnlyAppend = SqliteFileMode._internal(4);

  final int mode;

  const SqliteFileMode._internal(this.mode);
}
