import '../models/folder_model.dart';
import '../utils/app_config.dart';
import 'api_client.dart';

class FoldersService {
  static final FoldersService _i = FoldersService._();
  factory FoldersService() => _i;
  FoldersService._();

  final _api = ApiClient();
  final _base = '${AppConfig.apiUrl}/folders';

  Future<List<FolderTree>> getFoldersTree() async {
    final data = await _api.get('$_base/tree') as List<dynamic>;
    return data.map((e) => FolderTree.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getFolders({String? parentId}) async {
    final url = parentId != null ? '$_base?parentId=$parentId' : _base;
    return await _api.get(url) as Map<String, dynamic>;
  }

  Future<Folder> createFolder(String name, String? parentId) async {
    final data = await _api.post(_base, {'name': name, 'parentId': parentId});
    return Folder.fromJson(data);
  }

  Future<List<Folder>> getFolderParents(String folderId) async {
    final data = await _api.get('$_base/$folderId/parents') as List<dynamic>;
    return data.map((e) => Folder.fromJson(e)).toList();
  }

  Future<void> deleteFolder(String id) async {
    await _api.delete('$_base/$id');
  }

  Future<void> shareFolder(String folderId, String email, int permission) async {
    await _api.post('$_base/$folderId/share', {'email': email, 'permission': permission});
  }

  Future<void> removeShare(String folderId, String userId) async {
    await _api.delete('$_base/$folderId/share/$userId');
  }

  Future<void> moveFolder(String folderId, String? targetFolderId) async {
    await _api.patch('$_base/$folderId/move', {'targetFolderId': targetFolderId});
  }

  Future<Map<String, dynamic>?> getFolderSummary(String folderId) async {
    return await _api.get('$_base/$folderId/summary') as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> generateFolderSummary(String folderId) async {
    return await _api.post('$_base/$folderId/summary/generate', {}) as Map<String, dynamic>;
  }
}
