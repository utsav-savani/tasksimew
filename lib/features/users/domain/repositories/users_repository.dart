import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_list_entity.dart';

abstract class UsersRepository {
  Future<Either<Failure, List<UserListEntity>>> getUsers({
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, UserListEntity>> getUserById(String id);

  Future<Either<Failure, List<UserListEntity>>> searchUsers(String query);

  Future<Either<Failure, List<UserListEntity>>> getCachedUsers();

  Future<Either<Failure, void>> syncUsers();
}
