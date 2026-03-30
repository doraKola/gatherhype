import 'package:flutter/material.dart';
import '../../core/models/folder_model.dart';
import '../../core/models/link_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/folders_service.dart';
import '../../core/services/links_service.dart';
import '../../core/services/user_service.dart';
import '../../features/auth/login_screen.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/widgets/folder_sidebar.dart';
import '../../shared/widgets/link_grid.dart';
import '../../shared/widgets/move_folder_dialog.dart';
import '../../shared/widgets/search_bar.dart';
import '../../../main.dart' show themeModeNotifier, toggleTheme;

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  // ── Services ──
  final _foldersService = FoldersService();
  final _linksService = LinksService();
  final _userService = UserService();
  final _authService = AuthService();

  // ── Folder state ──
  List<dynamic> _folders = [];    // top-level (owned + virtual shared root)
  List<dynamic> _subFolders = []; // children of selected folder
  List<dynamic> _sharedFolders = [];
  List<FolderTree> _foldersTree = [];

  String? _selectedFolderId;
  String? _selectedFolderName;
  String? _selectedSubFolderId;
  String? _selectedSubFolderName;
  List<Folder> _breadcrumbs = [];

  // ── Link state ──
  List<Link> _allLinks = [];
  List<Link> _links = [];
  bool _linksLoading = false;

  // ── Filter ──
  final _filterCtrl = TextEditingController();
  String _filterMode = 'both'; // 'both' | 'title' | 'description'
  bool _filterOpen = false;
  String? _highlightedLinkId;

  // ── Language ──
  String _globalLanguage = 'en';
  List<String> _allowedLanguages = [];
  bool _langDropdownOpen = false;

  // ── UI ──
  bool _drawerOpen = false;
  bool _subfoldersOpen = true;
  String? _toast;

  // ── Move folder ──
  FolderTree? _folderToMove;

  static const _sharedRoot = {
    'id': '__shared__',
    'name': 'With Me',
    'isVirtual': true,
    'isShared': false,
  };

  // ─────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _loadFoldersTree();
    _loadUserLanguages();
  }

  // ─────────────────────────────────────
  //  LOADERS
  // ─────────────────────────────────────

  Future<void> _loadFolders({String? parentId}) async {
    try {
      final data = await _foldersService.getFolders(parentId: parentId);
      final owned = (data['owned'] as List<dynamic>? ?? [])
          .map((e) => Folder.fromJson(e))
          .toList();
      final shared = (data['shared'] as List<dynamic>? ?? [])
          .map((e) => Folder.fromJson(e as Map<String, dynamic>))
          .toList();

      if (parentId == null) {
        setState(() {
          _sharedFolders = shared;
          _folders = [
            ...owned,
            if (shared.isNotEmpty) _sharedRoot,
          ];
        });
      } else {
        setState(() => _subFolders = owned);
      }
    } catch (_) {}
  }

  Future<void> _loadFoldersTree() async {
    try {
      final tree = await _foldersService.getFoldersTree();
      setState(() => _foldersTree = tree);
    } catch (_) {}
  }

  Future<void> _loadLinks(String? folderId) async {
    setState(() => _linksLoading = true);
    try {
      final links = await _linksService.getLinks(folderId: folderId);
      setState(() {
        _allLinks = links;
        _applyFilter();
        _linksLoading = false;
      });
    } catch (_) {
      setState(() => _linksLoading = false);
    }
  }

  Future<void> _loadBreadcrumbs(String folderId) async {
    if (folderId == '__shared__') return;
    try {
      final bc = await _foldersService.getFolderParents(folderId);
      setState(() => _breadcrumbs = bc);
    } catch (_) {}
  }

  Future<void> _loadUserLanguages() async {
    try {
      final res = await _userService.getTranslationSettings();
      final lang = await _authService.getDefaultLanguage();
      setState(() {
        _allowedLanguages = List<String>.from(res['allowedLanguages'] ?? []);
        _globalLanguage = res['defaultLanguage'] ?? lang ?? 'en';
      });
    } catch (_) {}
  }

  // ─────────────────────────────────────
  //  FOLDER SELECTION
  // ─────────────────────────────────────

  void _selectFolder(dynamic folder) {
    _resetFilter();

    if (folder == null) {
      _selectRoot();
      return;
    }

    final id = folder is Folder ? folder.id : folder['id'] as String;

    // Shared root
    if (id == '__shared__') {
      setState(() {
        _selectedFolderId = '__shared__';
        _selectedFolderName = 'With Me';
        _links = [];
        _subFolders = _sharedFolders;
      });
      return;
    }

    // Shared sub-folder
    if (folder is Folder && folder.isShared) {
      setState(() {
        _selectedFolderId = '__shared__';
        _selectedSubFolderId = folder.id;
        _selectedSubFolderName = folder.name;
      });
      _loadLinks(folder.id);
      return;
    }

    // Normal main folder
    final name = folder is Folder ? folder.name : folder['name'] as String;
    setState(() {
      _selectedFolderId = id;
      _selectedFolderName = name;
      _selectedSubFolderId = null;
      _selectedSubFolderName = null;
      _breadcrumbs = [];
    });
    _loadFolders(parentId: id);
    _loadLinks(id);
  }

  void _selectSubFolder(dynamic folder) {
    _resetFilter();
    final id = folder is Folder ? folder.id : folder['id'] as String;
    final name = folder is Folder ? folder.name : folder['name'] as String;
    setState(() {
      _selectedSubFolderId = id;
      _selectedSubFolderName = name;
    });
    _loadLinks(id);
    _loadBreadcrumbs(id);
    if (_selectedFolderId != '__shared__') {
      _loadFolders(parentId: id);
    }
  }

  void _selectRoot() {
    setState(() {
      _selectedFolderId = null;
      _selectedFolderName = null;
      _selectedSubFolderId = null;
      _selectedSubFolderName = null;
      _subFolders = [];
      _breadcrumbs = [];
      _links = [];
    });
  }

  // ─────────────────────────────────────
  //  FILTER
  // ─────────────────────────────────────

  void _applyFilter() {
    final q = _filterCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _links = List.from(_allLinks);
      return;
    }
    _links = _allLinks.where((link) {
      final title = link.getTitle(_globalLanguage).toLowerCase();
      final desc = link.getDescription(_globalLanguage).toLowerCase();
      switch (_filterMode) {
        case 'title': return title.contains(q);
        case 'description': return desc.contains(q);
        default: return title.contains(q) || desc.contains(q);
      }
    }).toList();
  }

  void _resetFilter() {
    _filterCtrl.clear();
    _filterMode = 'both';
    _filterOpen = false;
  }

  // ─────────────────────────────────────
  //  FOLDERS CRUD
  // ─────────────────────────────────────

  Future<void> _createFolder(String name, String? parentId) async {
    final f = await _foldersService.createFolder(name, parentId);
    _loadFolders();
    _loadFoldersTree();
    if (parentId != null) _loadFolders(parentId: parentId);
    if (f.parentId == null) {
      _selectFolder(f);
      _loadLinks(f.id);
    }
  }

  Future<void> _deleteFolder(dynamic folder) async {
    final name = folder is Folder ? folder.name : folder['name'] as String;
    final id = folder is Folder ? folder.id : folder['id'] as String;
    final parentId = folder is Folder ? folder.parentId : null;

    final confirmed = await showDeleteConfirmDialog(context,
        title: 'Delete folder?',
        body: 'Delete "$name" and all its links?');
    if (!confirmed) return;

    await _foldersService.deleteFolder(id);
    _loadFoldersTree();

    if (parentId == null) {
      _selectRoot();
      _loadFolders();
    } else {
      _loadFolders(parentId: _selectedSubFolderId ?? _selectedFolderId);
    }
  }

  Future<void> _moveFolder(String folderId, String? targetFolderId) async {
    try {
      await _foldersService.moveFolder(folderId, targetFolderId);
      setState(() => _folderToMove = null);
      _loadFolders();
      _loadFoldersTree();
      if (_selectedFolderId == folderId || _selectedSubFolderId == folderId) {
        _selectRoot();
      } else if (_selectedSubFolderId != null) {
        _loadFolders(parentId: _selectedSubFolderId);
      } else if (_selectedFolderId != null) {
        _loadFolders(parentId: _selectedFolderId);
      }
    } catch (_) {}
  }

  FolderTree? _findInTree(List<FolderTree> folders, String id) {
    for (final f in folders) {
      if (f.id == id) return f;
      final found = _findInTree(f.children, id);
      if (found != null) return found;
    }
    return null;
  }

  // ─────────────────────────────────────
  //  LINKS CRUD
  // ─────────────────────────────────────

  Future<void> _createLink(String url, String? folderId) async {
    await _linksService.createLink(CreateLinkRequest(url: url, folderId: folderId));
    _loadLinks(_selectedSubFolderId ?? _selectedFolderId);
    _showToast('Link saved — translating to your languages...');
  }

  Future<void> _deleteLink(Link link, String language) async {
    final title = link.getTitle(language);
    final confirmed = await showDeleteConfirmDialog(context,
        title: 'Delete link?', body: 'Delete "$title"?');
    if (!confirmed) return;
    await _linksService.deleteLink(link.id);
    _loadLinks(_selectedSubFolderId ?? _selectedFolderId);
  }

  // ─────────────────────────────────────
  //  SEARCH
  // ─────────────────────────────────────

  void _onSearchSelect(Map<String, dynamic> item) {
    if (item['type'] == 'folder') {
      _selectFolder({
        'id': item['id'],
        'name': item['name'],
        'isShared': item['isShared'] ?? false,
      });
    } else if (item['type'] == 'link') {
      _filterCtrl.text = item['searchQuery'] ?? item['title'] ?? '';
      _selectFolder({
        'id': item['folderId'],
        'name': item['folderName'],
        'isShared': item['isShared'] ?? false,
      });
      Future.delayed(Duration.zero, () {
        _applyFilter();
        _highlightLink(item['id'] as String);
      });
    }
    setState(() {});
  }

  void _highlightLink(String id) {
    setState(() => _highlightedLinkId = id);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _highlightedLinkId = null);
    });
  }

  // ─────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────

  bool get _canAddContent =>
      (_selectedFolderId != null || _selectedSubFolderId != null) &&
      _selectedFolderId != '__shared__';

  String get _currentFolderLabel =>
      _selectedSubFolderName ?? _selectedFolderName ?? '';

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  // ─────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: _buildAppBar(isWide),
      drawer: isWide ? null : _buildDrawer(),
      body: Stack(
        children: [
          isWide ? _buildWideLayout() : _buildNarrowLayout(),
          if (_toast != null) _buildToast(),
          if (_folderToMove != null) _buildMoveFolderDialog(),
        ],
      ),
      floatingActionButton: _canAddContent ? _buildFab() : null,
    );
  }

  AppBar _buildAppBar(bool isWide) {
    return AppBar(
      title: const Text('GatherHype', style: TextStyle(fontWeight: FontWeight.bold)),
      leading: isWide
          ? null
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      actions: [
        if (isWide) SearchBar2(onSelected: _onSearchSelect),
        const SizedBox(width: 8),
        if (_allowedLanguages.length > 1) _buildLangButton(),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (_, mode, __) => IconButton(
            icon: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: mode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
            onPressed: toggleTheme,
          ),
        ),
        IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
      ],
    );
  }

  Widget _buildLangButton() {
    return PopupMenuButton<String>(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Text(_globalLanguage.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
            const Icon(Icons.expand_more, size: 16),
          ],
        ),
      ),
      itemBuilder: (_) => _allowedLanguages
          .map((lang) => PopupMenuItem(
                value: lang,
                child: Row(children: [
                  if (lang == _globalLanguage)
                    const Icon(Icons.check, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(lang.toUpperCase()),
                ]),
              ))
          .toList(),
      onSelected: (lang) => setState(() => _globalLanguage = lang),
    );
  }

  // ── Wide (desktop/tablet) layout ──
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar
        SizedBox(
          width: 220,
          child: _buildSidebarContent(),
        ),
        const VerticalDivider(width: 1),
        // Main content
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  // ── Narrow (mobile) layout ──
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SearchBar2(onSelected: _onSearchSelect),
        ),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  // ── Drawer for mobile ──
  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(child: _buildSidebarContent()),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
          child: Row(
            children: [
              const Text('Folders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                tooltip: 'New root folder',
                onPressed: () => showAddFolderDialog(context, onCreate: _createFolder),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: FolderSidebar(
              folders: _folders,
              selectedFolderId: _selectedFolderId,
              onFolderTap: _selectFolder,
              onDeleteFolder: _deleteFolder,
              onShareFolder: (f) {
                final folder = f as Folder;
                showShareFolderDialog(context, folderId: folder.id, folderName: folder.name);
              },
              onMoveFolder: (f) {
                final folder = f as Folder;
                final tree = _findInTree(_foldersTree, folder.id);
                if (tree != null) setState(() => _folderToMove = tree);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Empty hint
          if (!_canAddContent && _selectedFolderId == null)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Select a folder to add links or subfolders', style: TextStyle(color: Colors.grey))),
            ),

          // Breadcrumbs
          if (_breadcrumbs.isNotEmpty) _buildBreadcrumbs(),

          // Back button for shared
          if (_selectedFolderId == '__shared__')
            TextButton.icon(
              onPressed: _selectRoot,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
            ),

          // Current folder title
          if (_currentFolderLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_currentFolderLabel,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

          // Subfolders
          if (_subFolders.isNotEmpty) _buildSubfoldersSection(),

          // Links header + filter
          if (_canAddContent) _buildLinksHeader(),

          // Link grid
          LinkGrid(
            links: _links,
            isLoading: _linksLoading,
            globalLanguage: _globalLanguage,
            highlightedLinkId: _highlightedLinkId,
            isShared: _selectedFolderId == '__shared__',
            onDelete: _deleteLink,
            onMove: (link) async {
              // TODO: move link dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _breadcrumbs.asMap().entries.map((entry) {
          final bc = entry.value;
          final isLast = entry.key == _breadcrumbs.length - 1;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _selectFolder({'id': bc.id, 'name': bc.name}),
                child: Text(bc.name,
                    style: TextStyle(
                        color: isLast ? null : Theme.of(context).colorScheme.primary,
                        fontWeight: isLast ? FontWeight.w600 : FontWeight.normal)),
              ),
              if (!isLast) const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('›')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubfoldersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _subfoldersOpen = !_subfoldersOpen),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Text('Subfolders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                Icon(_subfoldersOpen ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        if (_subfoldersOpen)
          FolderSidebar(
            folders: _subFolders,
            selectedFolderId: _selectedSubFolderId,
            isShared: _selectedFolderId == '__shared__',
            onFolderTap: _selectSubFolder,
            onDeleteFolder: _deleteFolder,
            onShareFolder: (f) {
              if (f is Folder) {
                showShareFolderDialog(context, folderId: f.id, folderName: f.name);
              }
            },
            onMoveFolder: (f) {
              if (f is Folder) {
                final tree = _findInTree(_foldersTree, f.id);
                if (tree != null) setState(() => _folderToMove = tree);
              }
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLinksHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text('Links', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          // Filter
          SizedBox(
            width: 200,
            child: TextField(
              controller: _filterCtrl,
              onChanged: (_) => setState(_applyFilter),
              decoration: InputDecoration(
                hintText: 'Filter links',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.filter_alt_outlined, size: 18),
                  onPressed: () => setState(() => _filterOpen = !_filterOpen),
                ),
                suffixIcon: _filterCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() { _filterCtrl.clear(); _applyFilter(); }))
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
          if (_filterOpen) ...[
            const SizedBox(width: 8),
            _buildFilterMenu(),
          ],
          // AI Summary
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Summary',
            onPressed: () => showSummaryDialog(
              context,
              onLoad: () => _foldersService.getFolderSummary(_selectedSubFolderId ?? _selectedFolderId!),
              onGenerate: () => _foldersService.generateFolderSummary(_selectedSubFolderId ?? _selectedFolderId!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['both', 'title', 'description'].map((mode) {
          final label = mode == 'both' ? 'Title + Description' : mode[0].toUpperCase() + mode.substring(1);
          return InkWell(
            onTap: () => setState(() { _filterMode = mode; _applyFilter(); }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: mode,
                    groupValue: _filterMode,
                    onChanged: (v) => setState(() { _filterMode = v!; _applyFilter(); }),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(label, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'add_link',
          onPressed: () => showAddLinkDialog(
            context,
            folderId: _selectedSubFolderId ?? _selectedFolderId,
            onCreate: _createLink,
          ),
          tooltip: 'Add link',
          child: const Icon(Icons.add_link),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'add_folder',
          onPressed: () => showAddFolderDialog(
            context,
            parentId: _selectedSubFolderId ?? _selectedFolderId,
            onCreate: _createFolder,
          ),
          tooltip: 'New folder',
          child: const Icon(Icons.create_new_folder_outlined),
        ),
      ],
    );
  }

  Widget _buildToast() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(_toast!, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildMoveFolderDialog() {
    return Dialog(
      child: MoveFolderDialog(
        folderToMove: _folderToMove!,
        allFolders: _foldersTree,
        onClose: () => setState(() => _folderToMove = null),
        onMoved: (folderId, targetId) => _moveFolder(folderId, targetId),
      ),
    );
  }
}
