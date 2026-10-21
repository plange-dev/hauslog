import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hauslog/daten/datenbank.dart';
import 'package:hauslog/main.dart';
import 'package:hauslog/zustand.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late HauslogDatenbank db;

  Future<void> starten(
    WidgetTester tester,
    Future<void> Function()? vorbereiten,
  ) async {
    SharedPreferences.setMockInitialValues({});
    db = HauslogDatenbank(NativeDatabase.memory());
    // Testdaten in echter Zeit anlegen, bevor die Oberfläche die Datenbank
    // in der simulierten Testzeit benutzt.
    if (vorbereiten != null) await tester.runAsync(vorbereiten);
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          datenbankProvider.overrideWithValue(db),
          einstellungenProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
        child: const HauslogApp(),
      ),
    );
  }

  Future<void> warten(WidgetTester tester) async {
    // Drift-Streams liefern asynchron; echte Zeit kurz laufen lassen.
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// Baut den Widget-Baum ab, bevor die Datenbank geschlossen wird – sonst
  /// bleiben Timer der Drift-Streams hängen.
  Future<void> beenden(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.runAsync(db.close);
  }

  void appTest(
    String name,
    Future<void> Function(WidgetTester) body, {
    Future<void> Function()? vorbereiten,
  }) => testWidgets(name, (tester) async {
    await starten(tester, vorbereiten);
    await body(tester);
    await beenden(tester);
  });

  appTest('Leere App zeigt Hinweis und Offline-Status', (tester) async {
    await warten(tester);
    expect(find.text('Noch keine Zähler angelegt.'), findsOneWidget);
    expect(find.byTooltip('Nur auf diesem Gerät gespeichert'), findsOneWidget);
  });

  appTest(
    'Zähler mit Ablesungen zeigt Stand und Verbrauch',
    vorbereiten: () async {
      final id = await db.zaehlerSpeichern(
        name: 'Strom Haus',
        art: 'strom',
        einheit: 'kWh',
      );
      await db.ablesungSpeichern(
        zaehlerId: id,
        datum: DateTime(2026, 1, 1),
        stand: 1000,
      );
      await db.ablesungSpeichern(
        zaehlerId: id,
        datum: DateTime(2026, 2, 1),
        stand: 1124.5,
      );
    },
    (tester) async {
      await warten(tester);

      expect(find.text('Strom Haus'), findsOneWidget);
      expect(find.text('1.124,5 kWh'), findsOneWidget);

      await tester.tap(find.text('Strom Haus'));
      await warten(tester);
      expect(find.textContaining('+124,5 kWh in 31 Tagen'), findsOneWidget);
    },
  );

  appTest('Zähler über den Dialog anlegen', (tester) async {
    await warten(tester);

    await tester.tap(find.text('Ersten Zähler anlegen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Gas Keller',
    );
    await tester.tap(find.text('Speichern'));
    await warten(tester);

    expect(find.text('Gas Keller'), findsOneWidget);
    final abfrage = db.alleZaehler();
    await warten(tester);
    expect((await abfrage).single.ungesendet, isTrue);
  });
}
