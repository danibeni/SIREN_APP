import 'package:equatable/equatable.dart';

/// Domain entity representing a Work Package Type.
class WorkPackageTypeEntity extends Equatable {
  final int id;
  final String name;
  final String? href;

  const WorkPackageTypeEntity({
    required this.id,
    required this.name,
    this.href,
  });

  @override
  List<Object?> get props => [id, name, href];
}
