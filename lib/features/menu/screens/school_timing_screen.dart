import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/parent_data_provider.dart';

class SchoolTimingScreen extends ConsumerWidget {
  const SchoolTimingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentDataAsync = ref.watch(parentDataProvider);

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        title: const Text('School Timing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: parentDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Error loading parent data.')),
        data: (parentData) {
          if (parentData == null || parentData.schoolId.isEmpty) {
            return const Center(child: Text('School info not found.'));
          }
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('schools').doc(parentData.schoolId).collection('settings').doc('profile').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading timings.'));
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final start = data['schoolStartTime'] as String? ?? '08:00 AM';
              final end = data['schoolEndTime'] as String? ?? '02:00 PM';
              final breakStart = data['breakStartTime'] as String? ?? '10:30 AM';
              final breakEnd = data['breakEndTime'] as String? ?? '11:00 AM';

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Note: This is the official school's timing.",
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Widget below
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: ThemeColors.lightPurple.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.access_time_filled, size: 48, color: ThemeColors.primaryPurple),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Regular Timings",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildTimeRow(Icons.wb_sunny_rounded, "Morning Arrival", start),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Divider(),
                              ),
                              _buildTimeRow(Icons.directions_run_rounded, "Break Time", "$breakStart - $breakEnd"),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Divider(),
                              ),
                              _buildTimeRow(Icons.home_rounded, "School Off", end),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildTimeRow(IconData icon, String title, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(icon, color: ThemeColors.secondaryText, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ThemeColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: ThemeColors.primaryText,
          ),
        ),
      ],
    );
  }
}
