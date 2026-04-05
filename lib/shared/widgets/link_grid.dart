import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/link_model.dart';

class LinkGrid extends StatefulWidget {
  final List<Link> links;
  final bool isLoading;
  final String globalLanguage;
  final String? highlightedLinkId;
  final bool isShared;
  final void Function(Link link, String language)? onDelete;
  final void Function(Link link)? onMove;
  final void Function(Link link, String language)? onEdit;

  const LinkGrid({
    super.key,
    required this.links,
    required this.globalLanguage,
    this.isLoading = false,
    this.highlightedLinkId,
    this.isShared = false,
    this.onDelete,
    this.onMove,
    this.onEdit,
  });

  @override
  State<LinkGrid> createState() => _LinkGridState();
}

class _LinkGridState extends State<LinkGrid> {
  final Map<String, String> _activeLang = {};

  String _lang(Link link) {
    if (_activeLang.containsKey(link.id)) return _activeLang[link.id]!;
    final available = link.availableLanguages();
    if (available.isEmpty || available.contains(widget.globalLanguage)) {
      return widget.globalLanguage;
    }
    return available.first;
  }

  @override
  void didUpdateWidget(LinkGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.globalLanguage != widget.globalLanguage) {
      _activeLang.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }

    if (widget.links.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No links here yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        childAspectRatio: 1.1, // Adjusted to prevent overflow by making cards taller
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: widget.links.length,
      itemBuilder: (_, i) => _LinkCard(
        link: widget.links[i],
        activeLang: _lang(widget.links[i]),
        isHighlighted: widget.highlightedLinkId == widget.links[i].id,
        isShared: widget.isShared,
        onOpen: () => _openUrl(widget.links[i].url),
        onDelete: widget.onDelete != null
            ? () => widget.onDelete!(widget.links[i], _lang(widget.links[i]))
            : null,
        onMove: widget.onMove != null && !widget.isShared
            ? () => widget.onMove!(widget.links[i])
            : null,
        onEdit: widget.onEdit != null
            ? () => widget.onEdit!(widget.links[i], _lang(widget.links[i]))
            : null,
        onLangChange: (lang) => setState(() => _activeLang[widget.links[i].id] = lang),
        availableLangs: widget.links[i].availableLanguages(),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LinkCard extends StatelessWidget {
  final Link link;
  final String activeLang;
  final bool isHighlighted;
  final bool isShared;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final VoidCallback? onMove;
  final VoidCallback? onEdit;
  final void Function(String) onLangChange;
  final List<String> availableLangs;

  const _LinkCard({
    required this.link,
    required this.activeLang,
    required this.onOpen,
    required this.onLangChange,
    required this.availableLangs,
    this.isHighlighted = false,
    this.isShared = false,
    this.onDelete,
    this.onMove,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = link.getTitle(activeLang);
    final desc = link.getDescription(activeLang);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: isHighlighted ? 2 : 1,
        ),
        color: isHighlighted
            ? theme.colorScheme.primaryContainer.withOpacity(0.2)
            : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: favicon + title (Horizontal Scroll) + menu
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showDetailsDialog(context, title, desc),
                    child: _Favicon(url: link.url),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  _buildPopupMenu(theme),
                ],
              ),
              
              // Description (Scrollable within a fixed height "cut")
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 40), 
                  child: SingleChildScrollView(
                    child: Text(
                      desc,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],

              // Image (Fixed height to prevent pushing content out)
              if (link.imageUrl != null && link.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    link.imageUrl!,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              
              // Language chips (Horizontal Scroll)
              if (availableLangs.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ([activeLang, ...availableLangs.where((l) => l != activeLang)]).map((lang) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () => onLangChange(lang),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeLang == lang
                                ? Colors.blue
                                : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lang.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: activeLang == lang
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 16, color: theme.colorScheme.onSurfaceVariant),
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
        if (onMove != null)
          const PopupMenuItem(value: 'move', child: Row(children: [Icon(Icons.drive_file_move_outlined, size: 16), SizedBox(width: 8), Text('Move')])),
        if (onDelete != null)
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'move') onMove?.call();
        if (v == 'delete') onDelete?.call();
      },
    );
  }

  void _showDetailsDialog(BuildContext context, String title, String desc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: desc.isNotEmpty
            ? ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: SingleChildScrollView(child: Text(desc)),
              )
            : null,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _Favicon extends StatelessWidget {
  final String url;
  const _Favicon({required this.url});

  String get _faviconUrl {
    try {
      final uri = Uri.parse(url);
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=32';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_faviconUrl.isEmpty) return const Icon(Icons.link, size: 16);
    return Image.network(
      _faviconUrl,
      width: 16,
      height: 16,
      errorBuilder: (_, __, ___) => const Icon(Icons.link, size: 16),
    );
  }
}