import '../../features/users/domain/entities/user_list_entity.dart';

class MockData {
  // Test mode flag
  static const bool testMode = bool.fromEnvironment(
    'TEST_MODE',
    defaultValue: true,
  );

  // Mock current user
  static const String currentUserId = '123';
  static const String currentUserName = 'Test User (You)';
  static const String currentUserEmail = 'testuser@example.com';

  // Mock users list for testing
  static final List<UserListEntity> mockUsers = [
    UserListEntity(
      id: '1',
      name: 'Alice Johnson',
      email: 'alice@example.com',
      phoneNumber: '+1 234 567 8901',
      avatar: null,
      isOnline: true,
      lastSeen: null,
    ),
    UserListEntity(
      id: '2',
      name: 'Bob Smith',
      email: 'bob@example.com',
      phoneNumber: '+1 234 567 8902',
      avatar: null,
      isOnline: true,
      lastSeen: null,
    ),
    UserListEntity(
      id: '3',
      name: 'Carol Williams',
      email: 'carol@example.com',
      phoneNumber: '+1 234 567 8903',
      avatar: null,
      isOnline: false,
      lastSeen: DateTime(2024, 10, 25, 14, 30),
    ),
    UserListEntity(
      id: '4',
      name: 'David Brown',
      email: 'david@example.com',
      phoneNumber: '+1 234 567 8904',
      avatar: null,
      isOnline: true,
      lastSeen: null,
    ),
    UserListEntity(
      id: '5',
      name: 'Emma Davis',
      email: 'emma@example.com',
      phoneNumber: '+1 234 567 8905',
      avatar: null,
      isOnline: false,
      lastSeen: DateTime(2024, 10, 24, 18, 45),
    ),
  ];

  // Mock Agora token (empty for testing mode in Agora)
  static const String mockAgoraToken = '';

  // Generate a test channel name
  static String generateChannelName(String receiverId) {
    return 'channel_${currentUserId}_${receiverId}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
