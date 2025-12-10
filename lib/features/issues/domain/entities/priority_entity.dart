import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

/// Domain entity representing an OpenProject priority.
class PriorityEntity extends Equatable {
  final int id;
  final String name;
  final String? href;
  final String? colorHex;
  final PriorityLevel priorityLevel;

  const PriorityEntity({
    required this.id,
    required this.name,
    this.href,
    this.colorHex,
    required this.priorityLevel,
  });

  @override
  List<Object?> get props => [id, name, href, colorHex, priorityLevel];
}
