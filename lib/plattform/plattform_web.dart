import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../import/alt_import.dart';

const altImportMoeglich = false;

/// Bietet die Datei im Browser zum Herunterladen an.
Future<String?> dateiSpeichern({
  required String name,
  required String endung,
  required String typ,
  required Uint8List bytes,
}) async {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..click();
  web.URL.revokeObjectURL(url);
  return name;
}

Future<List<AltEintrag>?> altDatenbankLesen() async => null;

/// Im Browser liegt die Datenbank im Browser-Speicher (OPFS/IndexedDB).
Future<String?> datenOrdner() async => null;
