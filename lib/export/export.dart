import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../daten/datenbank.dart';
import '../daten/zaehler_art.dart';
import '../logik/verbrauch.dart';

/// Ablesungen eines Zählers, älteste zuerst, mit Verbrauch seit der
/// vorherigen Ablesung (`null` bei der ersten oder nach Zählertausch).
List<(Ablesung, double?)> _mitVerbrauch(List<Ablesung> ablesungen) {
  final sortiert = [...ablesungen]..sort((a, b) => a.datum.compareTo(b.datum));
  final abschnitte = abschnitteBerechnen(
    sortiert.map(
      (a) => Messpunkt(datum: DateTime.parse(a.datum), stand: a.stand),
    ),
  );
  return [
    for (var i = 0; i < sortiert.length; i++)
      (sortiert[i], i == 0 ? null : abschnitte[i - 1].verbrauch),
  ];
}

Map<String, List<Ablesung>> _nachZaehler(List<Ablesung> ablesungen) {
  final ergebnis = <String, List<Ablesung>>{};
  for (final a in ablesungen) {
    (ergebnis[a.zaehlerId] ??= []).add(a);
  }
  return ergebnis;
}

/// CSV für deutsches Excel: Semikolon, Dezimalkomma, UTF-8 mit BOM.
Uint8List csvErzeugen(List<Zaehler> zaehler, List<Ablesung> ablesungen) {
  String feld(String s) =>
      s.contains(RegExp('[;"\n\r]')) ? '"${s.replaceAll('"', '""')}"' : s;
  String zahl(double? v) => v == null ? '' : v.toString().replaceAll('.', ',');

  final zeilen = [
    'Zähler;Art;Zählernummer;Datum;Stand;Einheit;Verbrauch;Notiz',
  ];
  final proZaehler = _nachZaehler(ablesungen);
  for (final z in zaehler) {
    for (final (a, verbrauch) in _mitVerbrauch(proZaehler[z.id] ?? [])) {
      zeilen.add(
        [
          feld(z.name),
          feld(ZaehlerArt.ausName(z.art).label),
          feld(z.zaehlernummer),
          a.datum,
          zahl(a.stand),
          feld(z.einheit),
          zahl(verbrauch),
          feld(a.notiz),
        ].join(';'),
      );
    }
  }
  return Uint8List.fromList([
    0xEF, 0xBB, 0xBF, // BOM, damit Excel Umlaute richtig anzeigt
    ...utf8.encode('${zeilen.join('\r\n')}\r\n'),
  ]);
}

/// Excel-Datei mit einem Blatt pro Zähler.
Uint8List xlsxErzeugen(List<Zaehler> zaehler, List<Ablesung> ablesungen) {
  final excel = Excel.createExcel();
  final standardBlatt = excel.getDefaultSheet();
  final proZaehler = _nachZaehler(ablesungen);
  final vergeben = <String>{};

  for (final z in zaehler) {
    final blatt = excel[_blattName(z.name, vergeben)];
    final einheit = z.einheit.isEmpty ? '' : ' (${z.einheit})';
    blatt.appendRow([
      TextCellValue('Datum'),
      TextCellValue('Stand$einheit'),
      TextCellValue('Verbrauch$einheit'),
      TextCellValue('Notiz'),
    ]);
    for (final (a, verbrauch) in _mitVerbrauch(proZaehler[z.id] ?? [])) {
      final d = DateTime.parse(a.datum);
      blatt.appendRow([
        DateCellValue(year: d.year, month: d.month, day: d.day),
        DoubleCellValue(a.stand),
        verbrauch == null ? null : DoubleCellValue(verbrauch),
        TextCellValue(a.notiz),
      ]);
    }
    blatt.setColumnWidth(0, 14);
    blatt.setColumnWidth(1, 16);
    blatt.setColumnWidth(2, 16);
    blatt.setColumnWidth(3, 40);
  }

  if (standardBlatt != null && zaehler.isNotEmpty) excel.delete(standardBlatt);
  return Uint8List.fromList(excel.encode()!);
}

/// Excel erlaubt höchstens 31 Zeichen und keine Sonderzeichen wie `/` oder `:`.
String _blattName(String name, Set<String> vergeben) {
  var basis = name.replaceAll(RegExp(r'[\[\]:*?/\\]'), '-').trim();
  if (basis.isEmpty) basis = 'Zähler';
  if (basis.length > 28) basis = basis.substring(0, 28);
  var kandidat = basis;
  for (var i = 2; !vergeben.add(kandidat.toLowerCase()); i++) {
    kandidat = '$basis $i';
  }
  return kandidat;
}
