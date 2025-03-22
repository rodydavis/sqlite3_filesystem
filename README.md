# sqlite_fs

Using the package `sqlite3` to create a file system from the package `file` in Dart.

```dart
import 'package:file/file.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_fs/sqlite_fs.dart';

void main() {
  final fs = SqliteFileSystem.fromDb(sqlite3.openInMemory());

  final dir = fs.directory('temp');
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);

  _addFile(fs, dir, 'file1.txt');
  _addFile(fs, dir, 'file2.txt');

  _addDirectory(fs, dir, 'dir1');
  _addDirectory(fs, dir, 'dir2');

  final files = dir.listSync();
  final paths = files.map((file) => file.path).toList();
  print('paths: $paths');

  dir.deleteSync(recursive: true);
  fs.db.close();
}

File _addFile(FileSystem fs, Directory dir, String path) {
  final file = fs.file(fs.path.join(dir.path, path));
  file.writeAsStringSync('Hello, world!');
  return file;
}

Directory _addDirectory(FileSystem fs, Directory dir, String path) {
  final directory = fs.directory(fs.path.join(dir.path, path));
  directory.createSync(recursive: true);
  return directory;
}
```