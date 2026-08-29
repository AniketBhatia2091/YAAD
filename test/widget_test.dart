import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yadd/app/app.dart';
import 'package:yadd/app/providers.dart';
import 'package:yadd/core/constants/app_constants.dart';
import 'package:yadd/data/database/app_database.dart';

void main() {
  testWidgets('YAAD App Smoke Test renders Onboarding or Home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingCompleted: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    await testDb.initDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const YaadApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(YaadApp), findsOneWidget);
    await testDb.close();
  });
}
