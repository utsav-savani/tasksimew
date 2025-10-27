import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/network/dio_client.dart';
import 'core/utils/logger_service.dart';
import 'core/constants/app_constants.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';

// Auth
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// Users
import 'features/users/data/models/user_list_model.dart';
import 'features/users/data/datasources/users_local_datasource.dart';
import 'features/users/data/datasources/users_remote_datasource.dart';
import 'features/users/data/datasources/users_mock_datasource.dart';
import 'features/users/data/repositories/users_repository_impl.dart';
import 'features/users/data/repositories/users_repository_test_impl.dart';
import 'features/users/domain/repositories/users_repository.dart';
import 'features/users/presentation/providers/users_provider.dart';

// Video Call
import 'features/video_call/data/datasources/agora_service.dart';
import 'features/video_call/data/datasources/video_call_remote_datasource.dart';
import 'features/video_call/data/repositories/video_call_repository_impl.dart';
import 'features/video_call/data/repositories/video_call_repository_test_impl.dart';
import 'features/video_call/domain/repositories/video_call_repository.dart';
import 'features/video_call/presentation/providers/video_call_provider.dart';

import 'app.dart';

// Background message handler for Firebase (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LoggerService.i('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  final firebaseService = FirebaseService();
  try {
    await firebaseService.initialize();

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    LoggerService.i('✅ Firebase initialized successfully');
  } catch (e) {
    LoggerService.w('⚠️ Firebase initialization failed (optional feature): $e');
  }

  // Initialize notification service
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    LoggerService.i('✅ Notification service initialized');
  } catch (e) {
    LoggerService.w('⚠️ Notification service initialization failed: $e');
  }

  // Setup message handlers
  firebaseService.setupMessageHandlers(
    onMessageReceived: (message) {
      LoggerService.i('Foreground message: ${message.notification?.title}');
      notificationService.showNotificationFromMessage(message);
    },
    onMessageOpened: (message) {
      LoggerService.i('Message opened: ${message.data}');
      // Handle navigation based on message data
    },
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserListModelAdapter());

  // Open Hive boxes
  final usersBox = await Hive.openBox<UserListModel>(AppConstants.usersBox);

  // Initialize dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final logger = LoggerService.instance;
  final connectivity = Connectivity();

  // Initialize Dio Client
  final dioClient = DioClient(
    secureStorage: secureStorage,
    logger: logger,
  );

  // Initialize Auth
  final authRemoteDataSource = AuthRemoteDataSourceImpl(
    dioClient: dioClient,
    secureStorage: secureStorage,
    sharedPreferences: sharedPreferences,
  );

  final authLocalDataSource = AuthLocalDataSourceImpl(
    secureStorage: secureStorage,
    sharedPreferences: sharedPreferences,
  );

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
  );

  // Check if in test mode
  final testMode = dotenv.env['TEST_MODE'] == 'true';

  // Initialize Users
  late final UsersRepository usersRepository;

  if (testMode) {
    // Test mode: Use mock data
    final usersMockDataSource = UsersMockDataSource();
    usersRepository = UsersRepositoryTestImpl(
      mockDataSource: usersMockDataSource,
    );
    logger.i('🧪 TEST MODE: Using mock users data');
  } else {
    // Production mode: Use real API
    final usersRemoteDataSource = UsersRemoteDataSourceImpl(
      dioClient: dioClient,
    );
    final usersLocalDataSource = UsersLocalDataSourceImpl(
      usersBox: usersBox,
    );
    usersRepository = UsersRepositoryImpl(
      remoteDataSource: usersRemoteDataSource,
      localDataSource: usersLocalDataSource,
      connectivity: connectivity,
    );
  }

  // Initialize Video Call
  late final VideoCallRepository videoCallRepository;

  if (testMode) {
    // Test mode: Use mock token generation
    videoCallRepository = VideoCallRepositoryTestImpl();
    logger.i('🧪 TEST MODE: Using mock video call repository');
  } else {
    // Production mode: Use real API
    final videoCallRemoteDataSource = VideoCallRemoteDataSourceImpl(
      dioClient: dioClient,
    );
    videoCallRepository = VideoCallRepositoryImpl(
      remoteDataSource: videoCallRemoteDataSource,
    );
  }

  final agoraService = AgoraService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(usersRepository: usersRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => VideoCallProvider(
            videoCallRepository: videoCallRepository,
            agoraService: agoraService,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
