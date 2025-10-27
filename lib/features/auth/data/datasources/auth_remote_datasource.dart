import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  });

  Future<void> logout();

  Future<UserModel> getCurrentUser();

  Future<String> getAccessToken();

  Future<void> updateFCMToken(String fcmToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  AuthRemoteDataSourceImpl({
    required this.dioClient,
    required this.secureStorage,
    required this.sharedPreferences,
  });

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save tokens
        await secureStorage.write(
          key: AppConstants.tokenKey,
          value: data['access_token'],
        );

        if (data['refresh_token'] != null) {
          await secureStorage.write(
            key: AppConstants.refreshTokenKey,
            value: data['refresh_token'],
          );
        }

        // Save user data
        final user = UserModel.fromJson(data['user']);
        await sharedPreferences.setString(
          AppConstants.userKey,
          data['user'].toString(),
        );
        await sharedPreferences.setBool(AppConstants.isLoggedInKey, true);

        return user;
      } else {
        throw ServerException(
          message: 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is AuthenticationException) {
        rethrow;
      }
      throw ServerException(message: 'Login failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;

        // Save tokens
        await secureStorage.write(
          key: AppConstants.tokenKey,
          value: data['access_token'],
        );

        if (data['refresh_token'] != null) {
          await secureStorage.write(
            key: AppConstants.refreshTokenKey,
            value: data['refresh_token'],
          );
        }

        // Save user data
        final user = UserModel.fromJson(data['user']);
        await sharedPreferences.setString(
          AppConstants.userKey,
          data['user'].toString(),
        );
        await sharedPreferences.setBool(AppConstants.isLoggedInKey, true);

        return user;
      } else {
        throw ServerException(
          message: 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is ValidationException) {
        rethrow;
      }
      throw ServerException(message: 'Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Call logout API (optional - depending on your backend)
      try {
        await dioClient.post(ApiConstants.logout);
      } catch (e) {
        // Ignore API errors during logout
      }

      // Clear local data
      await secureStorage.delete(key: AppConstants.tokenKey);
      await secureStorage.delete(key: AppConstants.refreshTokenKey);
      await sharedPreferences.remove(AppConstants.userKey);
      await sharedPreferences.setBool(AppConstants.isLoggedInKey, false);
    } catch (e) {
      throw CacheException(message: 'Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.get(ApiConstants.updateProfile);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data['user']);

        // Update cached user data
        await sharedPreferences.setString(
          AppConstants.userKey,
          response.data['user'].toString(),
        );

        return user;
      } else {
        throw ServerException(
          message: 'Failed to get user',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is AuthenticationException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<String> getAccessToken() async {
    try {
      final token = await secureStorage.read(key: AppConstants.tokenKey);
      if (token == null) {
        throw AuthenticationException(message: 'No access token found');
      }
      return token;
    } catch (e) {
      throw CacheException(message: 'Failed to get access token');
    }
  }

  @override
  Future<void> updateFCMToken(String fcmToken) async {
    try {
      final response = await dioClient.post(
        ApiConstants.updateFCMToken,
        data: {
          'fcm_token': fcmToken,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Failed to update FCM token',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to update FCM token: ${e.toString()}');
    }
  }
}
