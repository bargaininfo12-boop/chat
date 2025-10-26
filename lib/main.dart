// lib/main.dart
// v1.3-main · Updated ChatService initialization
// - Uses ChatService.instance.init() with all required dependencies
// - Proper MessageRepository initialization
// - Defensive try/catch + helpful debug logs

import 'dart:async';
import 'dart:io';

import 'package:bargain/Database/Firebase_all/app_auth_provider.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/Database/database_helper.dart';
import 'package:bargain/Services/user_service.dart';
import 'package:bargain/account_setting/AppearanceSettingsPage.dart';
import 'package:bargain/account_setting/langauge/language_notifier.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/chat/services/notification_service.dart';
import 'package:bargain/chat/services/userpresence.dart';
import 'package:bargain/chat/repository/message_repository.dart';
import 'package:bargain/chat/screens/chat_screen/chat_bloc.dart';
import 'package:bargain/chat/utils/network_manager.dart';
import 'package:bargain/homesceen/home_page.dart';
import 'package:bargain/login/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Project-specific services (canonical paths)
import 'package:bargain/chat/services/ws_client.dart';
import 'package:bargain/chat/services/cdn_uploader.dart';
import 'package:bargain/chat/services/chat_service.dart';
import 'package:bargain/chat/services/ws_message_handler.dart';
import 'package:bargain/chat/services/ws_ack_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bargain/chat/services/chat_database_helper.dart';

// -------------------------------
// Notifications
// -------------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel kHighChannel = AndroidNotificationChannel(
  'high_importance',
  'High Importance Notifications',
  description: 'Used for chat & urgent notifications',
  importance: Importance.high,
);

// -------------------------------
// Global User Presence Mana  ger
// -------------------------------
class GlobalUserPresenceManager {
  GlobalUserPresenceManager._internal();
  static final GlobalUserPresenceManager _instance = GlobalUserPresenceManager._internal();
  static GlobalUserPresenceManager get instance => _instance;

  UserPresence? _userPresence;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  StreamSubscription<User?>? _authSubscription;

  Future<void> initialize() async {
    debugPrint("🚀 Initializing GlobalUserPresenceManager...");
    await _authSubscription?.cancel();
    _authSubscription = _authService.auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _initializeUserPresence(user.uid);
      } else {
        await _disposeUserPresence();
      }
    });
  }

  Future<void> _initializeUserPresence(String userId) async {
    try {
      await _disposeUserPresence();
      _userPresence = UserPresence(userId: userId);
      await _userPresence!.initialize();
      debugPrint("✅ User presence initialized for: $userId");
    } catch (e) {
      debugPrint("❌ Error initializing presence: $e");
    }
  }

  Future<void> _disposeUserPresence() async {
    if (_userPresence != null) {
      try {
        await _userPresence!.dispose();
      } catch (e) {
        debugPrint("⚠️ Error disposing userPresence: $e");
      }
      _userPresence = null;
    }
  }

  Future<void> dispose() async {
    await _disposeUserPresence();
    await _authSubscription?.cancel();
    _authSubscription = null;
  }

  Future<void> updateActivity() async {
    if (_userPresence != null) {
      await _userPresence!.updateActivity();
    }
  }

  Map<String, dynamic> getStats() {
    final up = _userPresence;
    return {
      'has_user_presence_instance': up != null,
      'is_initialized': up?.isInitialized ?? false,
      'is_online': up?.isOnline ?? false,
    };
  }
}

// -------------------------------
// FCM background handler
// -------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 BG FCM: ${message.messageId} | data: ${message.data}');
}

// -------------------------------
// Main entry
// -------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeEnhancedBlocObserver();
  await _initializeServices();
  runApp(const BargainApp());
}

// -------------------------------
// Service initialization
// -------------------------------
MessageRepository? _messageRepo;

