import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../services/notification_settings_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _newPostAlert = true;
  bool _msgAlert = true;
  bool _attendanceAlert = true;
  bool _academicAlert = true;
  bool _wellnessAlert = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _newPostAlert = prefs.getBool(NotificationSettingsHelper.keyNewPostAlert) ?? true;
      _msgAlert = prefs.getBool(NotificationSettingsHelper.keyMsgAlert) ?? true;
      _attendanceAlert = prefs.getBool(NotificationSettingsHelper.keyAttendanceAlert) ?? true;
      _academicAlert = prefs.getBool(NotificationSettingsHelper.keyAcademicAlert) ?? true;
      _wellnessAlert = prefs.getBool(NotificationSettingsHelper.keyWellnessAlert) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple))
        : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('New Post Alert'),
                        subtitle: const Text('Updates on newsfeed'),
                        activeColor: ThemeColors.primaryPurple,
                        value: _newPostAlert,
                        onChanged: (bool value) {
                          setState(() => _newPostAlert = value);
                          _saveSetting(NotificationSettingsHelper.keyNewPostAlert, value);
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: const Text('Msg Alert'),
                        subtitle: const Text('New chat messages'),
                        activeColor: ThemeColors.primaryPurple,
                        value: _msgAlert,
                        onChanged: (bool value) {
                          setState(() => _msgAlert = value);
                          _saveSetting(NotificationSettingsHelper.keyMsgAlert, value);
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: const Text('Attendance Alert'),
                        activeColor: ThemeColors.primaryPurple,
                        value: _attendanceAlert,
                        onChanged: (bool value) {
                          setState(() => _attendanceAlert = value);
                          _saveSetting(NotificationSettingsHelper.keyAttendanceAlert, value);
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: const Text('Academic Alerts'),
                        subtitle: const Text('Performance, behavior & celebrations'),
                        activeColor: ThemeColors.primaryPurple,
                        value: _academicAlert,
                        onChanged: (bool value) {
                          setState(() => _academicAlert = value);
                          _saveSetting(NotificationSettingsHelper.keyAcademicAlert, value);
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: const Text('Wellness Alerts'),
                        subtitle: const Text('Health and hygiene updates'),
                        activeColor: ThemeColors.primaryPurple,
                        value: _wellnessAlert,
                        onChanged: (bool value) {
                          setState(() => _wellnessAlert = value);
                          _saveSetting(NotificationSettingsHelper.keyWellnessAlert, value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
