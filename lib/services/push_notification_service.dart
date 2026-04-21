import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/router/app_router.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../core/theme/theme_colors.dart';
import '../features/kids/providers/kids_provider.dart';

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
           routeFromType(launchDetails!.notificationResponse!.payload);
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
    int tabIndex = 0; // Default to news
    if (type == 'fee' || type == 'fee_update') {
      tabIndex = 4; // Fee tab
    } else if (type == 'chat' || type == 'admin-message' || type == 'chat_message' || type == 'message') {
      tabIndex = 2; // Chat tab
    } else if (type == 'alert' || type == 'academic' || type == 'health' || type == 'wellness' || type == 'behavior' || type == 'hygiene' || type == 'personality' || type == 'performance' || type == 'celebration' || type == 'info') {
      tabIndex = 3; // Alerts tab
    } else if (type == 'post' || type == 'news') {
      tabIndex = 0; // News tab
    } else if (type == 'kid' || type == 'kids') {
      tabIndex = 1; // Kids tab
    }
    
    // Jump to the right tab using the provider
    _container?.read(dashboardTabProvider.notifier).state = tabIndex;
  }

  static OverlayEntry? _currentBanner;

  static void showGlobalAlert(String title, String body, String type, {bool isEmergency = false}) {
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

class AnimatedTopBanner extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final bool isEmergency;
  final VoidCallback onDismissed;

  const AnimatedTopBanner({
    Key? key,
    required this.title,
    required this.body,
    required this.type,
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
                        PushNotificationService().routeFromType(widget.type);
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
