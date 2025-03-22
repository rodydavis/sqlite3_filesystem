part of '../fs.dart';

class SqliteFileSystem extends FileSystem {
  final DB db;

  SqliteFileSystem(this.db) {
    deleteTempDirectories();
  }

  static SqliteFileSystem fromDb(CommonDatabase db) {
    return SqliteFileSystem(DB(db));
  }

  late Directory _currentDirectory = () {
    final dir = directory('/');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }();

  @override
  Directory get currentDirectory => _currentDirectory;

  @override
  set currentDirectory(dynamic value) {
    _currentDirectory = directory(utils.resolvePath(value));
  }

  @override
  late final Directory systemTempDirectory = directory(
    '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}/',
  );

  @override
  Directory directory(path) {
    return SqliteDirectory(this, utils.resolvePath(path));
  }

  @override
  File file(path) {
    return SqliteFile(this, utils.resolvePath(path));
  }

  @override
  Link link(path) {
    return SqliteLink(this, utils.resolvePath(path));
  }

  @override
  bool identicalSync(String path1, String path2) {
    final a = db.file(path1);
    final b = db.file(path2);
    return a == b;
  }

  @override
  Future<bool> identical(String path1, String path2) {
    return Future.value(identicalSync(path1, path2));
  }

  @override
  bool get isWatchSupported => true;

  @override
  p.Context get path => p.context;

  @override
  FileStat statSync(String path) {
    final file = db.file(path);
    if (file == null) return SqliteFileStat.notFound;
    return SqliteFileStat._(file);
  }

  @override
  Future<FileStat> stat(String path) {
    return Future.value(statSync(path));
  }

  @override
  FileSystemEntityType typeSync(String path, {bool followLinks = true}) {
    var file = db.file(path);
    if (file == null) return FileSystemEntityType.notFound;
    if (followLinks) {
      while (file != null && file.isLink) {
        file = db.file(file.link!);
      }
    }
    if (file == null) return FileSystemEntityType.notFound;
    if (file.isDir) return FileSystemEntityType.directory;
    if (file.isLink) return FileSystemEntityType.link;
    return FileSystemEntityType.file;
  }

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks = true}) {
    return Future.value(typeSync(path, followLinks: followLinks));
  }

  void deleteTempDirectories() {
    final files =
        db
            .select('SELECT * FROM temp_directories')
            .map(DatabaseTempDir.new)
            .getAll();
    for (var file in files) {
      final dir = directory(file.path);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  }
}
