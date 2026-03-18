import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCommentsModal extends StatelessWidget {
  final String schoolId;
  final String postId;

  const PostCommentsModal({
    super.key,
    required this.schoolId,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // Comments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(schoolId)
                  .collection('posts')
                  .doc(postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false) // oldest first usually for comments, but we can stick to desc. Let's do desc since appending. Wait, Facebook usually shows top comments but desc is easiest. FB does asc if at bottom. Let's do desc for newest first at the top of scroll.
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final comments = snapshot.data?.docs ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    final authorName = data['authorName'] ?? 'User';
                    final text = data['text'] ?? '';
                    final timestamp = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : null;
                    final authorImage = data['authorImage'] ?? '';

                    final role = data['role'] ?? 'Staff';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: authorImage.isNotEmpty ? NetworkImage(authorImage) : null,
                          child: authorImage.isEmpty ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          authorName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            role,
                                            style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(text, style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              if (timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, top: 4),
                                  child: Text(
                                    timeago.format(timestamp),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Footer Message
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'As a parent, you can view comments but commenting is reserved for school staff.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
