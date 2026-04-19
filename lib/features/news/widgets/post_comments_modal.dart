import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../kids/providers/kids_provider.dart';
import '../../auth/providers/auth_provider.dart';

class PostCommentsModal extends ConsumerStatefulWidget {
  final String schoolId;
  final String postId;

  const PostCommentsModal({
    super.key,
    required this.schoolId,
    required this.postId,
  });

  @override
  ConsumerState<PostCommentsModal> createState() => _PostCommentsModalState();
}

class _PostCommentsModalState extends ConsumerState<PostCommentsModal> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmitting = false;
  
  String? _replyingToCommentId;
  String? _replyingToName;
  final Map<String, bool> _showReplies = {};

  bool _isEditing = false;
  String? _editingCommentId;
  String? _editingReplyParentId;

  late final Stream<QuerySnapshot> _commentsStream;
  final Map<String, Stream<QuerySnapshot>> _replyStreams = {};

  @override
  void initState() {
    super.initState();
    _commentsStream = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getReplyStream(String commentId) {
    if (!_replyStreams.containsKey(commentId)) {
      _replyStreams[commentId] = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .orderBy('timestamp', descending: false)
          .snapshots();
    }
    return _replyStreams[commentId]!;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(userProvider);
      final parentDataAsync = ref.read(parentDataProvider);
      final kidsAsync = ref.read(kidsProvider);

      if (user == null || parentDataAsync.value == null) throw Exception("User not logged in");

      final parentData = parentDataAsync.value!;
      final kidsList = kidsAsync.value ?? [];

      KidData? selectedKid;
      if (kidsList.isNotEmpty) {
        selectedKid = kidsList.reduce((curr, next) {
          int getLevel(String className) {
            String lower = className.toLowerCase();
            if (lower.contains('play') || lower.contains('pg')) return 0;
            if (lower.contains('pre') || lower.contains('pn')) return 1;
            if (lower.contains('nursery') || lower.contains('nur')) return 2;
            if (lower.contains('kg') || lower.contains('prep')) return 3;
            final match = RegExp(r'\d+').firstMatch(lower);
            if (match != null) {
              return int.parse(match.group(0)!) + 10;
            }
            return 99; 
          }
          return getLevel(curr.className) <= getLevel(next.className) ? curr : next;
        });
      }

      String dynamicRole = 'Parent';
      String dynamicAuthorName = parentData.name;
      String? dynamicStudentContext;

      if (selectedKid != null) {
        if (selectedKid.name.isNotEmpty) {
            dynamicStudentContext = "${selectedKid.name}'s Parent";
        }
        if (selectedKid.className.isNotEmpty && selectedKid.className.toLowerCase() != 'n/a') {
            dynamicRole = selectedKid.className;
        }
      }

      final commentData = {
        'text': text,
        'authorId': user.uid,
        'authorName': dynamicAuthorName,
        'studentContext': dynamicStudentContext,
        'authorImage': user.photoURL ?? "",
        'role': dynamicRole,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
      };

      final postRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('posts')
          .doc(widget.postId);

      if (_isEditing && _editingCommentId != null) {
        if (_editingReplyParentId != null) {
          await postRef
            .collection('comments')
            .doc(_editingReplyParentId)
            .collection('replies')
            .doc(_editingCommentId)
            .update({'text': text});
        } else {
          await postRef
            .collection('comments')
            .doc(_editingCommentId)
            .update({'text': text});
        }
        setState(() {
          _isEditing = false;
          _editingCommentId = null;
          _editingReplyParentId = null;
        });
      } else if (_replyingToCommentId != null) {
        // Write to replies subcollection
        await postRef
            .collection('comments')
            .doc(_replyingToCommentId)
            .collection('replies')
            .add(commentData);
            
        // Increment reply count on parent comment
        await postRef.collection('comments').doc(_replyingToCommentId).update({
          'replyCount': FieldValue.increment(1)
        });
        
        setState(() {
          // Auto-expand replies to see what you just posted
          _showReplies[_replyingToCommentId!] = true;
          _replyingToCommentId = null;
          _replyingToName = null;
        });
      } else {
        // Write top-level comment
        await postRef.collection('comments').add(commentData);
        // Increment comment count on the post
        await postRef.update({
          'commentCount': FieldValue.increment(1)
        });
      }

      _commentController.clear();
      // Dismiss keyboard
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error posting comment: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showCommentOptions(BuildContext context, String commentId, Map<String, dynamic> data, {String? parentCommentId}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Comment'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isEditing = true;
                    _editingCommentId = commentId;
                    _editingReplyParentId = parentCommentId;
                    _commentController.text = data['text'] ?? '';
                    _replyingToCommentId = null;
                    _replyingToName = null;
                  });
                  _commentFocusNode.requestFocus();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Comment', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  bool confirm = await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text("Delete Comment"),
                      content: const Text("Are you sure you want to delete this comment?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ) ?? false;

                  if (confirm) {
                    _deleteComment(commentId, parentCommentId: parentCommentId);
                  }
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _deleteComment(String commentId, {String? parentCommentId}) async {
    final postRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('posts')
        .doc(widget.postId);
        
    try {
      if (parentCommentId != null) {
        await postRef.collection('comments').doc(parentCommentId).collection('replies').doc(commentId).delete();
        await postRef.collection('comments').doc(parentCommentId).update({
          'replyCount': FieldValue.increment(-1)
        });
      } else {
        await postRef.collection('comments').doc(commentId).delete();
        await postRef.update({
          'commentCount': FieldValue.increment(-1)
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting comment: $e")));
      }
    }
  }

  Future<void> _toggleCommentLike(String commentId, List<String> currentLikes) async {
    final user = ref.read(userProvider);
    if (user == null) return;
    
    final isLiked = currentLikes.contains(user.uid);
    final commentRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);
        
    try {
      if (isLiked) {
        await commentRef.update({'likes': FieldValue.arrayRemove([user.uid])});
      } else {
        await commentRef.update({'likes': FieldValue.arrayUnion([user.uid])});
      }
    } catch (e) {
      print("Error liking comment: $e");
    }
  }

  Widget _buildRepliesList(String commentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getReplyStream(commentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.only(top: 8), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)));
        final replies = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: replies.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final time = data['timestamp'] as Timestamp?;
            final tString = time != null ? timeago.format(time.toDate()) : 'Now';
            
            return Padding(
               padding: const EdgeInsets.only(top: 6),
               child: GestureDetector(
                 onLongPress: () {
                   final user = ref.read(userProvider);
                   if (user != null && data['authorId'] == user.uid) {
                     _showCommentOptions(context, doc.id, data, parentCommentId: commentId);
                   }
                 },
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        backgroundImage: data['authorImage'] != null && data['authorImage'].isNotEmpty ? NetworkImage(data['authorImage']) : null,
                        child: (data['authorImage'] == null || data['authorImage'].isEmpty) ? Icon(Icons.school, size: 14, color: Colors.blue[600]) : null,
                     ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                             decoration: BoxDecoration(
                               color: Colors.grey.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Text(data['authorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  if (data['studentContext'] != null || data['role'] != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (data['studentContext'] != null) ...[
                                          Flexible(
                                            child: Text(data['studentContext'], style: TextStyle(fontSize: 10, color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        if (data['role'] != null)
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                data['role'],
                                                style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(data['text'] ?? '', style: const TextStyle(fontSize: 13)),
                               ]
                             )
                           ),
                           Padding(
                             padding: const EdgeInsets.only(left: 4, top: 4),
                             child: Text(tString, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                           )
                        ]
                      )
                    )
                   ]
                 ),
               )
            );
          }).toList(),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),

          // Comments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _commentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                final comments = snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      "No comments yet. Be the first to comment!",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeString = timestamp != null ? timeago.format(timestamp.toDate()) : 'Just now';
                    
                    final likesList = List<String>.from(data['likes'] ?? []);
                    final isLiked = user != null && likesList.contains(user.uid);
                    final replyCount = data['replyCount'] ?? 0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onLongPress: () {
                          if (user != null && data['authorId'] == user.uid) {
                            _showCommentOptions(context, comments[index].id, data);
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            backgroundImage: data['authorImage'] != null && data['authorImage'].isNotEmpty
                                ? NetworkImage(data['authorImage'])
                                : null,
                            child: (data['authorImage'] == null || data['authorImage'].isEmpty)
                                ? Icon(Icons.school, color: Colors.blue[600], size: 20)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['authorName'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      if (data['studentContext'] != null || data['role'] != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (data['studentContext'] != null) ...[
                                              Flexible(
                                                child: Text(data['studentContext'], style: TextStyle(fontSize: 11, color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            if (data['role'] != null)
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    data['role'],
                                                    style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        data['text'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 4),
                                  child: Row(
                                    children: [
                                      Text(timeString, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: () => _toggleCommentLike(comments[index].id, likesList),
                                        child: Text("Like", style: TextStyle(
                                            color: isLiked ? Colors.blue : Colors.grey[600], 
                                            fontWeight: isLiked ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 12
                                        )),
                                      ),
                                      if (likesList.isNotEmpty) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.thumb_up, size: 12, color: Colors.blue),
                                        const SizedBox(width: 2),
                                        Text("${likesList.length}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      ],
                                    ]
                                  ),
                                ),
                                if (replyCount > 0)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showReplies[comments[index].id] = !(_showReplies[comments[index].id] ?? false);
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8, left: 12),
                                      child: Text(
                                        (_showReplies[comments[index].id] ?? false) ? "Hide replies" : "View $replyCount replies",
                                        style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                
                                if (_showReplies[comments[index].id] ?? false)
                                   _buildRepliesList(comments[index].id),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Comment Input
          SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_replyingToName != null || _isEditing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.withOpacity(0.1),
                    child: Row(
                      children: [
                        Text(_isEditing ? "Editing comment " : "Replying to ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        if (!_isEditing)
                          Text("$_replyingToName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() {
                            _replyingToCommentId = null;
                            _replyingToName = null;
                            _isEditing = false;
                            _editingCommentId = null;
                            _editingReplyParentId = null;
                            _commentController.clear();
                          }),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        )
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Write a comment...",
                            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _commentController,
                        builder: (context, value, child) {
                          final hasText = value.text.trim().isNotEmpty;
                          return IconButton(
                            onPressed: (hasText && !_isSubmitting)
                                ? _submitComment
                                : null,
                            icon: _isSubmitting 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(
                                    Icons.send,
                                    color: hasText ? Colors.blue : Colors.grey,
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
