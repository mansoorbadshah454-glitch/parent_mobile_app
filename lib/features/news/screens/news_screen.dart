import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/news_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../widgets/post_comments_modal.dart';
import '../../../core/widgets/video_player_widget.dart';
import '../widgets/full_screen_media_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsyncValue = ref.watch(newsProvider);
    final parentDataAsync = ref.watch(parentDataProvider);

    final parentData = parentDataAsync.value;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: newsAsyncValue.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final post = posts[index];
              final isLiked = parentData != null && post.likes.contains(parentData.uid);

              return Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Header
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            backgroundImage: post.authorImage.isNotEmpty ? NetworkImage(post.authorImage) : null,
                            child: post.authorImage.isEmpty ? const Icon(Icons.school, color: Colors.blueAccent) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      post.authorName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (post.audience == 'class') ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.play_arrow, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        post.targetClassName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                                      )
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      post.role,
                                      style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('•', style: TextStyle(color: Colors.grey)),
                                    const SizedBox(width: 4),
                                    if (post.timestamp != null)
                                      Text(
                                        timeago.format(post.timestamp!),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.public, size: 12, color: Colors.grey[600]),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            icon: const Icon(Icons.more_horiz, color: Colors.grey),
                            onSelected: (value) async {
                              if (value == 'save') {
                                if (post.attachmentUrl.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Downloading media...')),
                                  );
                                  FileDownloader.downloadFile(
                                    url: post.attachmentUrl,
                                    name: 'school_media_${post.id}.${post.attachmentType == 'video' ? 'mp4' : 'jpg'}',
                                    onDownloadCompleted: (String path) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Saved to $path')),
                                      );
                                    },
                                    onDownloadError: (String error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Error saving media')),
                                      );
                                    },
                                  );
                                }
                              } else if (value == 'delete') {
                                ref.read(hiddenPostsProvider.notifier).hidePost(post.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Post removed from your feed')),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              if (post.attachmentUrl.isNotEmpty)
                                const PopupMenuItem(
                                  value: 'save',
                                  child: Row(
                                    children: [Icon(Icons.download, size: 20), SizedBox(width: 8), Text('Save Media')],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [Icon(Icons.visibility_off, size: 20, color: Colors.grey), SizedBox(width: 8), Text('Hide Post', style: TextStyle(color: Colors.grey))],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Post Text Content
                    if (post.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          post.content,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Post Media Attachment
                    if (post.attachmentUrl.isNotEmpty) ...[
                      if (post.attachmentType == 'video')
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => FullScreenMediaViewer(url: post.attachmentUrl, type: 'video')
                            ));
                          },
                          behavior: HitTestBehavior.translucent,
                          child: IgnorePointer(
                            child: VideoPlayerWidget(videoUrl: post.attachmentUrl),
                          ),
                        )
                      else if (post.attachmentType == 'image')
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => FullScreenMediaViewer(url: post.attachmentUrl, type: 'image')
                            ));
                          },
                          child: CachedNetworkImage(
                            imageUrl: post.attachmentUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 250,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.grey[100],
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Attachment: ${post.attachmentType}', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                    ],

                    // Stats Row (Like Count, Comment Count)
                    if (post.likes.isNotEmpty || post.commentCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (post.likes.isNotEmpty)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                    child: const Icon(Icons.thumb_up, size: 10, color: Colors.white),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('${post.likes.length}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              )
                            else
                              const SizedBox.shrink(),
                              
                            if (post.commentCount > 0)
                              Text('${post.commentCount} comments', style: TextStyle(color: Colors.grey[600], fontSize: 13))
                          ],
                        ),
                      ),
                      
                    const Divider(height: 1, thickness: 1),

                    // Actions Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: isLiked ? Colors.blue : Colors.grey[700],
                              ),
                              icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20),
                              label: const Text('Like', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (parentData != null) {
                                  toggleLike(parentData.schoolId, post.id, parentData.uid, isLiked);
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                              icon: const Icon(Icons.chat_bubble_outline, size: 20),
                              label: const Text('Comment', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (parentData != null) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useRootNavigator: false,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => FractionallySizedBox(
                                      heightFactor: 0.8,
                                      child: PostCommentsModal(
                                        schoolId: parentData.schoolId,
                                        postId: post.id,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error loading feed: $error')),
      ),
    );
  }
}
