import 'package:equatable/equatable.dart';

class UserListEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserListEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phoneNumber,
        avatar,
        isOnline,
        lastSeen,
      ];
}
