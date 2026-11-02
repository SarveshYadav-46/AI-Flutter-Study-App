import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minerproject/models/models.dart';
import 'package:minerproject/screens/lesson_screen.dart';
import 'package:minerproject/utils/youtube_utils.dart';
import 'package:minerproject/widgets/lesson_video_player.dart';

void main() {
  group('YouTubeUtils URL Parsing Tests', () {
    test('extracts video ID from standard youtube.com/watch?v= URLs', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      expect(YouTubeUtils.extractVideoId(url), equals('dQw4w9WgXcQ'));
      expect(YouTubeUtils.isValidYouTubeUrl(url), isTrue);
    });

    test('extracts video ID from youtube.com with extra query parameters', () {
      const url =
          'https://www.youtube.com/watch?feature=share&v=dQw4w9WgXcQ&t=45s';
      expect(YouTubeUtils.extractVideoId(url), equals('dQw4w9WgXcQ'));
    });

    test('extracts video ID from youtu.be short URLs', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ';
      expect(YouTubeUtils.extractVideoId(url), equals('dQw4w9WgXcQ'));
      expect(YouTubeUtils.isValidYouTubeUrl(url), isTrue);
    });

    test('extracts video ID from youtu.be with timestamp', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ?t=120';
      expect(YouTubeUtils.extractVideoId(url), equals('dQw4w9WgXcQ'));
    });

    test('extracts video ID from YouTube Shorts URLs', () {
      const url = 'https://www.youtube.com/shorts/dQw4w9WgXcQ';
      expect(YouTubeUtils.extractVideoId(url), equals('dQw4w9WgXcQ'));
      expect(YouTubeUtils.isValidYouTubeUrl(url), isTrue);

      const urlWithQuery =
          'https://youtube.com/shorts/dQw4w9WgXcQ?feature=share';
      expect(YouTubeUtils.extractVideoId(urlWithQuery), equals('dQw4w9WgXcQ'));
    });

    test('extracts video ID from embed URLs', () {
      const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
      expect(YouTubeUtils.extractVideoId(url), equals('dQw4w9WgXcQ'));
    });

    test('extracts video ID from live URLs', () {
      const url = 'https://www.youtube.com/live/dQw4w9WgXcQ';
      expect(YouTubeUtils.extractVideoId(url), equals('dQw4w9WgXcQ'));
    });

    test('recognizes raw 11-character video ID', () {
      const rawId = 'dQw4w9WgXcQ';
      expect(YouTubeUtils.extractVideoId(rawId), equals('dQw4w9WgXcQ'));
      expect(YouTubeUtils.isValidYouTubeUrl(rawId), isTrue);
    });

    test('returns null for null, empty, or whitespace URLs', () {
      expect(YouTubeUtils.extractVideoId(null), isNull);
      expect(YouTubeUtils.extractVideoId(''), isNull);
      expect(YouTubeUtils.extractVideoId('   '), isNull);
      expect(YouTubeUtils.isValidYouTubeUrl(null), isFalse);
    });

    test('returns null for non-YouTube or invalid URLs', () {
      expect(YouTubeUtils.extractVideoId('https://vimeo.com/123456789'), isNull);
      expect(YouTubeUtils.extractVideoId('https://google.com'), isNull);
      expect(YouTubeUtils.extractVideoId('not_a_valid_url'), isNull);
      expect(YouTubeUtils.isValidYouTubeUrl('invalid'), isFalse);
    });
  });

  group('Lesson Model videoUrl Compatibility Tests', () {
    test('Lesson without videoUrl defaults to hasVideo = false', () {
      final lesson = Lesson(
        id: 'l_test1',
        courseId: 'c1',
        title: 'Introduction',
        duration: '10 mins',
        module: 'Module 1',
        description: 'Test description',
      );

      expect(lesson.videoUrl, isNull);
      expect(lesson.hasVideo, isFalse);
    });

    test('Lesson with videoUrl reports hasVideo = true', () {
      final lesson = Lesson(
        id: 'l_test2',
        courseId: 'c1',
        title: 'Video Lesson',
        duration: '15 mins',
        module: 'Module 1',
        description: 'Lesson with video',
        videoUrl: 'https://youtu.be/dQw4w9WgXcQ',
      );

      expect(lesson.videoUrl, equals('https://youtu.be/dQw4w9WgXcQ'));
      expect(lesson.hasVideo, isTrue);
    });

    test('Lesson.fromMap parses videoUrl correctly from Firestore map', () {
      final mapWithVideo = {
        'courseId': 'c1',
        'title': 'Map Lesson',
        'duration': '12 mins',
        'module': 'Mod 2',
        'description': 'Desc',
        'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      };
      final lesson = Lesson.fromMap(mapWithVideo, 'l_map1');
      expect(lesson.videoUrl, equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
      expect(lesson.hasVideo, isTrue);

      final mapWithoutVideo = {
        'courseId': 'c1',
        'title': 'Map Lesson No Video',
        'duration': '12 mins',
        'module': 'Mod 2',
        'description': 'Desc',
      };
      final lessonNoVid = Lesson.fromMap(mapWithoutVideo, 'l_map2');
      expect(lessonNoVid.videoUrl, isNull);
      expect(lessonNoVid.hasVideo, isFalse);
    });

    test('Lesson.toMap includes videoUrl when present, preserves null otherwise', () {
      final lesson = Lesson(
        id: 'l_map3',
        courseId: 'c1',
        title: 'Serializing Lesson',
        duration: '15 mins',
        module: 'Mod 3',
        description: 'Desc',
        videoUrl: 'https://youtu.be/dQw4w9WgXcQ',
      );
      final map = lesson.toMap();
      expect(map['videoUrl'], equals('https://youtu.be/dQw4w9WgXcQ'));

      final lessonEmpty = Lesson(
        id: 'l_map4',
        courseId: 'c1',
        title: 'Empty Vid Lesson',
        duration: '15 mins',
        module: 'Mod 3',
        description: 'Desc',
      );
      final mapEmpty = lessonEmpty.toMap();
      expect(mapEmpty.containsKey('videoUrl'), isFalse);
    });
  });

  group('LessonVideoPlayer Widget UI Tests', () {
    testWidgets('displays "Video coming soon." placeholder when videoUrl is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LessonVideoPlayer(
              videoUrl: null,
              lessonTitle: 'Sample Lesson',
            ),
          ),
        ),
      );

      expect(find.text('Video coming soon.'), findsOneWidget);
      expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
    });

    testWidgets('displays "Video coming soon." when videoUrl is empty string',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LessonVideoPlayer(
              videoUrl: '   ',
              lessonTitle: 'Sample Lesson',
            ),
          ),
        ),
      );

      expect(find.text('Video coming soon.'), findsOneWidget);
    });

    testWidgets('displays "Unable to load video" when URL is invalid',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LessonVideoPlayer(
              videoUrl: 'https://not-youtube.com/bad-link',
              lessonTitle: 'Invalid Lesson',
            ),
          ),
        ),
      );

      expect(find.text('Unable to load video'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders player surface when valid YouTube URL is provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LessonVideoPlayer(
              videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              lessonTitle: 'Valid Lesson',
            ),
          ),
        ),
      );

      // In test environment, renders the headless player representation with the video ID
      expect(find.textContaining('dQw4w9WgXcQ'), findsOneWidget);
    });
  });

  group('LessonScreen Integration Tests with Video Player', () {
    final sampleCourse = Course(
      id: 'c_test',
      title: 'Test Course',
      description: 'Course Description',
      instructor: 'Teacher',
      progress: 0.0,
      totalLessons: 2,
      category: 'Testing',
      imageUrl: '',
    );

    final lessonWithVideo = Lesson(
      id: 'l_vid',
      courseId: 'c_test',
      title: 'Lesson With Video',
      duration: '10 mins',
      module: 'Module 1',
      description: 'Overview of lesson with video.',
      videoUrl: 'https://youtu.be/dQw4w9WgXcQ',
    );

    final lessonNoVideo = Lesson(
      id: 'l_novid',
      courseId: 'c_test',
      title: 'Lesson No Video',
      duration: '15 mins',
      module: 'Module 2',
      description: 'Overview of lesson without video.',
    );

    testWidgets('LessonScreen shows video player above lesson overview',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonScreen(
            lesson: lessonWithVideo,
            course: sampleCourse,
            allLessons: [lessonWithVideo, lessonNoVideo],
          ),
        ),
      );

      // Video player widget is present
      expect(find.byType(LessonVideoPlayer), findsOneWidget);
      expect(find.textContaining('dQw4w9WgXcQ'), findsOneWidget);

      // Lesson Overview is rendered below video player
      expect(find.text('Lesson Overview'), findsOneWidget);
      expect(find.text('Overview of lesson with video.'), findsOneWidget);

      // Mark Complete button is present
      expect(find.text('Mark as Complete'), findsOneWidget);
      // Navigation buttons present
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('LessonScreen navigates from lesson with video to lesson without video',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonScreen(
            lesson: lessonWithVideo,
            course: sampleCourse,
            allLessons: [lessonWithVideo, lessonNoVideo],
          ),
        ),
      );

      // First lesson has video
      expect(find.textContaining('dQw4w9WgXcQ'), findsOneWidget);

      // Tap Next to navigate to second lesson (which has no video)
      final nextButton = find.text('Next');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Second lesson should now show "Video coming soon." placeholder
      expect(find.text('Lesson No Video'), findsOneWidget);
      expect(find.text('Video coming soon.'), findsOneWidget);
    });

    testWidgets('Mark as complete button toggles lesson completion state',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonScreen(
            lesson: lessonNoVideo,
            course: sampleCourse,
            allLessons: [lessonNoVideo],
          ),
        ),
      );

      final completeButton = find.text('Mark as Complete');
      expect(completeButton, findsOneWidget);

      // Scroll into view and tap to complete
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
      await tester.pump();

      expect(find.text('Completed ✓ (Tap to Undo)'), findsOneWidget);
    });
  });
}
