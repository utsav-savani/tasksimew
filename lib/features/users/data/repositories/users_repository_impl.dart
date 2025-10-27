import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_list_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_local_datasource.dart';
import '../datasources/users_remote_datasource.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;
  final UsersLocalDataSource localDataSource;
  final Connectivity connectivity;

  UsersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivity,
  });

  @override
  Future<Either<Failure, List<UserListEntity>>> getUsers({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Check connectivity
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        // No internet, return cached data
        final cachedUsers = await localDataSource.getCachedUsers();
        if (cachedUsers.isEmpty) {
          return const Left(NetworkFailure(
            message: 'No internet connection and no cached data available',
          ));
        }
        return Right(cachedUsers);
      }

      // Fetch from remote
      final users = await remoteDataSource.getUsers(page: page, limit: limit);

      // Cache the users
      await localDataSource.cacheUsers(users);

      return Right(users);
    } on ServerException catch (e) {
      // Try to return cached data on server error
      try {
        final cachedUsers = await localDataSource.getCachedUsers();
        if (cachedUsers.isNotEmpty) {
          return Right(cachedUsers);
        }
      } catch (_) {}

      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      // Return cached data on network error
      try {
        final cachedUsers = await localDataSource.getCachedUsers();
        if (cachedUsers.isNotEmpty) {
          return Right(cachedUsers);
        }
      } catch (_) {}

      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserListEntity>> getUserById(String id) async {
    try {
      // Try to get from cache first
      final cachedUser = await localDataSource.getCachedUserById(id);

      // Check connectivity
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        // No internet, return cached data if available
        if (cachedUser != null) {
          return Right(cachedUser);
        }
        return const Left(NetworkFailure(
          message: 'No internet connection and user not found in cache',
        ));
      }

      // Fetch from remote
      final user = await remoteDataSource.getUserById(id);

      return Right(user);
    } on ServerException catch (e) {
      // Try to return cached data on server error
      try {
        final cachedUser = await localDataSource.getCachedUserById(id);
        if (cachedUser != null) {
          return Right(cachedUser);
        }
      } catch (_) {}

      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      // Return cached data on network error
      try {
        final cachedUser = await localDataSource.getCachedUserById(id);
        if (cachedUser != null) {
          return Right(cachedUser);
        }
      } catch (_) {}

      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get user'));
    }
  }

  @override
  Future<Either<Failure, List<UserListEntity>>> searchUsers(String query) async {
    try {
      final users = await remoteDataSource.searchUsers(query);
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to search users'));
    }
  }

  @override
  Future<Either<Failure, List<UserListEntity>>> getCachedUsers() async {
    try {
      final users = await localDataSource.getCachedUsers();
      return Right(users);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get cached users'));
    }
  }

  @override
  Future<Either<Failure, void>> syncUsers() async {
    try {
      final users = await remoteDataSource.getUsers();
      await localDataSource.cacheUsers(users);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to sync users'));
    }
  }
}
