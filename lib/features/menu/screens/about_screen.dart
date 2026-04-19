import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/parent_data_provider.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentDataAsync = ref.watch(parentDataProvider);

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        title: const Text('About Us', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                return const Center(child: Text('Error loading about details.'));
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final aboutText = data['aboutText'] as String?;
              final profileImage = data['profileImage'] as String?;
              final hasAboutText = aboutText != null && aboutText.trim().isNotEmpty;

              return SingleChildScrollView(
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
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              if (profileImage != null && profileImage.isNotEmpty)
                                ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profileImage,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 120,
                                      width: 120,
                                      color: ThemeColors.lightPurple.withOpacity(0.3),
                                      child: const Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple)),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      height: 120,
                                      width: 120,
                                      color: ThemeColors.lightPurple.withOpacity(0.3),
                                      child: const Icon(Icons.school, size: 64, color: ThemeColors.primaryPurple),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: ThemeColors.lightPurple.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.school, size: 64, color: ThemeColors.primaryPurple),
                                ),
                              const SizedBox(height: 24),
                              const Text(
                                "Our School's Mission",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hasAboutText 
                                  ? aboutText 
                                  : "This section will be updated soon with detailed information about our core values, mission, and history.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: ThemeColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                "App Version 1.0.0",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ThemeColors.secondaryText,
                                ),
                              ),
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
}
