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
  List<dynamic> _results = [];
  bool _loading = false;
  bool _open = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) setState(() => _open = false);
    });
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _results = []; _open = false; });
      return;
    }
    setState(() { _loading = true; _open = true; });
    try {
      final data = await ApiClient().get('${AppConfig.apiUrl}/search?q=${Uri.encodeComponent(q)}');
      setState(() { _results = data as List<dynamic>? ?? []; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            onChanged: (v) => _search(v),
            decoration: InputDecoration(
              hintText: 'Search folders & links...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() { _results = []; _open = false; });
                      })
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          if (_open && (_results.isNotEmpty || _loading))
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final item = _results[i] as Map<String, dynamic>;
                          final isFolder = item['type'] == 'folder';
                          return ListTile(
                            dense: true,
                            leading: Icon(isFolder ? Icons.folder_outlined : Icons.link, size: 16),
                            title: Text(item['name'] ?? item['title'] ?? item['url'] ?? '', style: const TextStyle(fontSize: 13)),
                            subtitle: isFolder ? null : Text(item['folderName'] ?? '', style: const TextStyle(fontSize: 11)),
                            onTap: () {
                              _ctrl.clear();
                              setState(() { _results = []; _open = false; });
                              _focus.unfocus();
                              widget.onSelected(item);
                            },
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
