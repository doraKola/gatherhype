import '../models/link_model.dart';
import '../utils/app_config.dart';
import 'api_client.dart';

class LinksService {
  static final LinksService _i = LinksService._();
  factory LinksService() => _i;
  LinksService._();

  final _api = ApiClient();
  final _base = '${AppConfig.apiUrl}/links';

  Future<List<Link>> getLinks({String? folderId}) async {
    final url = folderId != null ? '$_base?folderId=$folderId' : _base;
    final data = await _api.get(url) as List<dynamic>;
    return data.map((e) => Link.fromJson(e)).toList();
  }

  Future<Link> createLink(CreateLinkRequest req) async {
    final data = await _api.post(_base, req.toJson());
    return Link.fromJson(data);
  }

  Future<void> deleteLink(String id) async {
    await _api.delete('$_base/$id');
  }

  Future<void> moveLink(String linkId, String? folderId) async {
    await _api.patch('$_base/$linkId/move', {'folderId': folderId});
  }

  Future<void> updateTextOverride(String linkId, String language, {String? title, String? description}) async {
    await _api.patch('$_base/$linkId/override', {
      'language': language,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    });
  }
}
