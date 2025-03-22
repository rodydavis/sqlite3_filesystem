part of '../fs.dart';

/// Generates a path to use in error messages.
typedef PathGenerator = dynamic Function();

/// Throws a `FileSystemException` if [object] is null.
void checkExists(Object? object, PathGenerator path) {
  if (object == null) {
    throw common.noSuchFileOrDirectory(path() as String);
  }
}
