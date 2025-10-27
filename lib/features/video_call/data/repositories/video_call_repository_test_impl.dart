import 'package:dartz/dartz.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger_service.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/repositories/video_call_repository.dart';

/// Test implementation of VideoCallRepository that uses mock data
class VideoCallRepositoryTestImpl implements VideoCallRepository {
  @override
  Future<Either<Failure, String>> generateAgoraToken({
    required String channelName,
    required String userId,
  }) async {
    // In test mode with Agora testing mode enabled, we can use empty token
    LoggerService.i('[TEST MODE] Generating mock Agora token for channel: $channelName');
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(MockData.mockAgoraToken);
  }

  @override
  Future<Either<Failure, CallEntity>> initiateCall({
    required String receiverId,
    required String channelName,
  }) async {
    LoggerService.i('[TEST MODE] Initiating mock call to user: $receiverId');
    await Future.delayed(const Duration(milliseconds: 500));

    final call = CallEntity(
      callId: 'test_call_${DateTime.now().millisecondsSinceEpoch}',
      channelName: channelName,
      callerId: MockData.currentUserId,
      callerName: MockData.currentUserName,
      receiverId: receiverId,
      receiverName: 'Test Receiver',
      status: CallStatus.initiated,
      startTime: DateTime.now(),
    );

    return Right(call);
  }

  @override
  Future<Either<Failure, void>> endCall({
    required String callId,
    required int duration,
  }) async {
    LoggerService.i('[TEST MODE] Ending mock call. Duration: $duration seconds');
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<CallEntity>>> getCallHistory() async {
    LoggerService.i('[TEST MODE] Loading mock call history');
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right([]);
  }
}
