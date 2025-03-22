part of '../fs.dart';

class SqliteLink extends SqliteFileSystemEntity<Link> implements Link {
  SqliteLink(super.fileSystem, super.path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.link;

  @override
  void createSync(String target, {bool recursive = false}) {
    if (existsSync()) {
      throw common.fileExists(path);
    }
    db.execute(
      'INSERT INTO files (path, mode, link, is_dir) VALUES (?, ?, ?, FALSE)',
      [path, SqliteFileMode.write.mode, target],
    );
    controller.add(
      FileSystemCreateEvent(
        path,
        expectedType == FileSystemEntityType.directory,
      ),
    );
  }

  @override
  Future<Link> create(String target, {bool recursive = false}) {
    createSync(target, recursive: recursive);
    return Future.value(this);
  }

  @override
  String targetSync() {
    final file = _file(path);
    if (file.link == null || file.link!.isEmpty) {
      throw common.noSuchFileOrDirectory(path);
    }
    return file.link as String;
  }

  @override
  Future<String> target() {
    return Future.value(targetSync());
  }

  @override
  void updateSync(String target) {
    final file = _file(path);
    final changed = file.link != target;
    db.execute('UPDATE files SET link = ? WHERE path = ?', [target, path]);
    controller.add(
      FileSystemModifyEvent(
        path,
        expectedType == FileSystemEntityType.directory,
        changed,
      ),
    );
  }

  @override
  Future<Link> update(String target) {
    updateSync(target);
    return Future.value(this);
  }

  @override
  Link renameSync(String newPath) {
    _checkFile(path);
    db.execute('UPDATE files SET path = ? WHERE path = ?', [newPath, path]);
    controller.add(
      FileSystemMoveEvent(
        path,
        expectedType == FileSystemEntityType.directory,
        newPath,
      ),
    );
    return fileSystem.link(newPath);
  }

  @override
  Future<Link> rename(String newPath) {
    return Future.value(renameSync(newPath));
  }

  @override
  Link get absolute => fileSystem.link(p.absolute(path));
}
