class Project {
  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.template,
    required this.path,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String template;

  /// Absolute path of the project folder on disk.
  final String path;

  Project copyWith({String? name, DateTime? modifiedAt}) => Project(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        template: template,
        path: path,
      );

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.name == name &&
      other.modifiedAt == modifiedAt &&
      other.path == path;

  @override
  int get hashCode => Object.hash(id, name, modifiedAt, path);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'template': template,
      };

  factory Project.fromJson(Map<String, dynamic> json, String path) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
        template: (json['template'] as String?) ?? 'blank',
        path: path,
      );
}
