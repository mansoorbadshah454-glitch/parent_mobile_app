import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kids_provider.dart';
import '../widgets/shining_profile_avatar.dart';
import 'kid_details_screen.dart';

class KidsScreen extends ConsumerWidget {
  const KidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsyncValue = ref.watch(kidsProvider);

    return Scaffold(
      body: Builder(
        builder: (context) {
          if (kidsAsyncValue.hasValue) {
            final kids = kidsAsyncValue.value!;
            if (kids.isEmpty) {
              return const Center(child: Text('No kids linked to this account.'));
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              itemCount: kids.length,
              itemBuilder: (context, index) {
                final kid = kids[index];
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KidDetailsScreen(kid: kid),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      child: Row(
                        children: [
                          ShiningProfileAvatar(
                            imageUrl: kid.imageUrl,
                            radius: 28, // Scaled for standard vertical list
                            strokeWidth: 2.5,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kid.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Class: ${kid.className}  |  Roll: ${kid.rollNo}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          if (kidsAsyncValue.hasError) {
            return Center(child: Text('Error: ${kidsAsyncValue.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
