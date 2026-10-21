import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daten/datenbank.dart';

/// Wird in `main()` überschrieben.
final datenbankProvider = Provider<HauslogDatenbank>(
  (ref) => throw UnimplementedError('datenbankProvider nicht gesetzt'),
);

/// Wird in `main()` überschrieben.
final einstellungenProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('einstellungenProvider nicht gesetzt'),
);

final zaehlerListeProvider = StreamProvider<List<Zaehler>>(
  (ref) => ref.watch(datenbankProvider).zaehlerBeobachten(),
);

final zaehlerProvider = StreamProvider.family<Zaehler?, String>(
  (ref, id) => ref.watch(datenbankProvider).einenZaehlerBeobachten(id),
);

final ablesungenProvider = StreamProvider.family<List<Ablesung>, String>(
  (ref, zaehlerId) =>
      ref.watch(datenbankProvider).ablesungenBeobachten(zaehlerId),
);

final alleAblesungenProvider = StreamProvider<List<Ablesung>>(
  (ref) => ref.watch(datenbankProvider).alleAblesungenBeobachten(),
);

final ungesendetProvider = StreamProvider<int>(
  (ref) => ref.watch(datenbankProvider).anzahlUngesendetBeobachten(),
);
