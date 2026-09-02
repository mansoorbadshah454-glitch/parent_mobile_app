import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/push_notification_service.dart';
import 'services/notification_settings_helper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    
    final data = message.data;
    final title = (data['title'] ?? message.notification?.title ?? 'New Notification').toString();
    final body = (data['body'] ?? message.notification?.body ?? 'You have a new update').toString();
    final type = data['type']?.toString() ?? 'info';
    
    // Unpack alertType if this is a generic 'alert' bundle
    final resolvedType = (type == 'alert' && data['alertType'] != null && data['alertType'].toString().isNotEmpty) 
        ? data['alertType'].toString()
        : type;
    
    final shouldShow = await NotificationSettingsHelper.shouldShowNotification(resolvedType);
    if (!shouldShow) return;
    
    bool isEmergency = type == 'alert' && title.toString().toLowerCase().contains('urgent');

    final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await localNotificationsPlugin.initialize(initializationSettings);

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isEmergency ? 'emergency_channel' : 'high_importance_channel',
      isEmergency ? 'Emergency Alerts' : 'Important Notifications',
      channelDescription: 'Used for important parent app notifications.',
      importance: isEmergency ? Importance.max : Importance.high,
      priority: isEmergency ? Priority.max : Priority.high,
      enableVibration: true,
      playSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Only show a local notification if it's a data-only message.
    // If message.notification is not null, FCM automatically displays a system notification.
    if (message.notification == null) {
      await localNotificationsPlugin.show(
        message.messageId.hashCode,
        title,
        body,
        platformDetails,
        payload: type,
      );
    }
  } catch (e) {
    print("Background Isolate Crash Prevented: $e");
  }
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Global Error Handlers for Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print("Flutter Error Caught: ${details.exception}");
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      print("Platform Dispatcher Error Caught: $error");
      return true;
    };

    try {
      await Firebase.initializeApp();
      
      // Enable bounded offline persistence to prevent storage bloat
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 100 * 1024 * 1024, // Enterprise Scalability: Cap at 100MB
      );
      print("💽 [Main] Firestore Offline Persistence Enabled");
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final container = ProviderContainer();
      PushNotificationService().setContainer(container);

      try {
        final message = await FirebaseMessaging.instance.getInitialMessage();
        if (message != null) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            try {
              final dynamic rawType = message.data['type'];
              final String? type = rawType?.toString();
              PushNotificationService().routeFromType(type);
            } catch (e) {
              print("Error routing initial message: $e");
            }
          });
        }
      } catch (e) {
        print("Error getting initial message: $e");
      }

      runApp(UncontrolledProviderScope(
        container: container,
        child: const ParentApp(),
      ));
      
    } catch (e, stackTrace) {
      print("FATAL INITIALIZATION ERROR: $e");
      runApp(ErrorApp(errorMessage: e.toString(), stackTrace: stackTrace.toString()));
    }
  }, (error, stack) {
    print("Zoned Error Caught: $error");
  });
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;
  final String stackTrace;

  const ErrorApp({super.key, required this.errorMessage, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Initialization Error', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The app failed to start due to a configuration error.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              const Text(
                'If you downloaded this from the Play Store, you likely need to add the Google Play App Signing SHA-1 fingerprint to your Firebase Console.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text('Error Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Text(errorMessage, style: const TextStyle(fontFamily: 'monospace')),
              ),
              const SizedBox(height: 16),
              const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Text(stackTrace, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentApp extends ConsumerWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Parent Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
