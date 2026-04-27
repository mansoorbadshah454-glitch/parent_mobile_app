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
    final title = data['title'] ?? message.notification?.title ?? 'New Notification';
    final body = data['body'] ?? message.notification?.body ?? 'You have a new update';
    final type = data['type'] ?? 'info';
    
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable aggressive offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  print("💽 [Main] Firestore Offline Persistence Enabled");
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();
  PushNotificationService().setContainer(container);

  try {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
          final type = message.data['type'];
          PushNotificationService().routeFromType(type);
      });
    }
  } catch (e) {
    print("Error getting initial message: $e");
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const ParentApp(),
  ));
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
