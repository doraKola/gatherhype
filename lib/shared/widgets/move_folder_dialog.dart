import 'package:flutter/material.dart';
import '../../core/models/folder_model.dart';

class MoveFolderDialog extends StatefulWidget {
  final FolderTree folderToMove;
  final List<FolderTree> allFolders;
  final void Function(String folderId, String? targetFolderId) onMoved;
  final VoidCallback onClose;

  const MoveFolderDialog({
    super.key,
    required this.folderToMove,
    required this.allFolders,
    required this.onMoved,
    required this.onClose,
  });

  @override
  State<MoveFolderDialog> createState() => _MoveFolderDialogState();
}

class _MoveFolderDialogState extends State<MoveFolderDialog> {
  String? _selectedTargetId; // null = root

  bool _isDescendant(FolderTree folder, String targetId) {
    if (folder.id == targetId) return true;
    return folder.children.any((c) => _isDescendant(c, targetId));
  }

  List<Widget> _buildOptions(List<FolderTree> folders, int depth) {
    final items = <Widget>[];
    for (final f in folders) {
      // Skip self and descendants
      if (f.id == widget.folderToMove.id) continue;
      if (_isDescendant(widget.folderToMove, f.id)) continue;

      final isSelected = _selectedTargetId == f.id;
      items.add(InkWell(
        onTap: () => setState(() => _selectedTargetId = f.id),
        child: Container(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4) : null,
          padding: EdgeInsets.only(left: 16.0 + depth * 16, right: 16, top: 10, bottom: 10),
          child: Row(children: [
            Icon(Icons.folder_outlined, size: 18, color: isSelected ? Theme.of(context).colorScheme.primary : null),
            const SizedBox(width: 8),
            Text(f.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ]),
        ),
      ));
      items.addAll(_buildOptions(f.children, depth + 1));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Move "${widget.folderToMove.name}"'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select destination:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Root option
                    InkWell(
                      onTap: () => setState(() => _selectedTargetId = null),
                      child: Container(
                        color: _selectedTargetId == null
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
                            : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(children: [
                          Icon(Icons.home_outlined, size: 18,
                              color: _selectedTargetId == null ? Theme.of(context).colorScheme.primary : null),
                          const SizedBox(width: 8),
                          Text('Root (top level)',
                              style: TextStyle(fontWeight: _selectedTargetId == null ? FontWeight.w600 : FontWeight.normal)),
                        ]),
                      ),
                    ),
                    ..._buildOptions(widget.allFolders, 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
        FilledButton(
          onPressed: () => widget.onMoved(widget.folderToMove.id, _selectedTargetId),
          child: const Text('Move here'),
        ),
      ],
    );
  }
}
