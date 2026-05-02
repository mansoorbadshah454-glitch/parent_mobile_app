import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/router/app_router.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../core/theme/theme_colors.dart';
import '../features/kids/providers/kids_provider.dart';
import '../features/kids/screens/kid_details_screen.dart';
import 'notification_settings_helper.dart';

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

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        routeFromType(response.payload);
      },
    );

    // Handle initialization from terminated state
    final NotificationAppLaunchDetails? launchDetails = await _localNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      if (launchDetails?.notificationResponse != null) {
         Future.delayed(const Duration(milliseconds: 1000), () {
           try {
             routeFromType(launchDetails!.notificationResponse!.payload);
           } catch (e) {
             print('Error routing from terminated state payload: $e');
           }
         });
      }
    }
  }

  Future<void> scheduleFeeReminders(KidData kid) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fee_reminders', 'Fee Reminders',
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    
    // Periodically show daily. Note: this triggers the first time 24 hours from now. 
    // We rely on in-app banner for immediate alerts today.
    await _localNotificationsPlugin.periodicallyShow(
      kid.id.hashCode,
      'Fee Reminder',
      'Please clear the pending fee for ${kid.name}.',
      RepeatInterval.daily,
      notificationDetails,
      payload: 'fee',
    );
  }

  Future<void> cancelFeeReminders(KidData kid) async {
    await _localNotificationsPlugin.cancel(kid.id.hashCode);
  }

  // Handle routing based on type
  void routeFromType(String? type) {
    if (type == null) return;
    
    String baseType = type;
    String? kidIdPayload;
    if (type.contains(':')) {
      final parts = type.split(':');
      baseType = parts[0];
      kidIdPayload = parts.length > 1 ? parts[1] : null;
    }

    int tabIndex = 0; // Default to news
    if (baseType == 'fee' || baseType == 'fee_update') {
      tabIndex = 4; // Fee tab
    } else if (baseType == 'chat' || baseType == 'admin-message' || baseType == 'chat_message' || baseType == 'message') {
      tabIndex = 2; // Chat tab
    } else if (baseType == 'alert' || baseType == 'academic' || baseType == 'health' || baseType == 'wellness' || baseType == 'behavior' || baseType == 'hygiene' || baseType == 'personality' || baseType == 'performance' || baseType == 'celebration' || baseType == 'info') {
      tabIndex = 3; // Alerts tab
    } else if (baseType == 'post' || baseType == 'news') {
      tabIndex = 0; // News tab
    } else if (baseType == 'kid' || baseType == 'kids' || baseType == 'result') {
      tabIndex = 1; // Kids tab
    }
    
    // Jump to the right tab using the provider
    _container?.read(dashboardTabProvider.notifier).state = tabIndex;

    // Direct route for result card alerts
    if (baseType == 'result' && kidIdPayload != null && kidIdPayload.isNotEmpty) {
      final kidsAsyncValue = _container?.read(kidsProvider);
      if (kidsAsyncValue != null && kidsAsyncValue.hasValue) {
        try {
          final kid = kidsAsyncValue.value!.firstWhere((k) => k.id == kidIdPayload);
          Future.delayed(const Duration(milliseconds: 300), () {
            rootNavigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => KidDetailsScreen(kid: kid, initialTabIndex: 3)),
            );
          });
        } catch (e) {
          print("Kid ID not found for result routing: $e");
        }
      }
    }
  }

  static OverlayEntry? _currentBanner;

  static void showGlobalAlert(String title, String body, String type, {bool isEmergency = false, String? payload}) {
    final overlayState = rootNavigatorKey.currentState?.overlay;
    if (overlayState != null) {
      if (_currentBanner != null) {
        _currentBanner?.remove();
        _currentBanner = null;
      }
      
      _currentBanner = OverlayEntry(
        builder: (ctx) => AnimatedTopBanner(
          title: title,
          body: body,
          type: type,
          payload: payload ?? type,
          isEmergency: isEmergency,
          onDismissed: () {
            if (_currentBanner != null) {
               _currentBanner?.remove();
               _currentBanner = null;
            }
          },
        )
      );
      overlayState.insert(_currentBanner!);
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
      try {
        String? token = await _fcm.getToken();
        if (token != null) {
           await saveTokenToDatabase(token, schoolId, uid);
        }
      } catch (e) {
        print("Error getting FCM token: $e");
      }

      // Refresh listener
      _fcm.onTokenRefresh.listen((newToken) {
         saveTokenToDatabase(newToken, schoolId, uid);
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        try {
          print('Got a push notification whilst in the foreground!');

          final title = (message.notification?.title ?? message.data['title'] ?? 'Notification').toString();
          final body = (message.notification?.body ?? message.data['body'] ?? '').toString();
          final type = (message.data['type'] ?? '').toString();
          final kidId = message.data['kidId']?.toString() ?? message.data['studentId']?.toString();
            
          if (title == 'Notification' && body.isEmpty && type.isEmpty) return; // Prevent empty pings

          final resolvedType = (type == 'alert' && message.data['alertType'] != null && message.data['alertType'].toString().isNotEmpty) 
              ? message.data['alertType'].toString()
              : type;

          String routingPayload = (resolvedType == 'result' && kidId != null) ? '$resolvedType:$kidId' : resolvedType;
            
          final shouldShow = await NotificationSettingsHelper.shouldShowNotification(resolvedType);
          if (!shouldShow) return;

          bool isEmergency = type == 'alert' && title.contains('Urgent');

          showGlobalAlert(title, body, type, isEmergency: isEmergency, payload: routingPayload);
        } catch (e) {
          print('Error handling foreground message: $e');
        }
      });
      
      // Background message tap handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        try {
           final type = message.data['type']?.toString();
           final kidId = message.data['kidId']?.toString() ?? message.data['studentId']?.toString();
           final alertType = message.data['alertType'];
           
           final resType = (type == 'alert' && alertType != null) ? alertType.toString() : type;
           
           if (resType == 'result' && kidId != null) {
              routeFromType('$resType:$kidId');
           } else {
              routeFromType(resType);
           }
        } catch (e) {
          print('Error handling message tap: $e');
        }
      });
      
    } else {
      print('Parent User declined or has not accepted permission');
    }
  }

  Future<void> saveTokenToDatabase(String token, String schoolId, String uid) async {
    try {
      // FCM Topic Subscription for scalable broadcasts
      await FirebaseMessaging.instance.subscribeToTopic('${schoolId}_parents');
      await FirebaseMessaging.instance.subscribeToTopic('${schoolId}_all');

      await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('parents')
        .doc(uid)
        .set({
          'fcmToken': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
        print('FCM Token and Topics saved successfully for Parent');
    } catch (e) {
      print('Error saving FCM token/topics for Parent: $e');
    }
  }
}

class AnimatedTopBanner extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final String payload;
  final bool isEmergency;
  final VoidCallback onDismissed;

  const AnimatedTopBanner({
    Key? key,
    required this.title,
    required this.body,
    required this.type,
    required this.payload,
    this.isEmergency = false,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<AnimatedTopBanner> createState() => _AnimatedTopBannerState();
}

class _AnimatedTopBannerState extends State<AnimatedTopBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 400),
       vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Hold the banner for 4 seconds then reverse
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isDismissed) {
         _controller.reverse().then((value) {
            if (!_isDismissed) {
               _isDismissed = true;
               widget.onDismissed();
            }
         });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismissBanner() {
    if (!_isDismissed) {
      _isDismissed = true;
      _controller.reverse().then((_) {
        widget.onDismissed();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      // SafeArea automatically prevents overlapping with the status bar icons
      child: SafeArea(
        child: SlideTransition(
          position: _offsetAnimation,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) {
              if (!_isDismissed) {
                 _isDismissed = true;
                 widget.onDismissed();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                   color: widget.isEmergency ? Colors.red.shade600 : ThemeColors.primaryPurple,
                   borderRadius: BorderRadius.circular(12),
                   boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 10)],
                ),
                child: ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                   title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                   subtitle: widget.body.isNotEmpty ? Padding(
                     padding: const EdgeInsets.only(top: 4),
                     child: Text(widget.body, style: const TextStyle(color: Colors.white)),
                   ) : null,
                   trailing: TextButton(
                     onPressed: () {
                        _dismissBanner();
                        PushNotificationService().routeFromType(widget.payload);
                     },
                     style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     ),
                     child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
