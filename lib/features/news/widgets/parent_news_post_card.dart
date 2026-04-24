import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

import '../providers/news_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import 'post_comments_modal.dart';
import '../../../core/widgets/video_player_widget.dart';
import 'likers_dialog.dart';

// Copy the ReactionPopup exactly from teacher app
class _ReactionPopup extends StatefulWidget {
  final ValueNotifier<int> hoverNotifier;
  final List<GlobalKey> emojiKeys;

  const _ReactionPopup({
    required this.hoverNotifier,
    required this.emojiKeys,
  });

  @override
  State<_ReactionPopup> createState() => _ReactionPopupState();
}

class _ReactionPopupState extends State<_ReactionPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _emojiChars = ['👍', '❤️', '😂', '😮'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: widget.hoverNotifier,
          builder: (context, hoverIndex, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                final isHovered = hoverIndex == i;
                return Row(
                  children: [
                    if (i > 0) const SizedBox(width: 16),
                    AnimatedScale(
                      scale: isHovered ? 1.5 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.only(bottom: isHovered ? 10 : 0),
                        child: Container(
                          key: widget.emojiKeys[i],
                          child: Text(_emojiChars[i], style: TextStyle(fontSize: 28, color: i == 1 ? Colors.red : null)),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class ParentNewsPostCard extends ConsumerStatefulWidget {
  final NewsPost post;

  const ParentNewsPostCard({super.key, required this.post});

  @override
  ConsumerState<ParentNewsPostCard> createState() => _ParentNewsPostCardState();
}

class _ParentNewsPostCardState extends ConsumerState<ParentNewsPostCard> {
  OverlayEntry? _overlayEntry;
  final ValueNotifier<int> _hoverIndexNotifier = ValueNotifier(-1);
  final List<GlobalKey> _emojiKeys = List.generate(4, (_) => GlobalKey());
  bool _isExpanded = false;

  static const List<List<Color>> _backgroundGradients = [
    [], // Default
    [Color(0xFFFF5F6D), Color(0xFFFFC371)], // Sunset
    [Color(0xFF2193b0), Color(0xFF6dd5ed)], // Ocean
    [Color(0xFFcc2b5e), Color(0xFF753a88)], // Purple Love
    [Color(0xFF00B4DB), Color(0xFF0083B0)], // Blue Raspberry
    [Color(0xFFf12711), Color(0xFFf5af19)], // Flare
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Frost
  ];

  @override
  void dispose() {
    _hideReactions();
    super.dispose();
  }

  void _showReactions(BuildContext context) {
    if (_overlayEntry != null) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    _hoverIndexNotifier.value = -1;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideReactions,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy - 60, // Above the button
            child: Material(
              color: Colors.transparent,
              child: _ReactionPopup(
                hoverNotifier: _hoverIndexNotifier,
                emojiKeys: _emojiKeys,
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideReactions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateHover(Offset globalPos) {
    int newHover = -1;
    for (int i = 0; i < _emojiKeys.length; i++) {
       final key = _emojiKeys[i];
       if (key.currentContext != null) {
          final box = key.currentContext!.findRenderObject() as RenderBox;
          final pos = box.localToGlobal(Offset.zero);
          final size = box.size;
          final rect = Rect.fromLTWH(pos.dx - 20, pos.dy - 60, size.width + 40, size.height + 120);
          if (rect.contains(globalPos)) {
             newHover = i;
             break;
          }
       }
    }
    if (_hoverIndexNotifier.value != newHover) {
       _hoverIndexNotifier.value = newHover;
    }
  }

  Future<void> _updateReaction(String type, String schoolId, String uid) async {
    await toggleReaction(schoolId, widget.post.id, uid, type);
  }

  Future<void> _removeReaction(String schoolId, String uid) async {
    await toggleReaction(schoolId, widget.post.id, uid, 'none');
  }

  Widget _getReactionIcon(String type) {
    if (type == 'heart') return const Text('❤️', style: TextStyle(fontSize: 18));
    if (type == 'haha') return const Text('😂', style: TextStyle(fontSize: 18));
    if (type == 'wow') return const Text('😮', style: TextStyle(fontSize: 18));
    if (type == 'like') return const Icon(Icons.thumb_up, color: Colors.blue, size: 18);
    return Icon(Icons.thumb_up_outlined, color: Colors.grey[700], size: 20);
  }

  String _getReactionText(String type) {
    if (type == 'heart') return 'Love';
    if (type == 'haha') return 'Haha';
    if (type == 'wow') return 'Wow';
    if (type == 'like') return 'Like';
    return 'Like';
  }

  Color _getReactionColor(String type) {
    if (type == 'heart') return Colors.red;
    if (type == 'haha') return Colors.orange;
    if (type == 'wow') return Colors.amber;
    if (type == 'like') return Colors.blue;
    return Colors.grey[700] ?? Colors.grey;
  }

  void _openFullScreenViewer(BuildContext context, List<Map<String, dynamic>> media, int initialIndex) {
      final PageController controller = PageController(initialPage: initialIndex);
      showDialog(
          context: context, 
          builder: (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Stack(
                children: [
                    PageView.builder(
                        controller: controller,
                        itemCount: media.length,
                        itemBuilder: (context, index) {
                            final m = media[index];
                            if (m['type'] == 'video') {
                                return Center(child: VideoPlayerWidget(videoUrl: m['url']));
                            }
                            return InteractiveViewer(
                                child: CachedNetworkImage(imageUrl: m['url']),
                            );
                        }
                    ),
                    Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context)
                        )
                    )
                ]
            )
      ));
  }

  Widget _buildMediaItem(Map<String, dynamic> mediaList, List<Map<String, dynamic>> fullList, {BoxFit fit = BoxFit.cover}) {
    final type = mediaList['type'] ?? 'image';
    final url = mediaList['url'];
    if (url == null || url.isEmpty) return const SizedBox();

    Widget child;
    if (type == 'video') {
      child = Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          const Center(child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white70)),
        ],
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (context, url) => Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator())),
        errorWidget: (context, url, error) => const SizedBox(),
      );
    }

    return GestureDetector(
      onTap: () {
         _openFullScreenViewer(context, fullList, fullList.indexOf(mediaList));
      },
      child: child,
    );
  }

  Widget _buildMediaCollage(List<Map<String, dynamic>> media, BuildContext context) {
    if (media.length == 1) {
      if (media.first['type'] == 'video') {
         return Center(child: VideoPlayerWidget(videoUrl: media.first['url']));
      }
      return SizedBox(
        width: double.infinity,
        child: _buildMediaItem(media.first, media)
      );
    }
    
    if (media.length == 2) {
      return SizedBox(
        height: 300,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildMediaItem(media[0], media)),
            const SizedBox(width: 2),
            Expanded(child: _buildMediaItem(media[1], media)),
          ],
        )
      );
    }

    if (media.length == 3) {
      return SizedBox(
        height: 300,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: _buildMediaItem(media[0], media)),
            const SizedBox(width: 2),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildMediaItem(media[1], media)),
                  const SizedBox(height: 2),
                  Expanded(child: _buildMediaItem(media[2], media)),
                ]
              )
            )
          ],
        )
      );
    }
    
    if (media.length == 4) {
      return SizedBox(
        height: 300,
        child: Column(
          children: [
            Expanded(child: _buildMediaItem(media[0], media)),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(media[1], media)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildMediaItem(media[2], media)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildMediaItem(media[3], media)),
                ]
              )
            )
          ]
        )
      );
    }

    // 5 or more
    return SizedBox(
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _buildMediaItem(media[0], media)),
          const SizedBox(height: 2),
          Expanded(
            flex: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildMediaItem(media[1], media)),
                const SizedBox(width: 2),
                Expanded(child: _buildMediaItem(media[2], media)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaItem(media[3], media),
                      if (media.length > 4)
                        GestureDetector(
                          onTap: () => _openFullScreenViewer(context, media, 3),
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                "+${media.length - 4}",
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                              ),
                            )
                          ),
                        )
                    ],
                  )
                ),
              ]
            )
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentDataAsync = ref.watch(parentDataProvider);
    final parentData = parentDataAsync.value;
    final post = widget.post;

    String currentReaction = 'none';
    if (parentData != null) {
      if (post.reactions.containsKey(parentData.uid)) {
        currentReaction = post.reactions[parentData.uid];
      } else if (post.likes.contains(parentData.uid)) {
        currentReaction = 'like';
      }
    }

    final Set<String> totalReactors = {...post.likes, ...post.reactions.keys};
    final int combinedLikeCount = totalReactors.length;
    final bool hasHearts = post.reactions.values.contains('heart');
    final bool hasHahas = post.reactions.values.contains('haha');
    final bool hasWows = post.reactions.values.contains('wow');

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
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
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
                          Expanded(
                            child: Text(
                              post.authorName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87, letterSpacing: -0.1),
                              overflow: TextOverflow.ellipsis,
                            ),
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
            if (post.backgroundIndex != 0 && post.backgroundIndex < _backgroundGradients.length && post.content.length <= 130)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _backgroundGradients[post.backgroundIndex]),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  post.content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: post.content.length < 85 ? 28 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (post.content.length > 200 && !_isExpanded) ? '${post.content.substring(0, 200)}...' : post.content,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                    if (post.content.length > 200)
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Padding(
                           padding: const EdgeInsets.only(top: 4.0),
                           child: Text(_isExpanded ? 'See less' : 'See more', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        )
                      )
                  ],
                ),
              ),
          const SizedBox(height: 8),

          // Post Media Attachment
          if (post.media.isNotEmpty)
            _buildMediaCollage(post.media, context),

          // Stats Row
          if (combinedLikeCount > 0 || post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (combinedLikeCount > 0)
                    GestureDetector(
                      onTap: () {
                         final allLikers = totalReactors.toList();
                         if (allLikers.isNotEmpty && parentData != null) {
                            showDialog(
                               context: context,
                               builder: (_) => LikersDialog(uids: allLikers, schoolId: parentData.schoolId)
                            );
                         }
                      },
                      child: Row(
                        children: [
                          if (hasHearts) const Text('❤️', style: TextStyle(fontSize: 12, color: Colors.red)),
                          if (hasHahas) const Text('😂', style: TextStyle(fontSize: 12)),
                          if (hasWows) const Text('😮', style: TextStyle(fontSize: 12)),
                          if (!hasHearts && !hasHahas && !hasWows)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.thumb_up, size: 10, color: Colors.white),
                            ),
                          const SizedBox(width: 6),
                          Text('$combinedLikeCount', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(width: 8),
                          Text("View", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
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
                  child: Builder(
                    builder: (btnContext) {
                      return GestureDetector(
                        onLongPressStart: (_) => _showReactions(btnContext),
                        onLongPressMoveUpdate: (details) => _updateHover(details.globalPosition),
                        onLongPressEnd: (_) {
                          if (parentData == null) return;
                          final emojis = ['like', 'heart', 'haha', 'wow'];
                          if (_hoverIndexNotifier.value != -1) {
                            final selected = emojis[_hoverIndexNotifier.value];
                            _updateReaction(selected, parentData.schoolId, parentData.uid);
                          }
                          _hideReactions();
                        },
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: _getReactionColor(currentReaction),
                          ),
                          icon: _getReactionIcon(currentReaction),
                          label: Text(_getReactionText(currentReaction), style: const TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            if (parentData != null) {
                              if (currentReaction == 'none') {
                                _updateReaction('like', parentData.schoolId, parentData.uid);
                              } else {
                                _removeReaction(parentData.schoolId, parentData.uid);
                              }
                            }
                          },
                        ),
                      );
                    }
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
  }
}
