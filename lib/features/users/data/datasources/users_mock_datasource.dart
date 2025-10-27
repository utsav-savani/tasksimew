import '../../../../core/constants/mock_data.dart';
import '../models/user_list_model.dart';

class UsersMockDataSource {
  // Get mock users
  Future<List<UserListModel>> getUsers({int page = 1, int limit = 20}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Convert entities to models
    return MockData.mockUsers
        .map((entity) => UserListModel(
              id: entity.id,
              name: entity.name,
              email: entity.email,
              phoneNumber: entity.phoneNumber,
              avatar: entity.avatar,
              isOnline: entity.isOnline,
              lastSeen: entity.lastSeen,
            ))
        .toList();
  }

  // Get user by ID
  Future<UserListModel> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final user = MockData.mockUsers.firstWhere(
      (u) => u.id == id,
      orElse: () => MockData.mockUsers.first,
    );

    return UserListModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phoneNumber: user.phoneNumber,
      avatar: user.avatar,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
    );
  }

  // Search users
  Future<List<UserListModel>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final filteredUsers = MockData.mockUsers.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return filteredUsers
        .map((entity) => UserListModel(
              id: entity.id,
              name: entity.name,
              email: entity.email,
              phoneNumber: entity.phoneNumber,
              avatar: entity.avatar,
              isOnline: entity.isOnline,
              lastSeen: entity.lastSeen,
            ))
        .toList();
  }
}
