import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../core/services/firebase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // Initialize auth state
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await _authRepository.isLoggedIn();

    result.fold(
      (failure) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      },
      (isLoggedIn) async {
        if (isLoggedIn) {
          await _getCurrentUser();
        } else {
          _status = AuthStatus.unauthenticated;
          _user = null;
          notifyListeners();
        }
      },
    );
  }

  // Get current user
  Future<void> _getCurrentUser() async {
    final result = await _authRepository.getCurrentUser();

    result.fold(
      (failure) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (user) {
        _status = AuthStatus.authenticated;
        _user = user;
        _errorMessage = null;
        notifyListeners();
      },
    );
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    return result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        LoggerService.e('Login failed: ${failure.message}');
        notifyListeners();
        return false;
      },
      (user) async {
        _status = AuthStatus.authenticated;
        _user = user;
        _errorMessage = null;
        LoggerService.i('Login successful: ${user.email}');

        // Update FCM token after successful login
        await _updateFCMToken();

        notifyListeners();
        return true;
      },
    );
  }

  // Update FCM token to backend
  Future<void> _updateFCMToken() async {
    try {
      final firebaseService = FirebaseService();
      final fcmToken = await firebaseService.getToken();

      if (fcmToken != null) {
        LoggerService.i('Updating FCM token to backend...');
        final result = await _authRepository.updateFCMToken(fcmToken);

        result.fold(
          (failure) {
            LoggerService.w('Failed to update FCM token: ${failure.message}');
          },
          (_) {
            LoggerService.i('FCM token updated successfully');
          },
        );
      }
    } catch (e) {
      LoggerService.w('FCM token update error (non-critical): $e');
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.register(
      name: name,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
    );

    return result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        LoggerService.e('Registration failed: ${failure.message}');
        notifyListeners();
        return false;
      },
      (user) async {
        _status = AuthStatus.authenticated;
        _user = user;
        _errorMessage = null;
        LoggerService.i('Registration successful: ${user.email}');

        // Update FCM token after successful registration
        await _updateFCMToken();

        notifyListeners();
        return true;
      },
    );
  }

  // Logout
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await _authRepository.logout();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        LoggerService.e('Logout failed: ${failure.message}');
        // Still log out locally
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      },
      (_) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        _errorMessage = null;
        LoggerService.i('Logout successful');
        notifyListeners();
      },
    );
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
