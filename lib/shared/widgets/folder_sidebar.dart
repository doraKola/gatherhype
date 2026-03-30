import 'package:flutter/material.dart';
import '../../core/models/folder_model.dart';

class FolderSidebar extends StatelessWidget {
  final List<dynamic> folders; // Folder or virtual shared root
  final String? selectedFolderId;
  final bool isShared;
  final void Function(dynamic folder) onFolderTap;
  final void Function(dynamic folder)? onDeleteFolder;
  final void Function(dynamic folder)? onShareFolder;
  final void Function(dynamic folder)? onMoveFolder;

  const FolderSidebar({
    super.key,
    required this.folders,
    required this.selectedFolderId,
    required this.onFolderTap,
    this.onDeleteFolder,
    this.onShareFolder,
    this.onMoveFolder,
    this.isShared = false,
  });

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No folders yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folders.length,
      itemBuilder: (_, i) => _FolderTile(
        folder: folders[i],
        isSelected: selectedFolderId == _id(folders[i]),
        isShared: isShared || (_isShared(folders[i])),
        onTap: () => onFolderTap(folders[i]),
        onDelete: onDeleteFolder != null ? () => onDeleteFolder!(folders[i]) : null,
        onShare: onShareFolder != null ? () => onShareFolder!(folders[i]) : null,
        onMove: onMoveFolder != null ? () => onMoveFolder!(folders[i]) : null,
      ),
    );
  }

  String _id(dynamic f) => f is Folder ? f.id : f['id'] as String? ?? '';
  bool _isShared(dynamic f) => f is Folder ? f.isShared : f['isShared'] as bool? ?? false;
}

class _FolderTile extends StatelessWidget {
  final dynamic folder;
  final bool isSelected;
  final bool isShared;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onMove;

  const _FolderTile({
    required this.folder,
    required this.isSelected,
    required this.isShared,
    required this.onTap,
    this.onDelete,
    this.onShare,
    this.onMove,
  });

  String get _name => folder is Folder ? folder.name : folder['name'] as String? ?? '';
  bool get _isVirtual => folder is Map && folder['isVirtual'] == true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : null;

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(
        isShared ? Icons.folder_shared : Icons.folder_outlined,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        _name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      trailing: _isVirtual
          ? null
          : PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 16, color: theme.colorScheme.onSurfaceVariant),
              itemBuilder: (_) => [
                if (onShare != null)
                  const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 16), SizedBox(width: 8), Text('Share')])),
                if (onMove != null)
                  const PopupMenuItem(value: 'move', child: Row(children: [Icon(Icons.drive_file_move_outlined, size: 16), SizedBox(width: 8), Text('Move')])),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
              onSelected: (v) {
                if (v == 'share') onShare?.call();
                if (v == 'move') onMove?.call();
                if (v == 'delete') onDelete?.call();
              },
            ),
    );
  }
}
