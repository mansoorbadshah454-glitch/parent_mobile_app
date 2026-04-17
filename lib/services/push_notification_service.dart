import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router/app_router.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../core/theme/theme_colors.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  ProviderContainer? _container;
  bool _initialized = false;

  void setContainer(ProviderContainer container) {
    _container = container;
  }

  // Handle routing based on type
  void routeFromType(String? type) {
    if (type == null) return;
    int tabIndex = 0; // Default to news
    if (type == 'chat' || type == 'admin-message' || type == 'chat_message' || type == 'message') {
      tabIndex = 2; // Chat tab
    } else if (type == 'alert' || type == 'academic' || type == 'health' || type == 'wellness' || type == 'behavior' || type == 'hygiene' || type == 'personality' || type == 'performance' || type == 'celebration' || type == 'info') {
      tabIndex = 3; // Alerts tab
    }
    
    // Jump to the right tab using the provider
    _container?.read(dashboardTabProvider.notifier).state = tabIndex;
  }

  static void showGlobalAlert(String title, String body, String type, {bool isEmergency = false}) {
    final context = rootScaffoldMessengerKey.currentContext;
    if (context != null) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
               if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: Colors.white)),
               ]
            ]
          ),
          backgroundColor: isEmergency ? Colors.red.shade600 : ThemeColors.primaryPurple,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: "VIEW", 
            textColor: Colors.white, 
            onPressed: () {
               PushNotificationService().routeFromType(type);
            }
          ),
        )
      );
    }
  }

  Future<void> init(String schoolId, String uid) async {
    if (_initialized) return;
    _initialized = true;

    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Parent User granted permission for FCM');
      // Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
         await saveTokenToDatabase(token, schoolId, uid);
      }

      // Refresh listener
      _fcm.onTokenRefresh.listen((newToken) {
         saveTokenToDatabase(newToken, schoolId, uid);
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('Got a push notification whilst in the foreground!');

        if (message.notification != null) {
          final title = message.notification?.title ?? 'Notification';
          final body = message.notification?.body ?? '';
          final type = message.data['type'] ?? '';
          
          bool isEmergency = type == 'alert' && title.contains('Urgent');

          showGlobalAlert(title, body, type, isEmergency: isEmergency);
        }
      });
      
      // Background message tap handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
         final type = message.data['type'];
         routeFromType(type);
      });
      
    } else {
      print('Parent User declined or has not accepted permission');
    }
  }

  Future<void> saveTokenToDatabase(String token, String schoolId, String uid) async {
    try {
      await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('parents')
        .doc(uid)
        .set({
          'fcmToken': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
        print('FCM Token saved successfully for Parent');
    } catch (e) {
      print('Error saving FCM token for Parent: $e');
    }
  }
}
