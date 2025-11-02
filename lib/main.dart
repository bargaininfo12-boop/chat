import 'package:bargain/Services/global_user_presence_manager.dart';
import 'package:bargain/chat/Core%20Services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/login/login_page.dart';
import 'package:bargain/homesceen/home_page.dart';
import 'package:bargain/account_setting/AppearanceSettingsPage.dart';

import 'package:bargain/Database/Firebase_all/app_auth_provider.dart';
import 'package:bargain/Database/database_helper.dart';
import 'package:bargain/Services/user_service.dart';
import 'package:bargain/chat/services/notification_service.dart';
import 'package:bargain/chat/utils/network_manager.dart';
import 'package:bargain/chat/Local Database Layer/chat_database_helper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel kHighChannel = AndroidNotificationChannel(
  'high_importance',
  'High Importance Notifications',
  description: 'Used for chat & urgent notifications',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 BG FCM: ${message.messageId} | data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeEnhancedBlocObserver();
  await _initializeServices();
  runApp(const BargainApp());
}

Future<void> _initializeServices() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  await DatabaseHelper.instance.database;
  await NetworkManager.instance.initialize();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await UserService().initializeUser(user);
      await FirebaseAuth.instance.currentUser?.getIdToken();
      await FirebaseMessaging.instance.getToken().then((token) {
        debugPrint("✅ FCM Token: $token");
      });
    } catch (e) {
      debugPrint('⚠️ User init failed: $e');
    }
  }

  try {
    await ChatService.instance.init(
      wsEndpoint: Uri.parse('wss://chat-q2sm.onrender.com'),
      imagekitAuthEndpoint: Uri.parse('https://chat-q2sm.onrender.com/api/imagekit-auth'),
      localDb: ChatDatabaseHelper(),
      tokenProvider: () async => await FirebaseAuth.instance.currentUser?.getIdToken() ?? '',
      httpFallbackEndpoint: null,
      logger: (msg) => debugPrint('[ChatService] $msg'),
    );
  } catch (e) {
    debugPrint('⚠️ ChatService init failed: $e');
  }

  try {
    await GlobalUserPresenceManager.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ Presence init failed: $e');
  }

  try {
    NotificationService();
    debugPrint('✅ NotificationService created');
  } catch (e) {
    debugPrint('⚠️ NotificationService init failed: $e');
  }
}

class BargainApp extends StatelessWidget {
  const BargainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        Provider<UserService>(create: (_) => UserService()),
        Provider<NetworkManager>.value(value: NetworkManager.instance),
        Provider<GlobalUserPresenceManager>.value(value: GlobalUserPresenceManager.instance),
      ],
      child: Consumer2<AppAuthProvider, ThemeNotifier>(
        builder: (context, authProvider, themeNotifier, _) {
          FirebaseAuth.instance.authStateChanges().listen((user) {
            authProvider.setUserId(user?.uid);
          });

          return MaterialApp(
            title: 'Bargain',
            themeMode: themeNotifier.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
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
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}

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
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class EnhancedBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('🔄 BLoC Created: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    GlobalUserPresenceManager.instance.updateActivity();
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
