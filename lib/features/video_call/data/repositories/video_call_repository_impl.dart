import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/repositories/video_call_repository.dart';
import '../datasources/video_call_remote_datasource.dart';

class VideoCallRepositoryImpl implements VideoCallRepository {
  final VideoCallRemoteDataSource remoteDataSource;

  VideoCallRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> generateAgoraToken({
    required String channelName,
    required String userId,
  }) async {
    try {
      final token = await remoteDataSource.generateAgoraToken(
        channelName: channelName,
        userId: userId,
      );
      return Right(token);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to generate token'));
    }
  }

  @override
  Future<Either<Failure, CallEntity>> initiateCall({
    required String receiverId,
    required String channelName,
  }) async {
    try {
      final call = await remoteDataSource.initiateCall(
        receiverId: receiverId,
        channelName: channelName,
      );
      return Right(call);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to initiate call'));
    }
  }

  @override
  Future<Either<Failure, void>> endCall({
    required String callId,
    required int duration,
  }) async {
    try {
      await remoteDataSource.endCall(
        callId: callId,
        duration: duration,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to end call'));
    }
  }

  @override
  Future<Either<Failure, List<CallEntity>>> getCallHistory() async {
    try {
      final calls = await remoteDataSource.getCallHistory();
      return Right(calls);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get call history'));
    }
  }
}
