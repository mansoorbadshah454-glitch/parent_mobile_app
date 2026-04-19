import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/parent_data_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentDataAsync = ref.watch(parentDataProvider);

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        title: const Text('Help & Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: parentDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading parent data.')),
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
                return const Center(child: Text('Error loading school profile.'));
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final address = data['address'] as String? ?? 'Address not updated';
              final phone = data['phone'] as String? ?? 'Phone not updated';
              final email = data['email'] as String? ?? 'Email not updated';
              final emergencyContact = data['emergencyContact'] as String? ?? 'Not updated';

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Contact Widget
                      _buildSupportCard(
                        icon: Icons.phone_in_talk,
                        title: "School Contacts",
                        details: [
                          _buildDetailRow(Icons.phone, "Main Office", phone),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider()),
                          _buildDetailRow(Icons.email, "Email", email),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Emergency Widget
                      _buildSupportCard(
                        icon: Icons.emergency,
                        iconColor: Colors.redAccent,
                        title: "Emergency Contact",
                        details: [
                          _buildDetailRow(Icons.phone_callback, "Emergency Line", emergencyContact),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Address Widget
                      _buildSupportCard(
                        icon: Icons.location_on,
                        title: "School Address",
                        details: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.map, color: ThemeColors.secondaryText, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeColors.primaryText,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
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

  Widget _buildSupportCard({required IconData icon, Color iconColor = ThemeColors.primaryPurple, required String title, required List<Widget> details}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ThemeColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ThemeColors.primaryText,
          ),
        ),
      ],
    );
  }
}
