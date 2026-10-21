import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hauslog/daten/datenbank.dart';
import 'package:hauslog/export/export.dart';

void main() {
  const zaehler = [
    Zaehler(
      id: 'z1',
      name: 'Strom; Haus',
      art: 'strom',
      einheit: 'kWh',
      zaehlernummer: '',
      notiz: '',
      geaendertAm: 0,
      geloescht: false,
      ungesendet: false,
    ),
  ];
  Ablesung ablesung(String datum, double stand) => Ablesung(
    id: datum,
    zaehlerId: 'z1',
    datum: datum,
    stand: stand,
    notiz: '',
    geaendertAm: 0,
    geloescht: false,
    ungesendet: false,
  );
  final ablesungen = [
    ablesung('2026-02-01', 1124.5),
    ablesung('2026-01-01', 1000),
  ];

  test('CSV: Semikolon, Dezimalkomma, Verbrauch, Maskierung', () {
    final bytes = csvErzeugen(zaehler, ablesungen);
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    final zeilen = utf8.decode(bytes.sublist(3)).trim().split('\r\n');
    expect(zeilen, [
      'Zähler;Art;Zählernummer;Datum;Stand;Einheit;Verbrauch;Notiz',
      '"Strom; Haus";Strom;;2026-01-01;1000,0;kWh;;',
      '"Strom; Haus";Strom;;2026-02-01;1124,5;kWh;124,5;',
    ]);
  });

  test('XLSX: ein Blatt pro Zähler mit Verbrauchsspalte', () {
    final excel = Excel.decodeBytes(xlsxErzeugen(zaehler, ablesungen));
    expect(excel.tables.keys, ['Strom; Haus']);
    final zeilen = excel.tables['Strom; Haus']!.rows;
    expect(zeilen, hasLength(3));
    expect(zeilen[2][1]?.value, DoubleCellValue(1124.5));
    expect(zeilen[2][2]?.value, DoubleCellValue(124.5));
  });
}
