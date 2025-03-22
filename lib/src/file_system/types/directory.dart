part of '../fs.dart';

// Tracks a unique name for system temp directories, per filesystem
// instance.
final Expando<int> _systemTempCounter = Expando<int>();

class SqliteDirectory extends SqliteFileSystemEntity<Directory>
    with common.DirectoryAddOnsMixin
    implements Directory {
  SqliteDirectory(super.fileSystem, super.path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.directory;

  @override
  Uri get uri {
    return Uri.directory(path, windows: p.style == p.Style.windows);
  }

  @override
  Directory get absolute {
    return fileSystem.directory(p.absolute(path));
  }

  @override
  void createSync({bool recursive = false}) {
    if (existsSync()) return;
    if (!recursive) {
      final parent = fileSystem.directory(p.dirname(path));
      _checkFile(parent.path);
    }
    _createAll(recursive: recursive);
    db.execute(
      'INSERT INTO files (path, mode, data, size, link, is_dir, created, modified) VALUES (?, ?, NULL, 0, NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)',
      [path, SqliteFileMode.write.mode],
    );
    controller.add(
      FileSystemCreateEvent(
        path,
        expectedType == FileSystemEntityType.directory,
      ),
    );
  }

  @override
  Future<Directory> create({bool recursive = false}) {
    createSync(recursive: recursive);
    return Future.value(this);
  }

  @override
  Directory createTempSync([String? prefix]) {
    prefix = '${prefix ?? ''}rand';
    var fullPath = fileSystem.path.join(path, prefix);
    var dirname = fileSystem.path.dirname(fullPath);
    var basename = fileSystem.path.basename(fullPath);
    var node = fileSystem.directory(dirname);
    checkExists(node, () => dirname);
    var tempCounter = _systemTempCounter[fileSystem] ?? 0;
    String name() => '$basename$tempCounter';
    while (node.childDirectory(name()).existsSync()) {
      tempCounter++;
    }
    _systemTempCounter[fileSystem] = tempCounter;
    var tempDir = node.childDirectory(name());
    final dir = SqliteDirectory(fileSystem, tempDir.path);
    dir.createSync();
    db.db.execute('INSERT INTO temp_directories (path) VALUES (?)', [dir.path]);
    return dir;
  }

  @override
  Future<Directory> createTemp([String? prefix]) {
    return Future.value(createTempSync(prefix));
  }

  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) {
    List<DatabaseFile> files;
    files =
        db
            .select('SELECT * FROM files WHERE path LIKE ?', [
              p.join(path, '%'),
            ])
            .getAll()
            .map(DatabaseFile.new)
            .toList();
    if (!recursive) {
      files =
          files.where((file) => file.path != path).where((file) {
            final parent = fileSystem.path.dirname(file.path);
            return parent == path;
          }).toList();
    }
    var results =
        files.map((file) {
          if (file.isDir) return fileSystem.directory(file.path);
          if (file.isLink) return fileSystem.link(file.path);
          return fileSystem.file(file.path);
        }).toList();
    if (followLinks) {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        if (file.isLink) {
          final link = fileSystem.link(file.path);
          if (link.existsSync()) {
            final finalPath = link.resolveSymbolicLinksSync();
            final stat = fileSystem.statSync(finalPath);
            if (stat.type == FileSystemEntityType.directory) {
              results[i] = fileSystem.directory(finalPath);
            } else if (stat.type == FileSystemEntityType.link) {
              results[i] = fileSystem.link(finalPath);
            } else {
              results[i] = fileSystem.file(finalPath);
            }
          }
        }
      }
    }
    return results;
  }

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) {
    return Stream<FileSystemEntity>.fromIterable(
      listSync(recursive: recursive, followLinks: followLinks),
    );
  }

  @override
  void deleteSync({bool recursive = false}) {
    super.deleteSync(recursive: recursive);
    for (var entity in listSync(recursive: true)) {
      entity.deleteSync(recursive: true);
    }
  }
}
