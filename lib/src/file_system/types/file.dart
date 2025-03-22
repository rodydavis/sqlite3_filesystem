part of '../fs.dart';

class SqliteFile extends SqliteFileSystemEntity<SqliteFile> implements File {
  SqliteFile(super.fileSystem, super.path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.file;

  @override
  File get absolute {
    return fileSystem.file(p.absolute(path));
  }

  @override
  File copySync(String newPath) {
    _checkFile(path);
    db.execute(
      '''
      INSERT INTO files (path, mode, data, size, link, is_dir, temp, created, modified)
      SELECT ?, mode, data, size, link, is_dir, temp, created, modified
      FROM files
      WHERE path = ?
      LIMIT 1
      ''',
      [newPath, path],
    );
    controller.add(
      FileSystemCreateEvent(
        newPath,
        expectedType == io.FileSystemEntityType.directory,
      ),
    );
    return fileSystem.file(newPath);
  }

  @override
  Future<File> copy(String newPath) {
    return Future.value(copySync(newPath));
  }

  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    if (existsSync()) {
      if (exclusive) {
        throw common.fileExists(path);
      }
      // File already exists and exclusive is false
      setLastModifiedSync(DateTime.now());
      return;
    }
    if (!recursive) {
      final parent = fileSystem.directory(p.dirname(path));
      _checkFile(parent.path);
    }
    _createAll(recursive: recursive);
    // File does not exist
    db.execute(
      'INSERT INTO files (path, mode, data, size, link, is_dir) VALUES (?, ?, NULL, 0, NULL, FALSE)',
      [path, SqliteFileMode.write.mode],
    );
    controller.add(
      FileSystemCreateEvent(
        path,
        expectedType == io.FileSystemEntityType.directory,
      ),
    );
  }

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) {
    createSync(recursive: recursive, exclusive: exclusive);
    return Future.value(this);
  }

  @override
  DateTime lastAccessedSync() {
    final file = _file(path);
    return file.accessed;
  }

  @override
  Future<DateTime> lastAccessed() {
    return Future.value(lastAccessedSync());
  }

  @override
  DateTime lastModifiedSync() {
    final file = _file(path);
    return file.modified;
  }

  @override
  Future<DateTime> lastModified() {
    return Future.value(lastModifiedSync());
  }

  @override
  int lengthSync() {
    final file = _file(path);
    return file.size ?? 0;
  }

  @override
  Future<int> length() {
    return Future.value(lengthSync());
  }

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    Uint8List data = Uint8List(0);

    final file = _file(path);
    data = file.data ?? Uint8List(0);

    void truncate(int length) {
      data.length = length;
      writeAsBytesSync(data);
    }

    void write(Uint8List bytes) {
      data = bytes;
      writeAsBytesSync(data);
    }

    return RandomAccessFileImpl(fileSystem, path, mode, (
      bytes: data,
      truncate: truncate,
      write: write,
    ));
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    return Future.value(openSync(mode: mode));
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    final file = _file(path);
    final bytes = file.data ?? Uint8List(0);
    final view = Uint8List.view(
      bytes.buffer,
      start ?? 0,
      end ?? bytes.lengthInBytes,
    );
    return Stream.value(view.toList());
  }

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    if (!utils.isWriteMode(mode)) {
      throw ArgumentError.value(
        mode,
        'mode',
        'Must be either WRITE, APPEND, WRITE_ONLY, or WRITE_ONLY_APPEND',
      );
    }
    return _FileSink.fromFile(this, mode, encoding);
  }

  @override
  Future<Uint8List> readAsBytes() {
    return Future.value(readAsBytesSync());
  }

  @override
  Uint8List readAsBytesSync() {
    final file = _file(path);
    setLastAccessedSync(DateTime.now());
    return file.data ?? Uint8List(0);
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) {
    return Future.value(readAsLinesSync(encoding: encoding));
  }

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    return encoding.decode(readAsBytesSync()).split('\n');
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    return Future.value(readAsStringSync(encoding: encoding));
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    return encoding.decode(readAsBytesSync());
  }

  @override
  void setLastAccessedSync(DateTime time) {
    _checkFile(path);
    db.execute('UPDATE files SET accessed = ? WHERE path = ?', [
      time.millisecondsSinceEpoch,
      path,
    ]);
  }

  @override
  Future setLastAccessed(DateTime time) {
    setLastAccessedSync(time);
    return Future.value();
  }

  @override
  void setLastModifiedSync(DateTime time) {
    _checkFile(path);
    db.execute('UPDATE files SET modified = ? WHERE path = ?', [
      time.millisecondsSinceEpoch,
      path,
    ]);
    controller.add(
      FileSystemModifyEvent(
        path,
        expectedType == io.FileSystemEntityType.directory,
        false,
      ),
    );
  }

  @override
  Future setLastModified(DateTime time) {
    setLastModifiedSync(time);
    return Future.value();
  }

  void setLastChangedSync(DateTime time) {
    _checkFile(path);
    db.execute('UPDATE files SET changed = ? WHERE path = ?', [
      time.millisecondsSinceEpoch,
      path,
    ]);
  }

  Future setLastChanged(DateTime time) {
    setLastChangedSync(time);
    return Future.value();
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = SqliteFileMode.write,
    bool flush = false,
  }) {
    int modeValue = SqliteFileMode.write.mode;
    if (mode is SqliteFileMode) {
      modeValue = mode.mode;
    }
    if (![
      SqliteFileMode.write,
      SqliteFileMode.writeOnly,
      SqliteFileMode.writeOnlyAppend,
      SqliteFileMode.append,
    ].map((e) => e.mode).contains(modeValue)) {
      throw ArgumentError.value(
        mode,
        'mode',
        'Must be either WRITE, APPEND, WRITE_ONLY, or WRITE_ONLY_APPEND',
      );
    }
    final file = _file(path);
    if (modeValue == SqliteFileMode.writeOnlyAppend.mode ||
        modeValue == SqliteFileMode.append.mode) {
      bytes = utils.concatBytes(file.data ?? [], bytes);
    }
    db.execute(
      'UPDATE files SET data = ?, size = ?, modified = ?, changed = ?, accessed = ?, mode = ? WHERE path = ?',
      [
        bytes,
        bytes.length,
        DateTime.now().millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch,
        modeValue,
        path,
      ],
    );
    controller.add(
      FileSystemModifyEvent(
        path,
        expectedType == io.FileSystemEntityType.directory,
        utils.compareBytes(file.data, bytes),
      ),
    );
  }

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {
    writeAsBytesSync(bytes, mode: mode, flush: flush);
    return Future.value(this);
  }

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    writeAsBytesSync(encoding.encode(contents), mode: mode, flush: flush);
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    writeAsStringSync(contents, mode: mode, encoding: encoding, flush: flush);
    return Future.value(this);
  }

  SqliteFile get _resolvedBackingOrCreate {
    var file = db.file(path);
    if (file == null) createSync();
    return this;
  }

  void _truncateIfNecessary(SqliteFile? file, io.FileMode mode) {
    if (mode == io.FileMode.write || mode == io.FileMode.writeOnly) {
      if (file == null) createSync();
      writeAsBytesSync(<int>[]);
    }
  }
}
