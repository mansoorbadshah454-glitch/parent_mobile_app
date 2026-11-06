import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../services/notification_settings_helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/parent_data_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final languageCode = ref.watch(languageProvider);
    final parentDataAsync = ref.watch(parentDataProvider);

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
              // 1. Professional Parent Account Profile Card
              parentDataAsync.when(
                data: (parentData) => _buildParentProfileCard(context, parentData),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'App Language',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.primaryPurple,
                          ),
                        ),
                      ),
                      ListTile(
                        title: const Text('Select Language'),
                        trailing: DropdownButton<String>(
                          value: languageCode,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: ThemeColors.primaryPurple),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'ur', child: Text('Urdu (اردو)')),
                          ],
                          onChanged: (String? val) {
                            if (val != null) {
                              ref.read(languageProvider.notifier).setLanguage(val);
                            }
                          },
                        ),
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

  // 1. Beautiful, Modern Parent Account Profile Card
  Widget _buildParentProfileCard(BuildContext context, ParentData? parent) {
    if (parent == null) return const SizedBox.shrink();

    final String name = parent.name.isNotEmpty ? parent.name : 'Parent Account';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final String email = parent.email.isNotEmpty ? parent.email : 'No email linked';
    final String phone = (parent.phone != null && parent.phone!.trim().isNotEmpty) ? parent.phone! : 'Not specified';
    final String address = (parent.address != null && parent.address!.trim().isNotEmpty) ? parent.address! : 'Not specified';
    final String school = parent.schoolName ?? 'School';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon with Gradient Accent
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryPurple,
                  ThemeColors.primaryPurple.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: ThemeColors.primaryPurple.withOpacity(0.12),
                    backgroundImage: (parent.photoUrl != null && parent.photoUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(parent.photoUrl!)
                        : null,
                    child: (parent.photoUrl == null || parent.photoUrl!.isEmpty)
                        ? Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.primaryPurple,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Verified Parent',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        school,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details List
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileDetailRow(
                  context,
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF0284C7),
                  label: 'Contact Number',
                  value: phone,
                  canCopy: phone != 'Not specified',
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildProfileDetailRow(
                  context,
                  icon: Icons.alternate_email_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  label: 'Email Address',
                  value: email,
                  canCopy: email != 'No email linked',
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildProfileDetailRow(
                  context,
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFFD97706),
                  label: 'Residential Address',
                  value: address,
                  canCopy: address != 'Not specified',
                ),
                if (parent.cnic != null && parent.cnic!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildProfileDetailRow(
                    context,
                    icon: Icons.badge_rounded,
                    iconColor: const Color(0xFF059669),
                    label: 'CNIC / National ID',
                    value: parent.cnic!,
                    canCopy: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool canCopy = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (canCopy)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy $label',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied: $value'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
      ],
    );
  }
}
