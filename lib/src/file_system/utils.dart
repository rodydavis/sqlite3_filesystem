import 'package:collection/collection.dart';

import 'io.dart' as io;

/// [path] can be either a [`String`], a [`Uri`], or a [`FileSystemEntity`].
String resolvePath(dynamic pathLike) {
  if (pathLike is String) {
    return pathLike;
  } else if (pathLike is Uri) {
    return pathLike.toFilePath();
  } else if (pathLike is io.FileSystemEntity) {
    return pathLike.path;
  } else {
    throw ArgumentError.value(pathLike, 'path', 'Invalid path type');
  }
}

List<int> concatBytes(List<int> a, List<int> b) {
  final result = List<int>.filled(a.length + b.length, 0, growable: false);
  result.setRange(0, a.length, a);
  result.setRange(a.length, result.length, b);
  return result;
}

bool compareBytes(List<int>? a, List<int>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  return const ListEquality<int>().equals(a, b);
}

/// Tells if the specified file mode represents a write mode.
bool isWriteMode(io.FileMode mode) =>
    mode == io.FileMode.write ||
    mode == io.FileMode.append ||
    mode == io.FileMode.writeOnly ||
    mode == io.FileMode.writeOnlyAppend;

/// Tells whether the given string is empty.
bool isEmpty(String str) => str.isEmpty;

// /// Returns the node ultimately referred to by [link]. This will resolve
// /// the link references (following chains of links as necessary) and return
// /// the node at the end of the link chain.
// ///
// /// If a loop in the link chain is found, this will throw a
// /// [FileSystemException], calling [path] to generate the path.
// ///
// /// If [ledger] is specified, the resolved path to the terminal node will be
// /// appended to the ledger (or overwritten in the ledger if a link target
// /// specified an absolute path). The path will not be normalized, meaning
// /// `..` and `.` path segments may be present.
// ///
// /// If [tailVisitor] is specified, it will be invoked for the tail element of
// /// the last link in the symbolic link chain, and its return value will be the
// /// return value of this method (thus allowing callers to create the entity
// /// at the end of the chain on demand).
// Node resolveLinks(
//   LinkNode link,
//   PathGenerator path, {
//   List<String>? ledger,
//   Node? Function(DirectoryNode parent, String childName, Node? child)?
//   tailVisitor,
// }) {
//   // Record a breadcrumb trail to guard against symlink loops.
//   var breadcrumbs = <LinkNode>{};

//   Node node = link;
//   while (isLink(node)) {
//     link = node as LinkNode;
//     if (!breadcrumbs.add(link)) {
//       throw common.tooManyLevelsOfSymbolicLinks(path() as String);
//     }
//     if (ledger != null) {
//       if (link.fs.path.isAbsolute(link.target)) {
//         ledger.clear();
//       } else if (ledger.isNotEmpty) {
//         ledger.removeLast();
//       }
//       ledger.addAll(link.target.split(link.fs.path.separator));
//     }
//     node = link.getReferent(
//       tailVisitor: (DirectoryNode parent, String childName, Node? child) {
//         if (tailVisitor != null && !isLink(child)) {
//           // Only invoke [tailListener] on the final resolution pass.
//           child = tailVisitor(parent, childName, child);
//         }
//         return child;
//       },
//     );
//   }

//   return node;
// }
