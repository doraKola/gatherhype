// ---------- Folder ----------

class SharedUser {
  final String userId;
  final String email;
  final int permission; // 1=view, 2=edit
  final String sharedAt;

  SharedUser({required this.userId, required this.email, required this.permission, required this.sharedAt});

  factory SharedUser.fromJson(Map<String, dynamic> j) => SharedUser(
        userId: j['userId'] ?? '',
        email: j['email'] ?? '',
        permission: j['permission'] ?? 1,
        sharedAt: j['sharedAt'] ?? '',
      );
}

class Folder {
  final String id;
  final String name;
  final bool isShared;
  final String? parentId;
  final List<SharedUser> sharedWith;

  Folder({
    required this.id,
    required this.name,
    required this.isShared,
    this.parentId,
    this.sharedWith = const [],
  });

  factory Folder.fromJson(Map<String, dynamic> j) => Folder(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        isShared: j['isShared'] ?? false,
        parentId: j['parentId'],
        sharedWith: (j['sharedWith'] as List<dynamic>? ?? [])
            .map((e) => SharedUser.fromJson(e))
            .toList(),
      );

  Folder copyWith({String? id, String? name, bool? isShared, String? parentId}) => Folder(
        id: id ?? this.id,
        name: name ?? this.name,
        isShared: isShared ?? this.isShared,
        parentId: parentId ?? this.parentId,
        sharedWith: sharedWith,
      );
}

class FolderTree {
  final String id;
  final String? parentId;
  final String name;
  final bool isShared;
  final List<FolderTree> children;

  FolderTree({
    required this.id,
    this.parentId,
    required this.name,
    required this.isShared,
    required this.children,
  });

  factory FolderTree.fromJson(Map<String, dynamic> j) => FolderTree(
        id: j['id'] ?? '',
        parentId: j['parentId'],
        name: j['name'] ?? '',
        isShared: j['isShared'] ?? false,
        children: (j['children'] as List<dynamic>? ?? [])
            .map((e) => FolderTree.fromJson(e))
            .toList(),
      );
}
