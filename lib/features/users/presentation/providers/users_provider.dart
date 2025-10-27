import 'package:flutter/foundation.dart';
import '../../../../core/utils/logger_service.dart';
import '../../domain/entities/user_list_entity.dart';
import '../../domain/repositories/users_repository.dart';

enum UsersStatus { initial, loading, loaded, error, refreshing }

class UsersProvider extends ChangeNotifier {
  final UsersRepository _usersRepository;

  UsersProvider({required UsersRepository usersRepository})
      : _usersRepository = usersRepository;

  UsersStatus _status = UsersStatus.initial;
  List<UserListEntity> _users = [];
  List<UserListEntity> _filteredUsers = [];
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';

  UsersStatus get status => _status;
  List<UserListEntity> get users => _filteredUsers.isEmpty && _searchQuery.isEmpty
      ? _users
      : _filteredUsers;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == UsersStatus.loading;
  bool get isRefreshing => _status == UsersStatus.refreshing;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;

  // Load users
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      _status = UsersStatus.refreshing;
      _currentPage = 1;
      _hasMore = true;
    } else {
      _status = UsersStatus.loading;
    }
    _errorMessage = null;
    notifyListeners();

    final result = await _usersRepository.getUsers(page: _currentPage);

    result.fold(
      (failure) {
        _status = UsersStatus.error;
        _errorMessage = failure.message;
        LoggerService.e('Failed to load users: ${failure.message}');
        notifyListeners();
      },
      (usersList) {
        if (refresh) {
          _users = usersList;
        } else {
          _users.addAll(usersList);
        }

        if (usersList.isEmpty || usersList.length < 20) {
          _hasMore = false;
        }

        _status = UsersStatus.loaded;
        _errorMessage = null;
        LoggerService.i('Loaded ${usersList.length} users');
        notifyListeners();
      },
    );
  }

  // Load more users (pagination)
  Future<void> loadMoreUsers() async {
    if (!_hasMore || _status == UsersStatus.loading) return;

    _currentPage++;
    await loadUsers();
  }

  // Refresh users
  Future<void> refreshUsers() async {
    await loadUsers(refresh: true);
  }

  // Search users
  Future<void> searchUsers(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredUsers = [];
      notifyListeners();
      return;
    }

    // First, filter from local cache
    _filteredUsers = _users.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase());
    }).toList();

    notifyListeners();

    // Then, search from remote
    _status = UsersStatus.loading;
    notifyListeners();

    final result = await _usersRepository.searchUsers(query);

    result.fold(
      (failure) {
        _status = UsersStatus.error;
        _errorMessage = failure.message;
        LoggerService.e('Failed to search users: ${failure.message}');
        notifyListeners();
      },
      (usersList) {
        _filteredUsers = usersList;
        _status = UsersStatus.loaded;
        _errorMessage = null;
        LoggerService.i('Found ${usersList.length} users for query: $query');
        notifyListeners();
      },
    );
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredUsers = [];
    notifyListeners();
  }

  // Get cached users (for offline mode)
  Future<void> loadCachedUsers() async {
    _status = UsersStatus.loading;
    notifyListeners();

    final result = await _usersRepository.getCachedUsers();

    result.fold(
      (failure) {
        _status = UsersStatus.error;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (usersList) {
        _users = usersList;
        _status = UsersStatus.loaded;
        _errorMessage = null;
        notifyListeners();
      },
    );
  }

  // Sync users
  Future<void> syncUsers() async {
    final result = await _usersRepository.syncUsers();

    result.fold(
      (failure) {
        LoggerService.e('Failed to sync users: ${failure.message}');
      },
      (_) {
        LoggerService.i('Users synced successfully');
        loadUsers(refresh: true);
      },
    );
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == UsersStatus.error) {
      _status = UsersStatus.initial;
    }
    notifyListeners();
  }
}
