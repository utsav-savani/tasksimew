import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_list_model.dart';

abstract class UsersRemoteDataSource {
  Future<List<UserListModel>> getUsers({int page = 1, int limit = 20});
  Future<UserListModel> getUserById(String id);
  Future<List<UserListModel>> searchUsers(String query);
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final DioClient dioClient;

  UsersRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<UserListModel>> getUsers({int page = 1, int limit = 20}) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getUsers,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'] ?? response.data;
        return data.map((json) => UserListModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to get users',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to get users: ${e.toString()}');
    }
  }

  @override
  Future<UserListModel> getUserById(String id) async {
    try {
      final response = await dioClient.get('${ApiConstants.getUserById}$id');

      if (response.statusCode == 200) {
        return UserListModel.fromJson(response.data['user'] ?? response.data);
      } else {
        throw ServerException(
          message: 'Failed to get user',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<List<UserListModel>> searchUsers(String query) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getUsers,
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'] ?? response.data;
        return data.map((json) => UserListModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to search users',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to search users: ${e.toString()}');
    }
  }
}
