import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/video_player_widget.dart';

class FullScreenMediaViewer extends StatelessWidget {
  final String url;
  final String type; // 'image' or 'video'

  const FullScreenMediaViewer({
    super.key,
    required this.url,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: type == 'video'
            ? VideoPlayerWidget(videoUrl: url)
            : InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
                ),
              ),
      ),
    );
  }
}
