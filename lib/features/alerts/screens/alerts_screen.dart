import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/alerts_provider.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/screens/kid_details_screen.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';
import 'performance_update_screen.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final Set<String> _selectedAlerts = {};
  bool _isSelectionMode = false;

  Widget _buildAlertIcon(alert) {
    IconData iconData;
    Color color;

    switch (alert.type?.toLowerCase()) {
      case 'attendance':
        bool isPresent;
        if (alert.status != null) {
          isPresent = alert.status!.toLowerCase() == 'present' || alert.status!.toLowerCase() == 'p';
        } else {
          isPresent = alert.message.toLowerCase().contains('present');
        }
        iconData = isPresent ? Icons.check_circle_outline : Icons.cancel_outlined;
        color = isPresent ? Colors.green : Colors.redAccent;
        break;
      case 'behavior':
      case 'health':
      case 'hygiene':
      case 'personality':
        final t = alert.type?.toLowerCase();
        if (t == 'behavior') {
          iconData = Icons.psychology_rounded;
        } else if (t == 'health') {
          iconData = Icons.health_and_safety_rounded;
        } else if (t == 'hygiene') {
          iconData = Icons.clean_hands_rounded;
        } else {
          iconData = Icons.volunteer_activism_rounded;
        }
        
        // Default specific colors
        Color specificColor = t == 'behavior' ? Colors.indigoAccent
            : t == 'health' ? Colors.pinkAccent
            : t == 'hygiene' ? Colors.cyan.shade600
            : Colors.teal.shade500;

        // Apply green/red wellness logic if a score/status allows derivation
        if (alert.status != null) {
           final stat = alert.status!.toLowerCase();
           final double? score = double.tryParse(stat);
           // Score > 1.0 is considered good (green), 1.0 or below is needs improvement (red).
           // Also checking string keywords.
           if (stat == 'excellent' || stat == 'good' || stat == 'satisfactory' || (score != null && score > 1.0)) {
             color = Colors.green;
           } else if (stat == 'needs improvement' || stat == 'poor' || (score != null && score <= 1.0)) {
             color = Colors.redAccent;
           } else {
             color = specificColor;
           }
        } else {
           // Fallback to message check if score is embedded in the message
           if (alert.message.toLowerCase().contains('needs improvement') || alert.message.toLowerCase().contains('poor')) {
             color = Colors.redAccent;
           } else if (alert.message.toLowerCase().contains('excellent') || alert.message.toLowerCase().contains('good')) {
             color = Colors.green;
           } else {
             color = specificColor;
           }
        }
        break;
      case 'academic':
      case 'performance':
      case 'performance update':
      case 'celebration':
        iconData = Icons.school_rounded;
        color = ThemeColors.primaryPurple;
        break;
      case 'result':
      case 'document':
        iconData = Icons.inventory_rounded;
        color = Colors.indigo;
        break;
      case 'alert':
      case 'info':
        iconData = Icons.info_outline_rounded;
        color = Colors.blueAccent;
        break;
      default:
        iconData = Icons.notifications_active_rounded;
        color = Colors.orangeAccent;
    }

    return CircleAvatar(
      backgroundColor: alert.read ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.15),
      child: Icon(iconData, color: alert.read ? color.withValues(alpha: 0.5) : color),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedAlerts.contains(id)) {
        _selectedAlerts.remove(id);
        if (_selectedAlerts.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedAlerts.add(id);
      }
    });
  }

  void _deleteSelected() {
    if (_selectedAlerts.isEmpty) return;
    final actions = ref.read(alertsActionProvider);
    actions.clearAllAlerts(_selectedAlerts.toList());
    setState(() {
      _selectedAlerts.clear();
      _isSelectionMode = false;
    });
  }

  void _clearAll(List<AlertModel> alerts) {
    if (alerts.isEmpty) return;
    final actions = ref.read(alertsActionProvider);
    actions.clearAllAlerts(alerts.map((a) => a.id).toList());
  }

  void _navigateToKid(AlertModel alert) {
    if (alert.studentId == null) return;
    final kidsData = ref.read(kidsProvider).value;
    if (kidsData == null) return;

    KidData? targetKid;
    for (var k in kidsData) {
      if (k.id == alert.studentId) {
        targetKid = k;
        break;
      }
    }

    if (targetKid != null) {
      final type = alert.type.toLowerCase();
      final title = alert.title.toLowerCase();
      final message = alert.message.toLowerCase();
      
      if (!alert.read) {
        ref.read(alertsActionProvider).markAsRead(alert.id);
      }

      if (type.contains('academic') || type.contains('performance') ||
          title.contains('academic') || title.contains('performance') ||
          message.contains('performance')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PerformanceUpdateScreen(
              kid: targetKid!,
            ),
          ),
        );
      } else {
        int tabIndex = 0; // Default fallback to Academic
        
        if (['attendance'].contains(type)) {
          tabIndex = 2; // Index 2 is Attendance
        } else if (['health', 'behavior', 'hygiene', 'personality'].contains(type)) {
          tabIndex = 1; // Index 1 is Personality
        } else if (['celebration'].contains(type)) {
          tabIndex = 0; // Index 0 is Academic
        } else if (['result', 'document'].contains(type)) {
          tabIndex = 3; // Index 3 is Result
        } else {
          tabIndex = 0; // Default fallback for unknown types
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KidDetailsScreen(
              kid: targetKid!,
              initialTabIndex: tabIndex,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsyncValue = ref.watch(alertsProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Builder(
        builder: (context) {
          if (alertsAsyncValue.hasValue) {
            final alerts = alertsAsyncValue.value!;
            if (alerts.isEmpty) {
              return const Center(child: Text('No new alerts.'));
            }
            return Column(
              children: [
                // Header Toolbar
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isSelectionMode ? ThemeColors.primaryPurple.withValues(alpha: 0.1) : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isSelectionMode) ...[
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedAlerts.clear();
                                  _isSelectionMode = false;
                                });
                              },
                            ),
                            Text(
                              '${_selectedAlerts.length} Selected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: _deleteSelected,
                        ),
                      ] else ...[
                        Text(
                          TranslationHelper.translate('Recent Alerts', lang),
                          style: TranslationHelper.getTextStyle(
                            lang,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.primaryPurple,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'select') {
                              setState(() {
                                _isSelectionMode = true;
                              });
                            } else if (value == 'clear_all') {
                              _clearAll(alerts);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'select',
                              child: Text('Select to Delete'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'clear_all',
                              child: Text('Clear All'),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final isSelected = _selectedAlerts.contains(alert.id);

                      return Container(
                        color: isSelected 
                            ? ThemeColors.primaryPurple.withValues(alpha: 0.15) 
                            : (!alert.read ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.transparent),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() {
                                 _isSelectionMode = true;
                                 _selectedAlerts.add(alert.id);
                              });
                            }
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(alert.id);
                            } else {
                              _navigateToKid(alert);
                            }
                          },
                          leading: _isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  activeColor: ThemeColors.primaryPurple,
                                  onChanged: (bool? value) {
                                    _toggleSelection(alert.id);
                                  },
                                )
                              : _buildAlertIcon(alert),
                          title: Text(
                            TranslationHelper.translate(alert.title, lang),
                            style: TranslationHelper.getTextStyle(
                              lang,
                              fontWeight: alert.read ? FontWeight.normal : FontWeight.bold,
                            ).copyWith(height: 1.2),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                TranslationHelper.translate(alert.message, lang),
                                style: TranslationHelper.getTextStyle(lang, fontSize: 13, height: 1.5),
                              ),
                              if (alert.createdAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat.yMMMd().add_jm().format(alert.createdAt!),
                                  style: TextStyle(
                                    color: Colors.grey[500], 
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ]
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          if (alertsAsyncValue.hasError) {
            return Center(child: Text('Error: ${alertsAsyncValue.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
