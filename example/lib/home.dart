import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite_fs/sqlite_fs.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.fs, required this.db});

  final SqliteFileSystem fs;
  final CommonDatabase db;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SignalsMixin {
  late final fs = widget.fs;
  late final db = widget.db;

  StreamSubscription? _watcher;
  late final selected = bindSignal(trackedSignal<FileSystemEntity?>(null));

  late final dir = createSignal<Directory>(widget.fs.directory('/'));
  late final files = createSignal<List<FileSystemEntity>>([]);

  void _refresh() {
    final target = selected() ?? widget.fs.directory('/');
    if (target is Directory) {
      files.value = target.listSync(followLinks: false).toList();
    } else if (target is File) {
      files.value = target.parent.listSync(followLinks: false).toList();
    } else if (target is Link) {
      files.value = target.parent.listSync(followLinks: false).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    createEffect(() {
      _refresh();
      _watcher?.cancel();
      _watcher = dir().watch().listen((event) {
        _refresh();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width ~/ 100;
    final current = selected() ?? widget.fs.directory('/');
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLite File System'),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: GridView.count(
        crossAxisCount: crossAxisCount,
        children: [
          FileSystemEntityWidget(
            entity: current.parent,
            onTap: selected.set,
            label: '..',
            selected: '',
          ),
          for (final file in files())
            FileSystemEntityWidget(
              entity: file,
              onTap: selected.set,
              selected: current.path,
            ),
        ],
      ),
      persistentFooterButtons: [
        if (current is Directory)
          TextButton.icon(
            label: Text('Add File'),
            icon: Icon(Icons.add),
            onPressed: () {
              int count = 0;

              String name() {
                return '$count-file.txt';
              }

              while (fs.file(fs.path.join(current.path, name())).existsSync()) {
                count++;
              }
              final file = fs.file(
                fs.path.normalize(fs.path.join(current.path, name())),
              );
              file.createSync(recursive: true);
              file.writeAsStringSync('Hello, World!');
              _refresh();
            },
          ),
        TextButton.icon(
          label: Text('Add Link'),
          icon: Icon(Icons.add),
          onPressed: () {
            int count = 0;

            String name() {
              return 'link-$count-${fs.path.basename(current.path)}';
            }

            while (fs
                .link(fs.path.join(current.parent.path, name()))
                .existsSync()) {
              count++;
            }
            final link = fs.link(
              fs.path.normalize(fs.path.join(current.parent.path, name())),
            );
            link.createSync(current.path, recursive: true);
            _refresh();
          },
        ),
        if (current is Directory)
          TextButton.icon(
            label: Text('Add Directory'),
            icon: Icon(Icons.add),
            onPressed: () {
              int count = 0;

              String name() {
                return 'dir-$count';
              }

              while (fs
                  .directory(fs.path.join(current.path, name()))
                  .existsSync()) {
                count++;
              }

              final dir = fs.directory(
                fs.path.normalize(fs.path.join(current.path, name())),
              );
              dir.createSync(recursive: true);
              _refresh();
            },
          ),
      ],
    );
  }
}

class FileSystemEntityWidget extends StatelessWidget {
  const FileSystemEntityWidget({
    super.key,
    required this.entity,
    required this.onTap,
    required this.selected,
    this.label,
  });

  final FileSystemEntity entity;
  final ValueChanged<FileSystemEntity?> onTap;
  final String? label;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final isDir = entity is Directory;
    final isLink = entity is Link;
    final isFile = entity is File;
    final isSelected = entity.path == selected;
    final colors = Theme.of(context).colorScheme;
    final bgColor = isDir ? colors.secondary : colors.primary;
    // final fgColor = isDir ? colors.onSecondary : colors.onPrimary;
    return Container(
      decoration:
          isSelected
              ? BoxDecoration(
                border: Border.all(color: colors.primary, width: 1),
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => onTap(isSelected ? null : entity),
            child: Center(
              child: Icon(
                isDir
                    ? isLink
                        ? Icons.folder_outlined
                        : Icons.folder
                    : isFile
                    ? Icons.file_copy
                    : isLink
                    ? Icons.file_copy_outlined
                    : Icons.error,
                color: bgColor,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label ?? entity.path.split('/').last,
            style: TextStyle(color: colors.onSurface, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
