import 'package:equatable/equatable.dart';

enum CallStatus { initiated, ringing, connected, ended, failed }

class CallEntity extends Equatable {
  final String callId;
  final String channelName;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;

  const CallEntity({
    required this.callId,
    required this.channelName,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
  });

  @override
  List<Object?> get props => [
        callId,
        channelName,
        callerId,
        callerName,
        callerAvatar,
        receiverId,
        receiverName,
        receiverAvatar,
        status,
        startTime,
        endTime,
        duration,
      ];
}
