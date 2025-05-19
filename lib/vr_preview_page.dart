import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VRPreviewPage extends StatefulWidget {
  final String videoUrl;

  const VRPreviewPage({super.key, required this.videoUrl});

  @override
  _VRPreviewPageState createState() => _VRPreviewPageState();
}

class _VRPreviewPageState extends State<VRPreviewPage> {
  late VideoPlayerController _videoController;
  late YoutubePlayerController _youtubeController;
  bool isYouTubeVideo = false;

  @override
  void initState() {
    super.initState();

    if (widget.videoUrl.contains("youtube.com") ||
        widget.videoUrl.contains("youtu.be")) {
      // Initialize YoutubePlayerController for YouTube videos
      isYouTubeVideo = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '',
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    } else {
      // Initialize VideoPlayerController for non-YouTube videos
      _videoController = VideoPlayerController.network(widget.videoUrl)
        ..initialize().then((_) {
          setState(() {});
          _videoController.play();
        });
    }
  }

  @override
  void dispose() {
    if (isYouTubeVideo) {
      _youtubeController.dispose();
    } else {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: isYouTubeVideo
                ? YoutubePlayerBuilder(
                    player: YoutubePlayer(
                      controller: _youtubeController,
                      showVideoProgressIndicator: true,
                    ),
                    builder: (context, player) {
                      return SizedBox.expand(
                        child: player,
                      );
                    },
                  )
                : _videoController.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      )
                    : const Center(child: CircularProgressIndicator()),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isYouTubeVideo
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _videoController.value.isPlaying
                      ? _videoController.pause()
                      : _videoController.play();
                });
              },
              child: Icon(
                _videoController.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            ),
    );
  }
}
