import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daten/datenbank.dart';
import 'sync/sync_steuerung.dart';
import 'ui/startseite.dart';
import 'zustand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final einstellungen = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        datenbankProvider.overrideWithValue(HauslogDatenbank()),
        einstellungenProvider.overrideWithValue(einstellungen),
      ],
      child: const HauslogApp(),
    ),
  );
}

class HauslogApp extends ConsumerWidget {
  const HauslogApp({super.key});

  static const _grundfarbe = Color(0xFF1A2744);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync von Anfang an aktiv halten, nicht erst beim Öffnen der Einstellungen.
    ref.watch(syncProvider);

    return MaterialApp(
      title: 'Hauslog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _grundfarbe),
      darkTheme: ThemeData(
        colorSchemeSeed: _grundfarbe,
        brightness: Brightness.dark,
      ),
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Startseite(),
    );
  }
}
