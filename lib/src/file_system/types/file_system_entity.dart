part of '../fs.dart';

abstract class SqliteFileSystemEntity<T extends FileSystemEntity>
    extends FileSystemEntity {
  SqliteFileSystemEntity(this.fileSystem, this.path);

  io.FileSystemEntityType get expectedType;

  late final DB db = fileSystem.db;

  @override
  final SqliteFileSystem fileSystem;

  @override
  final String path;

  final controller = StreamController<FileSystemEvent>.broadcast();

  void _checkFile(String path) {
    var file = db.file(path);
    if (file == null) throw common.noSuchFileOrDirectory(path);
  }

  DatabaseFile _file(String path) {
    var file = db.file(path);
    if (file == null) throw common.noSuchFileOrDirectory(path);
    return file;
  }

  void _createAll({bool recursive = false}) {
    final parts = p.split(path);
    for (var i = 1; i < parts.length; i++) {
      final dir = fileSystem.directory(p.joinAll(parts.sublist(0, i)));
      dir.createSync(recursive: recursive);
    }
  }

  @override
  Uri get uri {
    return Uri.file(path, windows: p.style == p.Style.windows);
  }

  @override
  String get dirname => p.dirname(path);

  @override
  String get basename => p.basename(path);

  @override
  FileSystemEntity get absolute => fileSystem.file(p.absolute(path));

  @override
  bool get isAbsolute => p.isAbsolute(path);

  @override
  void deleteSync({bool recursive = false}) {
    db.deleteFile(path);
    controller.add(
      FileSystemDeleteEvent(
        path,
        expectedType == io.FileSystemEntityType.directory,
      ),
    );
  }

  @override
  Future<T> delete({bool recursive = false}) {
    deleteSync(recursive: recursive);
    return Future.value(this as T);
  }

  @override
  bool existsSync() {
    final file = db.file(path);
    return file != null;
  }

  @override
  Future<bool> exists() {
    return Future.value(existsSync());
  }

  @override
  Directory get parent {
    final dirPath = p.dirname(path);
    return fileSystem.directory(dirPath);
  }

  @override
  T renameSync(String newPath) {
    _checkFile(path);
    db.execute('UPDATE files SET path = ? WHERE path = ?', [newPath, path]);
    controller.add(
      FileSystemMoveEvent(
        path,
        expectedType == io.FileSystemEntityType.directory,
        newPath,
      ),
    );
    return fileSystem.file(newPath) as T;
  }

  @override
  Future<T> rename(String newPath) {
    return Future.value(renameSync(newPath));
  }

  @override
  Future<String> resolveSymbolicLinks() {
    return Future.value(resolveSymbolicLinksSync());
  }

  @override
  String resolveSymbolicLinksSync() {
    if (path.isEmpty) {
      throw common.noSuchFileOrDirectory(path);
    }
    final visited = <String>{};
    var current = _file(path);
    while (current.link != null && current.link!.isNotEmpty) {
      if (visited.contains(current.path)) {
        throw LinkCycleException(current.path);
      }
      visited.add(current.path);
      current = _file(current.link!);
    }
    return fileSystem.path.normalize(current.path);
  }

  @override
  FileStat statSync() {
    final file = db.file(path);
    if (file != null) return SqliteFileStat.notFound;
    return SqliteFileStat._(file!);
  }

  @override
  Future<FileStat> stat() {
    return Future.value(statSync());
  }

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) => controller.stream.filter(events);
}

class LinkCycleException implements Exception {
  LinkCycleException(this.path);

  final String path;

  @override
  String toString() => 'Link cycle detected at $path';
}

extension on Stream<FileSystemEvent> {
  Stream<FileSystemEvent> filter(int type) {
    return where((event) => event.type & type != 0);
  }
}
