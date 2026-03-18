import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kids_provider.dart';

class KidsScreen extends ConsumerWidget {
  const KidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsyncValue = ref.watch(kidsProvider);

    return Scaffold(
      body: kidsAsyncValue.when(
        data: (kids) {
          if (kids.isEmpty) {
            return const Center(child: Text('No kids linked to this account.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: kids.length,
            itemBuilder: (context, index) {
              final kid = kids[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(kid.imageUrl),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      kid.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Class: ${kid.className}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
