import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:animesync/widgets/anime_card.dart';
import 'package:animesync/models/models.dart';

void main() {
  group('AnimeCard Widget', () {
    testWidgets('renders title and progress bar', (WidgetTester tester) async {
      final anime = AnimeProgress(
        id: 1,
        title: 'Test Anime',
        totalEpisodes: 24,
        watchedEpisodes: 12,
        status: 'watching',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimeCard(anime: anime),
          ),
        ),
      );

      // Title
      expect(find.text('Test Anime'), findsOneWidget);
      // Episode count
      expect(find.text('12/24 集'), findsOneWidget);
      // Status badge
      expect(find.text('在看'), findsOneWidget);
    });

    testWidgets('shows progress bar with correct value', (WidgetTester tester) async {
      final anime = AnimeProgress(
        id: 1,
        title: 'Progress Test',
        totalEpisodes: 10,
        watchedEpisodes: 5,
        status: 'watching',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimeCard(anime: anime),
          ),
        ),
      );

      // Find LinearProgressIndicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.5);
    });

    testWidgets('displays cover placeholder when no coverUrl', (WidgetTester tester) async {
      final anime = AnimeProgress(
        id: 1,
        title: 'No Cover',
        coverUrl: null,
        totalEpisodes: 1,
        watchedEpisodes: 0,
        status: 'plan_to_watch',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimeCard(anime: anime),
          ),
        ),
      );

      // The placeholder Icon should be found
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      // Status
      expect(find.text('想看'), findsOneWidget);
    });

    testWidgets('calls onIncrement when pressing + button for watching status', (WidgetTester tester) async {
      bool incrementPressed = false;
      final anime = AnimeProgress(
        id: 1,
        title: 'Increment Test',
        status: 'watching',
        watchedEpisodes: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimeCard(
              anime: anime,
              onIncrement: () => incrementPressed = true,
            ),
          ),
        ),
      );

      // Find the +1 IconButton with tooltip '+1'
      final incrementButton = find.byTooltip('+1');
      expect(incrementButton, findsOneWidget);
      await tester.tap(incrementButton);
      expect(incrementPressed, true);
    });

    testWidgets('calls onEdit when tapping the card', (WidgetTester tester) async {
      bool editPressed = false;
      final anime = AnimeProgress(
        id: 1,
        title: 'Edit Test',
        status: 'watching',
        watchedEpisodes: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimeCard(
              anime: anime,
              onEdit: () => editPressed = true,
            ),
          ),
        ),
      );

      // Tap the card to trigger onEdit
      await tester.tap(find.byType(AnimeCard));
      expect(editPressed, true);
    });

    test('statusColor returns correct colors', () {
      expect(AnimeCard.statusColor('watching'), const Color(0xFF4CAF50));
      expect(AnimeCard.statusColor('completed'), const Color(0xFF2196F3));
      expect(AnimeCard.statusColor('plan_to_watch'), const Color(0xFFFFC107));
      expect(AnimeCard.statusColor('on_hold'), const Color(0xFFFF9800));
      expect(AnimeCard.statusColor('dropped'), const Color(0xFFF44336));
      expect(AnimeCard.statusColor('unknown'), Colors.grey);
    });
  });
}