Future<void> _initializeServices() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM + local notifications setup
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
  await flutterLocalNotificationsPlugin.initialize(settings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(kHighChannel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // DB & Network
  await DatabaseHelper.instance.database;
  await NetworkManager.instance.initialize();

  // === ChatService init (set real endpoints) ===
  const String WS_ENDPOINT = 'wss://your-ws-endpoint.example/ws';
  const String SIGNING_ENDPOINT = 'https://your-signing-endpoint.example/sign';

  WsClient? wsClient;
  CdnUploader? cdnUploader;
  ChatDatabaseHelper? localDb;
  WsMessageHandler? wsMessageHandler;
  WsAckHandler? wsAckHandler;

  // Initialize all chat dependencies
  try {
    // Create WsClient with token provider
    wsClient = WsClient(
      Uri.parse(WS_ENDPOINT),
      tokenProvider: () async {
        final user = FirebaseAuth.instance.currentUser;
        final token = await user?.getIdToken();
        return token ?? '';
      },
    );

    // Create CdnUploader
    cdnUploader = CdnUploader(signingEndpoint: Uri.parse(SIGNING_ENDPOINT));

    // Create local database helper
    localDb = ChatDatabaseHelper();

    // Create WsMessageHandler (positional parameters)
    wsMessageHandler = WsMessageHandler(wsClient, logger: (msg) => debugPrint('[WsMsgHandler] $msg'));

    // Create WsAckHandler (positional parameters: wsMessageHandler, localDb)
    wsAckHandler = WsAckHandler(wsMessageHandler, localDb);

    debugPrint('✅ Chat dependencies created successfully');
  } catch (e) {
    debugPrint('⚠️ Failed to construct chat dependencies: $e');
  }

  // Initialize MessageRepository singleton
  try {
    if (wsClient == null || cdnUploader == null || localDb == null) {
      throw Exception('Chat dependencies not initialized');
    }

    await MessageRepository.instance.init(
      wsClient: wsClient,
      cdnUploader: cdnUploader,
      localDb: localDb,
      httpFallbackEndpoint: null,
      logger: (m) => debugPrint('[Repo] $m'),
    );
    _messageRepo = MessageRepository.instance;
    debugPrint('✅ MessageRepository initialized (singleton)');
  } catch (e) {
    debugPrint('⚠️ MessageRepository init failed: $e');
  }

  // Initialize ChatService with all dependencies
  try {
    if (wsClient == null ||
        cdnUploader == null ||
        localDb == null ||
        _messageRepo == null ||
        wsMessageHandler == null ||
        wsAckHandler == null) {
      throw Exception('Required dependencies not initialized');
    }

    final user = FirebaseAuth.instance.currentUser;

    await ChatService.instance.init(
      wsClient: wsClient,
      cdnUploader: cdnUploader,
      localDb: localDb,
      repo: _messageRepo!,
      wsMessageHandler: wsMessageHandler,
      wsAckHandler: wsAckHandler,
      currentUserId: user?.uid,
    );

    debugPrint('✅ ChatService initialized successfully');
  } catch (e) {
    debugPrint('⚠️ ChatService.init failed: $e');
  }

  // Presence manager
  try {
    await GlobalUserPresenceManager.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ Presence init failed: $e');
  }

  // Notification service
  try {
    NotificationService();
    debugPrint('✅ NotificationService created');
  } catch (e) {
    debugPrint('⚠️ NotificationService init failed: $e');
  }

  // If logged-in user exists -> initialize profile + save FCM token
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await UserService().initializeUser(user);
      await FirebaseAuthService.instance.saveUserFCMToken();
      debugPrint("✅ Firebase user initialized: ${user.uid}");
    } catch (e) {
      debugPrint('⚠️ User init at startup failed: $e');
    }
  } else {
    debugPrint("⚠️ No Firebase user found at startup.");
  }
}

// -------------------------------
// App widget
// -------------------------------
class BargainApp extends StatelessWidget {
  const BargainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LanguageNotifier()),
        Provider<NetworkManager>.value(value: NetworkManager.instance),
        if (_messageRepo != null) Provider<MessageRepository>.value(value: _messageRepo!),
        Provider<GlobalUserPresenceManager>.value(value: GlobalUserPresenceManager.instance),
        Provider<UserService>(create: (_) => UserService()),
      ],
      child: Consumer3<AppAuthProvider, ThemeNotifier, LanguageNotifier>(
        builder: (context, authProvider, themeNotifier, langNotifier, _) {
          FirebaseAuth.instance.authStateChanges().listen((user) {
            authProvider.setUserId(user?.uid);
          });

          return MaterialApp(
            title: 'Bargain',
            themeMode: themeNotifier.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: langNotifier.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('hi', ''),
              Locale('bn', ''),
              Locale('gu', ''),
              Locale('ta', ''),
              Locale('te', ''),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _AppLifecycleWrapper(
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return HomePage(user: snapshot.data!);
                  }
                  return const LoginPage();
                },
              ),
            ),
            routes: {
              '/appearance': (_) => const AppearanceSettingsPage(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// -------------------------------
// Theme notifier
// -------------------------------
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}

// -------------------------------
// App lifecycle wrapper
// -------------------------------
class _AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _AppLifecycleWrapper({required this.child});

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupServices();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      GlobalUserPresenceManager.instance.updateActivity();
    }
  }

  Future<void> _cleanupServices() async {
    try {
      await GlobalUserPresenceManager.instance.dispose();
    } catch (_) {}
    try {
      await ChatService.instance.dispose();
    } catch (_) {}
    try {
      await NetworkManager.instance.dispose();
    } catch (_) {}
    try {
      if (_messageRepo != null) {
        try {
          await (_messageRepo as dynamic).dispose();
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// -------------------------------
// Bloc observer
// -------------------------------
class EnhancedBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('🔄 BLoC Created: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (bloc is ChatBloc) {
      GlobalUserPresenceManager.instance.updateActivity();
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('❌ BLoC Error: ${bloc.runtimeType} - $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    debugPrint('🪄 BLoC Closed: ${bloc.runtimeType}');
  }
}

void initializeEnhancedBlocObserver() {
  Bloc.observer = EnhancedBlocObserver();
}