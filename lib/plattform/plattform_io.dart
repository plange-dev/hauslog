import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../import/alt_import.dart';

const altImportMoeglich = true;

/// Fragt nach einem Speicherort und schreibt die Datei.
/// Gibt den Pfad zurück oder `null`, wenn abgebrochen wurde.
Future<String?> dateiSpeichern({
  required String name,
  required String endung,
  required String typ,
  required Uint8List bytes,
}) async {
  final ort = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: [
      XTypeGroup(label: typ, extensions: [endung]),
    ],
  );
  if (ort == null) return null;
  var pfad = ort.path;
  if (!pfad.toLowerCase().endsWith('.$endung')) pfad = '$pfad.$endung';
  await File(pfad).writeAsBytes(bytes);
  return pfad;
}

/// Ordner, in dem der alte Verbrauchsmanager seine Datenbank angelegt hat.
String? _altOrdner() {
  final basis = Platform.isWindows
      ? Platform.environment['LOCALAPPDATA']
      : '${Platform.environment['HOME']}/.local/share';
  if (basis == null) return null;
  final ordner = Directory('$basis${Platform.pathSeparator}verbrauchsmanager');
  return ordner.existsSync() ? ordner.path : null;
}

/// Lässt eine alte Verbrauchsmanager-Datenbank auswählen und liest sie.
/// `null` bei Abbruch.
Future<List<AltEintrag>?> altDatenbankLesen() async {
  final datei = await openFile(
    initialDirectory: _altOrdner(),
    acceptedTypeGroups: const [
      XTypeGroup(label: 'SQLite-Datenbank', extensions: ['db', 'sqlite']),
    ],
  );
  if (datei == null) return null;

  final db = sqlite3.open(datei.path, mode: OpenMode.readOnly);
  try {
    final vorhanden = db
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((z) => z['name'] as String)
        .toSet();
    return [
      for (final tabelle in altTabellen.keys.where(vorhanden.contains))
        for (final z in db.select(
          'SELECT datum, wert, notiz FROM $tabelle ORDER BY datum',
        ))
          AltEintrag(
            tabelle: tabelle,
            datum: z['datum'] as String,
            wert: (z['wert'] as num).toDouble(),
            notiz: (z['notiz'] as String?) ?? '',
          ),
    ];
  } finally {
    db.close();
  }
}

/// Ordner der lokalen Datenbank (zur Anzeige).
Future<String?> datenOrdner() async =>
    (await getApplicationSupportDirectory()).path;
