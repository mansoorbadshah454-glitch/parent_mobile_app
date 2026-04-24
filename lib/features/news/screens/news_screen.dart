import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';
import '../widgets/parent_news_post_card.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsyncValue = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: newsAsyncValue.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final post = posts[index];
              return ParentNewsPostCard(post: post);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error loading feed: $error')),
      ),
    );
  }
}
