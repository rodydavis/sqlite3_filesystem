import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_fs/sqlite_fs.dart';
import 'package:test/test.dart';

void main() {
  late FileSystem fs;
  late DB db;

  setUp(() {
    db = DB(sqlite3.openInMemory());
    fs = SqliteFileSystem(db);
    fs.file('/foo').createSync(recursive: true);
    fs.file('/path/to/file').createSync(recursive: true);
    fs.directory('/path/to/directory').createSync(recursive: true);
  });

  tearDown(() {
    fs.file('/foo').deleteSync();
    fs.file('/path/to/file').deleteSync();
    fs.directory('/path/to/directory').deleteSync();
    db.close();
  });

  test('some test', () {
    expectFileSystemException(ErrorCodes.ENOENT, () {
      fs.directory('').resolveSymbolicLinksSync();
    });
    expect(fs.file('/path/to/file'), isFile);
    expect(fs.directory('/path/to/directory'), isDirectory);
    expect(fs.file('/foo'), exists);
  });
}
