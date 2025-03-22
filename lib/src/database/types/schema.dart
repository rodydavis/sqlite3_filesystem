part of '../db.dart';

const _schema = <int, (String, String)>{0: (_schema0Up, _schema0Down)};

// ----------	0000	no permissions
// -rwx------	0700	read, write, & execute only for owner
// -rwxrwx---	0770	read, write, & execute for owner and group
// -rwxrwxrwx	0777	read, write, & execute for owner, group and others
// ---x--x--x	0111	execute
// --w--w--w-	0222	write
// --wx-wx-wx	0333	write & execute
// -r--r--r--	0444	read
// -r-xr-xr-x	0555	read & execute
// -rw-rw-rw-	0666	read & write
// -rwxr-----	0740	owner can read, write, & execute; group can only read; others have no permissions

const _schema0Up = '''
CREATE TABLE files (
  path TEXT NOT NULL PRIMARY KEY,
  mode INTEGER NOT NULL DEFAULT (1),
  data BLOB,
  size INTEGER,
  link TEXT REFERENCES files(path),
  is_dir BOOLEAN NOT NULL DEFAULT (FALSE),
  accessed TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  created TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  modified TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  changed TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TABLE temp_directories (
  path TEXT NOT NULL PRIMARY KEY,
  created TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP)
);

CREATE INDEX files_path ON files(path);
CREATE INDEX files_link ON files(link);
''';

extension type DatabaseFile(Row row) implements Row {
  String get path => row['path'] as String;

  int get mode => row['mode'] as int;

  Uint8List? get data {
    final data = row['data'];
    if (data == null) return null;
    return Uint8List.fromList(data as List<int>);
  }

  int? get size => row['size'] as int?;

  String? get link => row['link'] as String?;

  bool get isDir {
    final val = row['is_dir'];
    if (val is int) return val != 0;
    if (val is bool) return val;
    return val == 'true';
  }

  bool get isLink => link != null && link!.isNotEmpty;

  /// The time of the last change to the data of the file system object.
  DateTime get modified {
    final modified = row['modified'];
    if (modified is int) return DateTime.fromMillisecondsSinceEpoch(modified);
    return DateTime.parse(modified as String);
  }

  /// When the file system object was created.
  DateTime get created {
    final created = row['created'];
    if (created is int) return DateTime.fromMillisecondsSinceEpoch(created);
    return DateTime.parse(created as String);
  }

  /// The time of the last access to the data of the file system object.
  ///
  /// On Windows platforms, this may have 1 day granularity, and be
  /// out of date by an hour.
  DateTime get accessed {
    final accessed = row['accessed'];
    if (accessed is int) return DateTime.fromMillisecondsSinceEpoch(accessed);
    return DateTime.parse(accessed as String);
  }

  /// The time of the last change to the data or metadata of the file system
  /// object.
  ///
  /// On Windows platforms, this is instead the file creation time.
  DateTime get changed {
    final changed = row['changed'];
    if (changed is int) return DateTime.fromMillisecondsSinceEpoch(changed);
    return DateTime.parse(changed as String);
  }
}

extension type DatabaseTempDir(Row row) implements Row {
  String get path => row['path'] as String;

  DateTime get created {
    final created = row['created'];
    if (created is int) return DateTime.fromMillisecondsSinceEpoch(created);
    return DateTime.parse(created as String);
  }
}

const _schema0Down = '''
DROP TABLE files;
DROP TABLE temp_directories;
''';
