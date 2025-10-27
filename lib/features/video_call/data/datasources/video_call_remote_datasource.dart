import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/call_model.dart';

abstract class VideoCallRemoteDataSource {
  Future<String> generateAgoraToken({
    required String channelName,
    required String userId,
  });

  Future<CallModel> initiateCall({
    required String receiverId,
    required String channelName,
  });

  Future<void> endCall({
    required String callId,
    required int duration,
  });

  Future<List<CallModel>> getCallHistory();
}

class VideoCallRemoteDataSourceImpl implements VideoCallRemoteDataSource {
  final DioClient dioClient;

  VideoCallRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<String> generateAgoraToken({
    required String channelName,
    required String userId,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.generateToken,
        data: {
          'channel_name': channelName,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        return response.data['token'] ?? '';
      } else {
        throw ServerException(
          message: 'Failed to generate token',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to generate token: ${e.toString()}');
    }
  }

  @override
  Future<CallModel> initiateCall({
    required String receiverId,
    required String channelName,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.initiateCall,
        data: {
          'receiver_id': receiverId,
          'channel_name': channelName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CallModel.fromJson(response.data['call'] ?? response.data);
      } else {
        throw ServerException(
          message: 'Failed to initiate call',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to initiate call: ${e.toString()}');
    }
  }

  @override
  Future<void> endCall({
    required String callId,
    required int duration,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.endCall,
        data: {
          'call_id': callId,
          'duration': duration,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to end call',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to end call: ${e.toString()}');
    }
  }

  @override
  Future<List<CallModel>> getCallHistory() async {
    try {
      final response = await dioClient.get(ApiConstants.callHistory);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['calls'] ?? response.data;
        return data.map((json) => CallModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to get call history',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to get call history: ${e.toString()}');
    }
  }
}
