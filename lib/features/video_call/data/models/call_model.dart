import '../../domain/entities/call_entity.dart';

class CallModel extends CallEntity {
  const CallModel({
    required super.callId,
    required super.channelName,
    required super.callerId,
    required super.callerName,
    super.callerAvatar,
    required super.receiverId,
    required super.receiverName,
    super.receiverAvatar,
    required super.status,
    required super.startTime,
    super.endTime,
    super.duration,
  });

  // From JSON
  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      callId: json['call_id']?.toString() ?? '',
      channelName: json['channel_name'] ?? '',
      callerId: json['caller_id']?.toString() ?? '',
      callerName: json['caller_name'] ?? '',
      callerAvatar: json['caller_avatar'],
      receiverId: json['receiver_id']?.toString() ?? '',
      receiverName: json['receiver_name'] ?? '',
      receiverAvatar: json['receiver_avatar'],
      status: _parseStatus(json['status']),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      duration: json['duration'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'channel_name': channelName,
      'caller_id': callerId,
      'caller_name': callerName,
      'caller_avatar': callerAvatar,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'receiver_avatar': receiverAvatar,
      'status': _statusToString(status),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration': duration,
    };
  }

  static CallStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'initiated':
        return CallStatus.initiated;
      case 'ringing':
        return CallStatus.ringing;
      case 'connected':
        return CallStatus.connected;
      case 'ended':
        return CallStatus.ended;
      case 'failed':
        return CallStatus.failed;
      default:
        return CallStatus.initiated;
    }
  }

  static String _statusToString(CallStatus status) {
    switch (status) {
      case CallStatus.initiated:
        return 'initiated';
      case CallStatus.ringing:
        return 'ringing';
      case CallStatus.connected:
        return 'connected';
      case CallStatus.ended:
        return 'ended';
      case CallStatus.failed:
        return 'failed';
    }
  }

  // From Entity
  factory CallModel.fromEntity(CallEntity entity) {
    return CallModel(
      callId: entity.callId,
      channelName: entity.channelName,
      callerId: entity.callerId,
      callerName: entity.callerName,
      callerAvatar: entity.callerAvatar,
      receiverId: entity.receiverId,
      receiverName: entity.receiverName,
      receiverAvatar: entity.receiverAvatar,
      status: entity.status,
      startTime: entity.startTime,
      endTime: entity.endTime,
      duration: entity.duration,
    );
  }
}
