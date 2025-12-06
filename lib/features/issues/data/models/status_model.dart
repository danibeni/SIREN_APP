import 'package:siren_app/features/issues/domain/entities/status_entity.dart';

class StatusModel {
  final int id;
  final String name;
  final bool isDefault;
  final bool isClosed;
  final String? href;
  final String? colorHex;

  const StatusModel({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.isClosed,
    this.href,
    this.colorHex,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    final rawColor = json['color'];
    String? colorHex;
    if (rawColor is String) {
      colorHex = rawColor;
    } else if (rawColor is Map<String, dynamic>) {
      colorHex =
          rawColor['hexcode'] as String? ??
          rawColor['hexCode'] as String? ??
          rawColor['hex_code'] as String?;
    }

    return StatusModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      isClosed: json['isClosed'] as bool? ?? false,
      href: json['_links']?['self']?['href'] as String?,
      colorHex: colorHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isDefault': isDefault,
      'isClosed': isClosed,
      'color': colorHex,
      '_links': {
        'self': {'href': href},
      },
    };
  }

  StatusEntity toEntity() {
    return StatusEntity(
      id: id,
      name: name,
      isDefault: isDefault,
      isClosed: isClosed,
      href: href,
      colorHex: colorHex,
    );
  }
}
