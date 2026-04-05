class Link {
  final String id;
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? folderId;
  final String? createdAt;
  final Map<String, dynamic>? translations;
  final Map<String, dynamic>? overrides;

  Link({
    required this.id,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.folderId,
    this.createdAt,
    this.translations,
    this.overrides,
  });

  factory Link.fromJson(Map<String, dynamic> j) => Link(
        id: j['id'] ?? '',
        url: j['url'] ?? '',
        title: j['title'],
        description: j['description'],
        imageUrl: j['fullImageUrl'],
        folderId: j['folderId'],
        createdAt: j['createdAt'],
        translations: j['translations'] as Map<String, dynamic>?,
        overrides: j['overrides'] as Map<String, dynamic>?,
      );

  String getTitle(String lang) {
    final t = overrides?[lang]?['title'] ??
        translations?[lang]?['title'] ??
        title ??
        url;
    return t.length > 100 ? '${t.substring(0, 100)}…' : t;
  }

  String getDescription(String lang) {
    return overrides?[lang]?['description'] ??
        translations?[lang]?['description'] ??
        description ??
        '';
  }

  List<String> availableLanguages() {
    final langs = <String>{};
    if (translations != null) langs.addAll(translations!.keys);
    if (overrides != null) langs.addAll(overrides!.keys);
    return langs.toList();
  }
}

class CreateLinkRequest {
  final String url;
  final String? folderId;

  CreateLinkRequest({required this.url, this.folderId});

  Map<String, dynamic> toJson() => {'url': url, 'folderId': folderId};
}
