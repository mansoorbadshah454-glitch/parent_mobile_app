import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsHelper {
  // SharedPreferences Keys
  static const String keyNewPostAlert = 'new_post_alert_enabled';
  static const String keyMsgAlert = 'msg_alert_enabled';
  static const String keyAttendanceAlert = 'attendance_alert_enabled';
  static const String keyAcademicAlert = 'academic_alert_enabled';
  static const String keyWellnessAlert = 'wellness_alert_enabled';

  /// Evaluates whether the notification of [type] should be displayed
  /// based on user preferences in SharedPreferences.
  static Future<bool> shouldShowNotification(String type) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Fee always bypasses alert rules
    if (type == 'fee' || type == 'fee_update') {
      return true;
    }

    if (type == 'post' || type == 'news') {
      return prefs.getBool(keyNewPostAlert) ?? true;
    } 
    
    if (type == 'chat' || type == 'admin-message' || type == 'chat_message' || type == 'message') {
      return prefs.getBool(keyMsgAlert) ?? true;
    } 
    
    if (type == 'attendance') {
      return prefs.getBool(keyAttendanceAlert) ?? true;
    }
    
    // Academic bundle
    if (type == 'academic' || type == 'behavior' || type == 'personality' || type == 'performance' || type == 'celebration') {
      return prefs.getBool(keyAcademicAlert) ?? true;
    }

    // Wellness bundle
    if (type == 'wellness' || type == 'health' || type == 'hygiene') {
      return prefs.getBool(keyWellnessAlert) ?? true;
    }

    // Default to true for any unknown type
    return true;
  }
}
