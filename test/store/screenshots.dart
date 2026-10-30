// Play Store screenshots: the real screens, with a demo budget, rendered at
// phone size with the real fonts. Not part of `flutter test` (no _test
// suffix); run it on its own:
//
//   flutter test test/store/screenshots.dart
//
// Raw screens land in build/store/raw/; tool/store/frame.py puts them in
// the store frames.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/providers/font_provider.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:budgetseal/shared/theme/app_colors.dart';
import 'package:budgetseal/shared/theme/app_theme.dart';
import 'package:budgetseal/shared/theme/brand_palette.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_budget.dart';
import 'shots.dart';

/// 1080 × 2340 px, a common Android phone.
const _physical = Size(1080, 2340);
const _dpr = 2.75;

Future<void> _loadFonts() async {
  // Everything the app bundles (Bricolage Grotesque, Phosphor, Material).
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json'))
      as List<dynamic>;
  for (final f in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(f['family'] as String);
    for (final a in (f['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(a['asset'] as String));
    }
    await loader.load();
  }
  // Nunito Sans comes from Google Fonts at runtime; google_fonts names each
  // weight "NunitoSans_<weight>".
  for (final (name, file) in [
    ('regular', 400), ('300', 400), ('200', 400), ('500', 500),
    ('600', 600), ('700', 700), ('800', 800), ('900', 800),
  ]) {
    final bytes = File('tool/store/fonts/NunitoSans-$file.ttf').readAsBytesSync();
    final loader = FontLoader('NunitoSans_$name')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
  // google_fonts' fallback family: characters Nunito Sans lacks (→) come
  // from the system font on a phone; here, from Windows' Segoe UI.
  final segoe = File(r'C:\Windows\Fonts\segoeui.ttf');
  if (segoe.existsSync()) {
    final bytes = segoe.readAsBytesSync();
    await (FontLoader('NunitoSans')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUpAll(() async {
    await _loadFonts();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      for (final h in ['dashboard_welcome', 'reports_intro', 'transactions_intro'])
        'hint_dismissed_$h': true,
      'notification_permission_asked': true,
      'entry_mode': 'one',
      'member_name_asked': true,
    });
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    await DemoBudget(db).build();
    container.read(currentHouseholdIdProvider.notifier).set(DemoBudget.hh);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  for (final shot in shots) {
    testWidgets('shot ${shot.name}', (tester) async {
      tester.view.physicalSize = _physical;
      tester.view.devicePixelRatio = _dpr;
      tester.view.padding = const FakeViewPadding(top: 24 * _dpr, bottom: 16 * _dpr);
      tester.view.viewPadding = const FakeViewPadding(top: 24 * _dpr, bottom: 16 * _dpr);
      addTearDown(tester.view.reset);

      final dark = shot.dark;
      final pair = brandPalette.first;
      AppColors.setAccent(pair);
      AppColors.applyMode(dark);
      final theme = dark
          ? buildDarkTheme(defaultAppFont, pair.bright, pair.darkFill)
          : buildLightTheme(defaultAppFont, pair.deep, pair.lightFill);

      final router = GoRouter(
        initialLocation: shot.location,
        routes: [
          for (final r in shotRoutes)
            GoRoute(path: r.path, builder: (_, s) => r.builder(s)),
        ],
      );
      final key = GlobalKey();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp.router(
            theme: theme,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) {
              AppColors.applyMode(dark);
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                    textScaler:
                        TextScaler.linear(fontOpticalScale(defaultAppFont))),
                child: child!,
              );
            },
          ),
        ),
      ));
      Future<void> settle([int rounds = 10]) async {
        for (var i = 0; i < rounds; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 60)));
          await tester.pump(const Duration(milliseconds: 120));
        }
      }

      await settle();
      if (shot.act != null) {
        await shot.act!(tester);
        await settle();
      }
      // Fluent emoji and other images decode off the test clock.
      for (final e in find.byType(Image).evaluate()) {
        final img = e.widget as Image;
        await tester.runAsync(() => precacheImage(img.image, e)
            .timeout(const Duration(seconds: 3), onTimeout: () {}));
      }
      await settle(6);

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: _dpr);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      final out = File('build/store/raw/${shot.name}.png')
        ..createSync(recursive: true);
      out.writeAsBytesSync(bytes!);
      // Keep going whatever the screen logged (overflow in a corner case
      // shouldn't stop the rest).
      tester.takeException();
      // Close the screens so their database streams finish their timers.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
