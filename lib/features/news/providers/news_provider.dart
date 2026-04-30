import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../kids/providers/kids_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsPost {
  final String id;
  final String content;
  final String type;
  final String targetClassName;
  final String audience;
  final String authorName;
  final String role;
  final String authorImage;
  final String attachmentUrl;
  final String attachmentType;
  final List<Map<String, dynamic>> media;
  final DateTime? timestamp;
  final List<String> likes;
  final int commentCount;
  final int backgroundIndex;
  final Map<String, dynamic> reactions;

  NewsPost({
    required this.id,
    required this.content,
    required this.type,
    required this.targetClassName,
    required this.audience,
    required this.authorName,
    required this.role,
    required this.authorImage,
    required this.attachmentUrl,
    required this.attachmentType,
    required this.media,
    this.timestamp,
    required this.likes,
    required this.commentCount,
    this.backgroundIndex = 0,
    required this.reactions,
  });

  factory NewsPost.fromMap(Map<String, dynamic> map, String id) {
    // Detect video from URL
    String attachmentUrl = map['attachmentUrl'] ?? map['imageUrl'] ?? map['mediaUrl'] ?? '';
    String attachmentType = map['attachmentType'] ?? map['mediaType'] ?? '';
    if (attachmentType.isEmpty && attachmentUrl.isNotEmpty) {
      attachmentType = attachmentUrl.contains('.mp4') ? 'video' : 'image';
    }

    List<Map<String, dynamic>> mediaList = [];
    if (map['media'] != null) {
        for(var m in (map['media'] as List<dynamic>? ?? [])) {
            mediaList.add(m as Map<String, dynamic>? ?? <String, dynamic>{});
        }
    } else if (attachmentUrl.isNotEmpty) {
        mediaList.add({
           'url': attachmentUrl,
           'type': attachmentType
        });
    }

    return NewsPost(
      id: id,
      content: map['content'] ?? map['text'] ?? '',
      type: map['type'] ?? 'announcement',
      targetClassName: map['targetClassName'] ?? '',
      audience: map['audience'] ?? 'all',
      authorName: map['authorName'] ?? 'School Admin',
      role: map['role'] ?? 'Admin',
      authorImage: map['authorImage'] ?? '',
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      media: mediaList,
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate() 
          : (map['timestamp'] != null ? DateTime.tryParse(map['timestamp'].toString()) : null),
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      backgroundIndex: map['backgroundIndex'] ?? 0,
      reactions: map['reactions'] is Map 
          ? Map<String, dynamic>.from(map['reactions'] as Map) 
          : <String, dynamic>{},
    );
  }
}

Future<void> toggleReaction(String schoolId, String postId, String userId, String reactionType) async {
  final postRef = FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('posts').doc(postId);
  
  if (reactionType == 'none') {
    await postRef.update({
      'reactions.$userId': FieldValue.delete()
    });
  } else {
    // Also remove from legacy likes array to prevent duplication issues
    await postRef.update({
      'reactions.$userId': reactionType,
      'likes': FieldValue.arrayRemove([userId])
    });
  }
}

Future<void> toggleLike(String schoolId, String postId, String userId, bool isLiked) async {
  final postRef = FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('posts').doc(postId);
  if (isLiked) {
    await postRef.update({
      'likes': FieldValue.arrayRemove([userId])
    });
  } else {
    await postRef.update({
      'likes': FieldValue.arrayUnion([userId])
    });
  }
}

Future<void> deletePost(String schoolId, String postId) async {
  await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('posts').doc(postId).delete();
}

final hiddenPostsProvider = StateNotifierProvider<HiddenPostsNotifier, List<String>>((ref) {
  return HiddenPostsNotifier();
});

class HiddenPostsNotifier extends StateNotifier<List<String>> {
  HiddenPostsNotifier() : super([]) {
    _loadHiddenPosts();
  }

  Future<void> _loadHiddenPosts() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('hidden_news_posts') ?? [];
  }

  Future<void> hidePost(String postId) async {
    if (!state.contains(postId)) {
      final newState = [...state, postId];
      state = newState;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hidden_news_posts', newState);
    }
  }
}

final newsProvider = FutureProvider<List<NewsPost>>((ref) async {
  final parentDataAsync = ref.watch(parentDataProvider);
  final kidsAsync = ref.watch(kidsProvider);
  final hiddenPosts = ref.watch(hiddenPostsProvider);

  if (parentDataAsync.value == null || kidsAsync.value == null) {
    return [];
  }

  final schoolId = parentDataAsync.value!.schoolId;
  final kidsClasses = kidsAsync.value!.map((k) => k.className).toSet();

  if (schoolId.isEmpty) {
    return [];
  }

  final snapshot = await FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('posts')
      .orderBy('timestamp', descending: true)
      .get();

  final allPosts = snapshot.docs.map((doc) => NewsPost.fromMap(doc.data(), doc.id)).toList();
  
  // Filter by audience
  final filteredPosts = allPosts.where((post) {
    if (hiddenPosts.contains(post.id)) return false;

    if (post.audience == 'all' || post.audience.isEmpty) return true;
    if (post.audience == 'class') {
      return kidsClasses.contains(post.targetClassName);
    }
    return false;
  }).toList();

  return filteredPosts;
});
