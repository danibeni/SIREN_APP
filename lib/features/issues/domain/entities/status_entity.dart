import 'package:equatable/equatable.dart';

/// Domain entity representing an OpenProject status.
class StatusEntity extends Equatable {
  final int id;
  final String name;
  final bool isDefault;
  final bool isClosed;
  final String? href;
  final String? colorHex;

  const StatusEntity({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.isClosed,
    this.href,
    this.colorHex,
  });

  @override
  List<Object?> get props => [id, name, isDefault, isClosed, href, colorHex];
}
