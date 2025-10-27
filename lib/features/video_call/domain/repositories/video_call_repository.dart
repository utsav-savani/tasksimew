import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/call_entity.dart';

abstract class VideoCallRepository {
  Future<Either<Failure, String>> generateAgoraToken({
    required String channelName,
    required String userId,
  });

  Future<Either<Failure, CallEntity>> initiateCall({
    required String receiverId,
    required String channelName,
  });

  Future<Either<Failure, void>> endCall({
    required String callId,
    required int duration,
  });

  Future<Either<Failure, List<CallEntity>>> getCallHistory();
}
