import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_list_model.dart';

abstract class UsersLocalDataSource {
  Future<List<UserListModel>> getCachedUsers();
  Future<void> cacheUsers(List<UserListModel> users);
  Future<UserListModel?> getCachedUserById(String id);
  Future<void> clearCache();
}

class UsersLocalDataSourceImpl implements UsersLocalDataSource {
  final Box<UserListModel> usersBox;

  UsersLocalDataSourceImpl({required this.usersBox});

  @override
  Future<List<UserListModel>> getCachedUsers() async {
    try {
      return usersBox.values.toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached users: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheUsers(List<UserListModel> users) async {
    try {
      await usersBox.clear();
      for (var user in users) {
        await usersBox.put(user.id, user);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to cache users: ${e.toString()}');
    }
  }

  @override
  Future<UserListModel?> getCachedUserById(String id) async {
    try {
      return usersBox.get(id);
    } catch (e) {
      throw CacheException(message: 'Failed to get cached user: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await usersBox.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear cache: ${e.toString()}');
    }
  }
}
