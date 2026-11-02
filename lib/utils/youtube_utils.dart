/// Utility functions for validating and extracting video IDs from YouTube URLs.
class YouTubeUtils {
  static final RegExp _videoIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  static final List<RegExp> _urlPatterns = [
    // Standard watch URL: youtube.com/watch?v=ID or /watch?feature=...&v=ID
    RegExp(
      r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?(?:.*&)?v=([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    ),
    // Short URL: youtu.be/ID
    RegExp(
      r'(?:https?:\/\/)?youtu\.be\/([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    ),
    // Shorts: youtube.com/shorts/ID
    RegExp(
      r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    ),
    // Embed: youtube.com/embed/ID
    RegExp(
      r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    ),
    // Live: youtube.com/live/ID
    RegExp(
      r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/live\/([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    ),
    // Mobile: m.youtube.com/watch?v=ID
    RegExp(
      r'(?:https?:\/\/)?m\.youtube\.com\/watch\?(?:.*&)?v=([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    ),
  ];

  /// Extracts the 11-character YouTube video ID from a URL, or returns null if invalid.
  ///
  /// Supported formats:
  /// - `https://www.youtube.com/watch?v=VIDEO_ID`
  /// - `https://youtube.com/watch?v=VIDEO_ID&t=10s`
  /// - `https://youtu.be/VIDEO_ID`
  /// - `https://youtu.be/VIDEO_ID?t=10s`
  /// - `https://www.youtube.com/shorts/VIDEO_ID`
  /// - `https://youtube.com/shorts/VIDEO_ID?feature=share`
  /// - `https://www.youtube.com/embed/VIDEO_ID`
  /// - `https://www.youtube.com/live/VIDEO_ID`
  /// - Raw 11-character video ID directly: `VIDEO_ID`
  static String? extractVideoId(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    // Check if raw 11-character video ID
    if (_videoIdRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    // Match against known YouTube URL patterns
    for (final pattern in _urlPatterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null && match.groupCount >= 1) {
        final id = match.group(1);
        if (id != null && _videoIdRegex.hasMatch(id)) {
          return id;
        }
      }
    }

    return null;
  }

  /// Returns true if [url] contains a valid YouTube video ID or URL.
  static bool isValidYouTubeUrl(String? url) {
    return extractVideoId(url) != null;
  }
}
