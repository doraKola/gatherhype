import 'package:flutter/material.dart';
import '../../core/utils/app_config.dart';
import '../../core/services/api_client.dart';

class SearchBar2 extends StatefulWidget {
  final void Function(Map<String, dynamic> item) onSelected;

  const SearchBar2({super.key, required this.onSelected});

  @override
  State<SearchBar2> createState() => _SearchBar2State();
}

class _SearchBar2State extends State<SearchBar2> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _layerLink = LayerLink();
  List<dynamic> _results = [];
  bool _loading = false;
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _closeOverlay();
    });
  }

  @override
  void dispose() {
    _closeOverlay();
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      _closeOverlay();
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    _showOverlay();
    try {
      final data = await ApiClient().get(
        '${AppConfig.apiUrl}/search/global-search?searchText=${Uri.encodeComponent(q)}&filters=all',
      );
      setState(() {
        _results = data as List<dynamic>? ?? [];
        _loading = false;
      });
      _showOverlay();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showOverlay() {
    _closeOverlay();
    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final item = _results[i] as Map<String, dynamic>;
                        final isFolder = item['type'] == 'folder';
                        final label = item['name'] ?? item['title'] ?? item['url'] ?? '';
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(isFolder ? Icons.folder_outlined : Icons.link, size: 14),
                          title: Text(
                            label,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            _ctrl.clear();
                            _closeOverlay();
                            _focus.unfocus();
                            widget.onSelected(item);
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: 280,
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: _search,
          decoration: InputDecoration(
            hintText: 'Search folders & links...',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _ctrl.clear();
                      _closeOverlay();
                      setState(() => _results = []);
                    })
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
