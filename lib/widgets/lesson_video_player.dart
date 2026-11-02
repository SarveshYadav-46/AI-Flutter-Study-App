import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../utils/youtube_utils.dart';

/// Embedded YouTube player widget for lesson screens.
///
/// Handles:
/// - Lessons without video: shows friendly "Video coming soon." placeholder.
/// - Lessons with invalid video URL: shows error state.
/// - Lessons with valid YouTube URL / ID: embeds the official YouTube player.
/// - Dynamic video updates when navigating between lessons.
/// - Safe test environment detection so unit/widget tests run without native WebView bindings.
class LessonVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? lessonTitle;
  final bool? isTestMode;

  const LessonVideoPlayer({
    super.key,
    required this.videoUrl,
    this.lessonTitle,
    this.isTestMode,
  });

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  YoutubePlayerController? _controller;
  String? _currentVideoId;
  String? _playerErrorMessage;
  bool _isLoading = true;
  StreamSubscription? _playerSub;

  /// Returns true in widget test environments where WebView platform channels are not active.
  bool get _isTestMode =>
      widget.isTestMode ??
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  @override
  void didUpdateWidget(LessonVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _setupPlayer();
    }
  }

  void _setupPlayer() {
    final videoId = YouTubeUtils.extractVideoId(widget.videoUrl);

    if (videoId == _currentVideoId && _controller != null) {
      return;
    }

    _playerSub?.cancel();
    _controller?.close();
    _controller = null;
    _currentVideoId = videoId;
    _playerErrorMessage = null;
    _isLoading = true;

    if (videoId == null || _isTestMode) {
      _isLoading = false;
      return;
    }

    try {
      final ctrl = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          enableCaption: true,
        ),
      );

      _playerSub = ctrl.stream.listen((value) {
        if (!mounted) return;
        if (value.hasError) {
          setState(() {
            _playerErrorMessage = 'Video playback error: ${value.error.name}';
            _isLoading = false;
          });
        } else if (value.playerState == PlayerState.playing ||
            value.playerState == PlayerState.paused ||
            value.playerState == PlayerState.cued) {
          if (_isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      });

      _controller = ctrl;
      _isLoading = false;
    } catch (e) {
      _playerErrorMessage = 'Could not initialize video player: $e';
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.black,
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 1. No video URL provided
    if (widget.videoUrl == null || widget.videoUrl!.trim().isEmpty) {
      return _buildPlaceholder(
        icon: Icons.video_library_outlined,
        title: 'Video coming soon.',
        subtitle: 'This lesson currently focuses on written notes and exercises.',
        iconColor: Colors.white70,
      );
    }

    // 2. Invalid YouTube URL / unparseable video ID
    if (_currentVideoId == null) {
      return _buildPlaceholder(
        icon: Icons.error_outline,
        title: 'Unable to load video',
        subtitle: 'The provided link is not a supported YouTube URL.',
        iconColor: Theme.of(context).colorScheme.error,
      );
    }

    // 3. Player error state
    if (_playerErrorMessage != null) {
      return _buildPlaceholder(
        icon: Icons.warning_amber_rounded,
        title: 'Video Unavailable',
        subtitle: _playerErrorMessage!,
        iconColor: Theme.of(context).colorScheme.error,
      );
    }

    // 4. Test environment (mock player presentation)
    if (_isTestMode) {
      return Container(
        key: const Key('youtube_player_mock'),
        color: Colors.black87,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.red, size: 56),
            const SizedBox(height: 8),
            Text(
              'YouTube Player: $_currentVideoId',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.lessonTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.lessonTitle!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      );
    }

    // 5. Real device YouTube Player
    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        YoutubePlayer(
          key: Key('youtube_player_$_currentVideoId'),
          controller: controller,
          aspectRatio: 16 / 9,
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
