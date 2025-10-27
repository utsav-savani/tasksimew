import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<bool> isLoggedIn();
  Future<void> saveLoginStatus(bool status);
  Future<String?> getAccessToken();
  Future<void> clearAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({
    required this.secureStorage,
    required this.sharedPreferences,
  });

  @override
  Future<bool> isLoggedIn() async {
    try {
      return sharedPreferences.getBool(AppConstants.isLoggedInKey) ?? false;
    } catch (e) {
      throw CacheException(message: 'Failed to check login status');
    }
  }

  @override
  Future<void> saveLoginStatus(bool status) async {
    try {
      await sharedPreferences.setBool(AppConstants.isLoggedInKey, status);
    } catch (e) {
      throw CacheException(message: 'Failed to save login status');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await secureStorage.read(key: AppConstants.tokenKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get access token');
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await secureStorage.delete(key: AppConstants.tokenKey);
      await secureStorage.delete(key: AppConstants.refreshTokenKey);
      await sharedPreferences.remove(AppConstants.userKey);
      await sharedPreferences.setBool(AppConstants.isLoggedInKey, false);
    } catch (e) {
      throw CacheException(message: 'Failed to clear auth data');
    }
  }
}
