part of '../fs.dart';

/// Implementation of an [io.IOSink] that's backed by a [FileNode].
class _FileSink implements io.IOSink {
  factory _FileSink.fromFile(
    SqliteFile file,
    io.FileMode mode,
    Encoding encoding,
  ) {
    late SqliteFile node;
    Exception? deferredException;

    // Resolve the backing immediately to ensure that the [FileNode] we write
    // to is the same as when [openWrite] was called.  This can matter if the
    // file is moved or removed while open.
    try {
      node = file._resolvedBackingOrCreate;
    } on Exception catch (e) {
      // For behavioral consistency with [LocalFile], do not report failures
      // immediately.
      deferredException = e;
    }

    var future = Future<SqliteFile>.microtask(() {
      if (deferredException != null) {
        throw deferredException;
      }
      file._truncateIfNecessary(node, mode);
      return node;
    });
    return _FileSink._(future, encoding);
  }

  _FileSink._(Future<SqliteFile> node, this.encoding) : _pendingWrites = node;

  final Completer<void> _completer = Completer<void>();

  @override
  Encoding encoding;

  Future<SqliteFile> _pendingWrites;
  Completer<void>? _streamCompleter;
  bool _isClosed = false;

  bool get isStreaming => !(_streamCompleter?.isCompleted ?? true);

  @override
  void add(List<int> data) {
    _checkNotStreaming();
    if (_isClosed) {
      throw StateError('StreamSink is closed');
    }

    _addData(data);
  }

  @override
  void write(Object? obj) => add(encoding.encode(obj?.toString() ?? 'null'));

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    var firstIter = true;
    for (dynamic obj in objects) {
      if (!firstIter) {
        write(separator);
      }
      firstIter = false;
      write(obj);
    }
  }

  @override
  void writeln([Object? obj = '']) {
    write(obj);
    write('\n');
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _checkNotStreaming();
    _completer.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    _checkNotStreaming();
    _streamCompleter = Completer<void>();

    stream.listen(
      _addData,
      cancelOnError: true,
      onError: (Object error, StackTrace stackTrace) {
        _streamCompleter!.completeError(error, stackTrace);
        _streamCompleter = null;
      },
      onDone: () {
        _streamCompleter!.complete();
        _streamCompleter = null;
      },
    );
    return _streamCompleter!.future;
  }

  @override
  Future<void> flush() {
    _checkNotStreaming();
    return _pendingWrites;
  }

  @override
  Future<void> close() {
    _checkNotStreaming();
    if (!_isClosed) {
      _isClosed = true;
      _pendingWrites.then(
        (_) => _completer.complete(),
        onError: _completer.completeError,
      );
    }
    return _completer.future;
  }

  @override
  Future<void> get done => _completer.future;

  void _addData(List<int> data) {
    _pendingWrites = _pendingWrites.then((SqliteFile node) {
      node.writeAsBytesSync(data, mode: io.FileMode.writeOnly, flush: true);
      return node;
    });
  }

  void _checkNotStreaming() {
    if (isStreaming) {
      throw StateError('StreamSink is bound to a stream');
    }
  }
}
