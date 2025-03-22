part of '../fs.dart';

class SqliteFileStat implements FileStat {
  SqliteFileStat._(this.file);

  final DatabaseFile file;

  static FileStat notFound = const _NotFound();

  @override
  DateTime get accessed => file.accessed;

  @override
  DateTime get changed => file.changed;

  @override
  DateTime get modified => file.modified;

  @override
  int get mode => file.mode;

  @override
  String modeString() {
    var permissions = mode & 0xFFF;
    var codes = const <String>[
      '---',
      '--x',
      '-w-',
      '-wx',
      'r--',
      'r-x',
      'rw-',
      'rwx',
    ];
    var result = <String>[];
    result
      ..add(codes[(permissions >> 6) & 0x7])
      ..add(codes[(permissions >> 3) & 0x7])
      ..add(codes[permissions & 0x7]);
    return result.join();
  }

  @override
  int get size => file.size ?? -1;

  @override
  FileSystemEntityType get type {
    if (file.isDir) return FileSystemEntityType.directory;
    if (file.isLink) return FileSystemEntityType.link;
    return FileSystemEntityType.file;
  }
}

class _NotFound implements FileStat {
  const _NotFound();

  @override
  DateTime get accessed => DateTime(0);

  @override
  DateTime get changed => DateTime(0);

  @override
  DateTime get modified => DateTime(0);

  @override
  int get mode => 0;

  @override
  String modeString() => '';

  @override
  int get size => -1;

  @override
  FileSystemEntityType get type => FileSystemEntityType.notFound;
}
