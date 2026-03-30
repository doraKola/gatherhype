import 'package:flutter/material.dart';
import '../../core/services/folders_service.dart';

// ─────────────────────────────────────────
//  ADD FOLDER DIALOG
// ─────────────────────────────────────────
Future<void> showAddFolderDialog(
  BuildContext context, {
  String? parentId,
  required Future<void> Function(String name, String? parentId) onCreate,
}) async {
  final ctrl = TextEditingController();
  String? error;
  bool loading = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('New folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Folder name'),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: loading ? null : () async {
              if (ctrl.text.trim().isEmpty) return;
              setState(() { loading = true; error = null; });
              try {
                await onCreate(ctrl.text.trim(), parentId);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (_) {
                setState(() { error = 'Failed to create folder'; loading = false; });
              }
            },
            child: loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────
//  ADD LINK DIALOG
// ─────────────────────────────────────────
Future<void> showAddLinkDialog(
  BuildContext context, {
  String? folderId,
  required Future<void> Function(String url, String? folderId) onCreate,
}) async {
  final ctrl = TextEditingController();
  String? error;
  bool loading = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Add link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Paste link URL'),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: loading ? null : () async {
              if (ctrl.text.trim().isEmpty) return;
              setState(() { loading = true; error = null; });
              try {
                await onCreate(ctrl.text.trim(), folderId);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (_) {
                setState(() { error = 'Failed to add link'; loading = false; });
              }
            },
            child: loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────
//  DELETE CONFIRM DIALOG
// ─────────────────────────────────────────
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─────────────────────────────────────────
//  SHARE FOLDER DIALOG
// ─────────────────────────────────────────
Future<void> showShareFolderDialog(
  BuildContext context, {
  required String folderId,
  required String folderName,
}) async {
  final ctrl = TextEditingController();
  String? error;
  bool loading = false;
  bool success = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Share "$folderName"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 12)),
            ],
            if (success) ...[
              const SizedBox(height: 6),
              const Text('Invitation sent!', style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(
            onPressed: loading ? null : () async {
              if (ctrl.text.trim().isEmpty) return;
              setState(() { loading = true; error = null; success = false; });
              try {
                await FoldersService().shareFolder(folderId, ctrl.text.trim(), 1);
                setState(() { loading = false; success = true; });
                ctrl.clear();
              } catch (_) {
                setState(() { error = 'Failed to share folder'; loading = false; });
              }
            },
            child: loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Share'),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────
//  AI SUMMARY DIALOG
// ─────────────────────────────────────────
Future<void> showSummaryDialog(
  BuildContext context, {
  required Future<Map<String, dynamic>?> Function() onLoad,
  required Future<Map<String, dynamic>> Function() onGenerate,
}) async {
  Map<String, dynamic>? data;
  bool loading = true;
  bool generating = false;
  String? error;
  bool initialized = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        if (!initialized) {
          initialized = true;
          onLoad().then((d) {
            if (ctx.mounted) setState(() { data = d; loading = false; });
          }).catchError((_) {
            if (ctx.mounted) setState(() { error = 'Failed to load summary'; loading = false; });
          });
        }
        return AlertDialog(
          title: Row(children: [
            Icon(Icons.auto_awesome, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Folder Summary'),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: loading
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : error != null
                    ? Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))
                    : data != null
                        ? SingleChildScrollView(child: Text(data!['summary']?.toString() ?? ''))
                        : const Text('No summary yet. Click Refresh to generate one.'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            FilledButton.icon(
              onPressed: (generating || loading) ? null : () async {
                setState(() { generating = true; error = null; });
                try {
                  final d = await onGenerate();
                  if (ctx.mounted) setState(() { data = d; generating = false; });
                } catch (_) {
                  if (ctx.mounted) setState(() { error = 'Failed to generate summary'; generating = false; });
                }
              },
              icon: generating
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 16),
              label: Text(generating ? 'Generating...' : 'Refresh'),
            ),
          ],
        );
      },
    ),
  );
}
