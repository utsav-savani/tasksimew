import 'package:hive/hive.dart';
import '../../domain/entities/user_list_entity.dart';

part 'user_list_model.g.dart';

@HiveType(typeId: 0)
class UserListModel extends UserListEntity {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final String name;

  @override
  @HiveField(2)
  final String email;

  @override
  @HiveField(3)
  final String? phoneNumber;

  @override
  @HiveField(4)
  final String? avatar;

  @override
  @HiveField(5)
  final bool isOnline;

  @override
  @HiveField(6)
  final DateTime? lastSeen;

  const UserListModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  }) : super(
          id: id,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          avatar: avatar,
          isOnline: isOnline,
          lastSeen: lastSeen,
        );

  // From JSON
  factory UserListModel.fromJson(Map<String, dynamic> json) {
    return UserListModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      avatar: json['avatar'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  // From Entity
  factory UserListModel.fromEntity(UserListEntity entity) {
    return UserListModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      avatar: entity.avatar,
      isOnline: entity.isOnline,
      lastSeen: entity.lastSeen,
    );
  }

  // Copy With
  UserListModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? avatar,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
