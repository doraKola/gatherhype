import 'package:flutter/material.dart';
import '../../core/services/folders_service.dart';
import '../../core/services/i18n_service.dart';

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
        title: Text(I18nService.t('hub.newFolder')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(labelText: I18nService.t('hub.folderName')),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(I18nService.t('hub.cancel')),
          ),
          FilledButton(
            onPressed: loading ? null : () async {
              if (ctrl.text.trim().isEmpty) return;
              setState(() { loading = true; error = null; });
              try {
                await onCreate(ctrl.text.trim(), parentId);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (_) {
                setState(() { error = I18nService.t('share.failedToCreate'); loading = false; });
              }
            },
            child: loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(I18nService.t('hub.create')),
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
        title: Text(I18nService.t('hub.addLink')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: I18nService.t('hub.pasteUrl')),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(I18nService.t('hub.cancel')),
          ),
          FilledButton(
            onPressed: loading ? null : () async {
              if (ctrl.text.trim().isEmpty) return;
              setState(() { loading = true; error = null; });
              try {
                await onCreate(ctrl.text.trim(), folderId);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (_) {
                setState(() { error = I18nService.t('share.failedToAdd'); loading = false; });
              }
            },
            child: loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(I18nService.t('hub.save')),
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
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(I18nService.t('hub.cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(I18nService.t('hub.delete')),
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
        title: Text('${I18nService.t('share.sharing')} "$folderName"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: I18nService.t('share.emailPlaceholder')),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 12)),
            ],
            if (success) ...[
              const SizedBox(height: 6),
              Text(I18nService.t('share.invitationSent'),
                  style: const TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(I18nService.t('hub.close')),
          ),
          FilledButton(
            onPressed: loading ? null : () async {
              if (ctrl.text.trim().isEmpty) return;
              setState(() { loading = true; error = null; success = false; });
              try {
                await FoldersService().shareFolder(folderId, ctrl.text.trim(), 1);
                setState(() { loading = false; success = true; });
                ctrl.clear();
              } catch (_) {
                setState(() { error = I18nService.t('share.failedToShare'); loading = false; });
              }
            },
            child: loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(I18nService.t('share.shareBtn')),
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
            if (ctx.mounted) setState(() { error = I18nService.t('hub.loadingSummary'); loading = false; });
          });
        }
        return AlertDialog(
          title: Row(children: [
            Icon(Icons.auto_awesome, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            Text(I18nService.t('hub.folderSummary')),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: loading
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : error != null
                    ? Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))
                    : data != null
                        ? SingleChildScrollView(child: Text(data!['summary']?.toString() ?? ''))
                        : Text(I18nService.t('hub.noSummaryYet')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(I18nService.t('hub.close')),
            ),
            FilledButton.icon(
              onPressed: (generating || loading) ? null : () async {
                setState(() { generating = true; error = null; });
                try {
                  final d = await onGenerate();
                  if (ctx.mounted) setState(() { data = d; generating = false; });
                } catch (_) {
                  if (ctx.mounted) setState(() { error = I18nService.t('hub.generating'); generating = false; });
                }
              },
              icon: generating
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 16),
              label: Text(generating
                  ? I18nService.t('hub.generating')
                  : I18nService.t('hub.refresh')),
            ),
          ],
        );
      },
    ),
  );
}
