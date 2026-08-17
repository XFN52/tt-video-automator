import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tt_video_automator/core/database/database_provider.dart';
import 'package:tt_video_automator/core/database/isar_service.dart';
import 'package:tt_video_automator/main.dart';

class MockIsarService extends Mock implements IsarService {}

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    final mockIsar = MockIsarService();
    when(() => mockIsar.getAllPresets()).thenAnswer((_) async => []);
    when(() => mockIsar.getAllTasks()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarServiceProvider.overrideWithValue(mockIsar),
        ],
        child: const TTVideoAutomatorApp(),
      ),
    );
    // Пропускаем один фрейм: async зависимости (Isar, path_provider) отдренажированы моком
    await tester.pump();

    expect(find.text('TT Video Automator'), findsOneWidget);
  });
}
