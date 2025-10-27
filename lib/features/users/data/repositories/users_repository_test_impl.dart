import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger_service.dart';
import '../../domain/entities/user_list_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_mock_datasource.dart';

/// Test implementation of UsersRepository that uses mock data
class UsersRepositoryTestImpl implements UsersRepository {
  final UsersMockDataSource mockDataSource;

  UsersRepositoryTestImpl({required this.mockDataSource});

  @override
  Future<Either<Failure, List<UserListEntity>>> getUsers({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final users = await mockDataSource.getUsers(page: page, limit: limit);
      LoggerService.i('[TEST MODE] Loaded ${users.length} mock users');
      return Right(users);
    } catch (e) {
      LoggerService.e('[TEST MODE] Failed to load mock users', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserListEntity>> getUserById(String id) async {
    try {
      final user = await mockDataSource.getUserById(id);
      LoggerService.i('[TEST MODE] Loaded mock user: ${user.name}');
      return Right(user);
    } catch (e) {
      LoggerService.e('[TEST MODE] Failed to load mock user', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserListEntity>>> searchUsers(String query) async {
    try {
      final users = await mockDataSource.searchUsers(query);
      LoggerService.i('[TEST MODE] Found ${users.length} mock users for query: $query');
      return Right(users);
    } catch (e) {
      LoggerService.e('[TEST MODE] Failed to search mock users', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserListEntity>>> getCachedUsers() async {
    try {
      final users = await mockDataSource.getUsers();
      return Right(users);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncUsers() async {
    // In test mode, no sync needed
    LoggerService.i('[TEST MODE] Sync not needed in test mode');
    return const Right(null);
  }
}
