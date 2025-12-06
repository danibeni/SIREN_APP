import 'package:siren_app/features/issues/domain/entities/work_package_type_entity.dart';

class WorkPackageTypeModel {
  final int id;
  final String name;
  final String? href;

  const WorkPackageTypeModel({required this.id, required this.name, this.href});

  factory WorkPackageTypeModel.fromJson(Map<String, dynamic> json) {
    return WorkPackageTypeModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      href: json['_links']?['self']?['href'] as String?,
    );
  }

  WorkPackageTypeEntity toEntity() {
    return WorkPackageTypeEntity(id: id, name: name, href: href);
  }
}
