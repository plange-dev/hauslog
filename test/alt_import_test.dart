import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hauslog/daten/datenbank.dart';
import 'package:hauslog/import/alt_import.dart';

void main() {
  test('Alte Einträge werden je Art zu einem Zähler mit Ablesungen', () async {
    final db = HauslogDatenbank(NativeDatabase.memory());
    addTearDown(db.close);

    final anzahl = await altDatenImportieren(db, const [
      AltEintrag(
        tabelle: 'strom',
        datum: '2024-01-15',
        wert: 312.5,
        notiz: 'HZ',
      ),
      AltEintrag(tabelle: 'strom', datum: '2024-02-15', wert: 600, notiz: ''),
      AltEintrag(tabelle: 'gas', datum: '2024-01-15', wert: 123.4, notiz: ''),
      AltEintrag(tabelle: 'gas', datum: 'kaputt', wert: 1, notiz: ''),
    ]);

    expect(anzahl, 3);
    final zaehler = await db.alleZaehler();
    expect(zaehler.map((z) => (z.name, z.einheit)), [
      ('Gas', 'm³'),
      ('Strom', 'kWh'),
    ]);
    final strom = zaehler.singleWhere((z) => z.art == 'strom');
    final ablesungen = (await db.alleAblesungen()).where(
      (a) => a.zaehlerId == strom.id,
    );
    expect(ablesungen.map((a) => a.stand), [312.5, 600]);
    expect(ablesungen.first.notiz, 'HZ');
    expect(ablesungen.every((a) => a.ungesendet), isTrue);
  });
}
