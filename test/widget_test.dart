import 'dart:io';

import 'package:decode/app.dart';
import 'package:decode/core/settings/settings_providers.dart';
import 'package:decode/core/supabase/supabase_providers.dart';
import 'package:decode/features/projects/project.dart';
import 'package:decode/features/projects/project_providers.dart';
import 'package:decode/features/projects/project_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyRepository extends ProjectRepository {
  _EmptyRepository() : super(Directory('/nonexistent'));

  @override
  Future<List<Project>> list() async => [];
}

void main() {
  testWidgets('Home screen shows branding and New Project button',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          supabaseProvider.overrideWithValue(null),
          projectRepositoryProvider.overrideWith(
            (ref) async => _EmptyRepository(),
          ),
        ],
        child: const DecodeApp(),
      ),
    );
    // The splash shows for a moment first.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Your Phone. Your Code. Your Future.'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
