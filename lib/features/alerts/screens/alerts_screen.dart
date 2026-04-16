import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/alerts_provider.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/screens/kid_details_screen.dart';
import '../../../core/theme/theme_colors.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final Set<String> _selectedAlerts = {};
  bool _isSelectionMode = false;

  Widget _buildAlertIcon(alert) {
    if (alert.read) {
      return CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: const Icon(Icons.notifications, color: Colors.grey),
      );
    }

    IconData iconData;
    Color color;

    switch (alert.type) {
      case 'attendance':
        bool isPresent = alert.status?.toLowerCase() == 'present' || alert.status?.toLowerCase() == 'p';
        iconData = isPresent ? Icons.check_circle_outline : Icons.cancel_outlined;
        color = isPresent ? Colors.green : Colors.redAccent;
        break;
      case 'personality':
        iconData = Icons.volunteer_activism_rounded;
        color = Colors.teal.shade500; // Distinct thick teal for personality
        break;
      case 'academic':
      case 'performance':
      case 'celebration':
        iconData = Icons.school_rounded;
        color = ThemeColors.primaryPurple;
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
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(iconData, color: color),
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
      int tabIndex = 0; // Default fallback to Academic
      final type = alert.type.toLowerCase();
      
      if (['attendance'].contains(type)) {
        tabIndex = 2; // Index 2 is Attendance
      } else if (['health', 'behavior', 'hygiene', 'personality'].contains(type)) {
        tabIndex = 1; // Index 1 is Personality
      } else if (['academic', 'performance', 'celebration'].contains(type)) {
        tabIndex = 0; // Index 0 is Academic
      } else {
        tabIndex = 0; // Default fallback for unknown types
      }

      if (!alert.read) {
        ref.read(alertsActionProvider).markAsRead(alert.id);
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

  @override
  Widget build(BuildContext context) {
    final alertsAsyncValue = ref.watch(alertsProvider);

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
                        const Text(
                          'Recent Alerts',
                          style: TextStyle(
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
                            alert.title,
                            style: TextStyle(
                              fontWeight: alert.read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(alert.message),
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
