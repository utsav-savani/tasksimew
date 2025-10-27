import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatar,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phoneNumber,
        avatar,
        createdAt,
        updatedAt,
      ];
}
