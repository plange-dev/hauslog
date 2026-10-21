import '../daten/datenbank.dart';
import '../daten/zaehler_art.dart';

/// Eine Zeile aus der Datenbank des alten Rust-„Verbrauchsmanagers“
/// (Tabellen `strom`, `wasser`, `gas`).
class AltEintrag {
  const AltEintrag({
    required this.tabelle,
    required this.datum,
    required this.wert,
    required this.notiz,
  });

  final String tabelle;
  final String datum;
  final double wert;
  final String notiz;
}

const altTabellen = {
  'strom': ZaehlerArt.strom,
  'wasser': ZaehlerArt.wasser,
  'gas': ZaehlerArt.gas,
};

/// Legt je alter Tabelle einen Zähler an und übernimmt die Werte als
/// Zählerstände. Gibt die Anzahl übernommener Ablesungen zurück.
Future<int> altDatenImportieren(
  HauslogDatenbank db,
  List<AltEintrag> eintraege,
) => db.transaction(() async {
  final zaehlerIds = <String, String>{};
  var anzahl = 0;
  for (final e in eintraege) {
    final datum = DateTime.tryParse(e.datum);
    final art = altTabellen[e.tabelle];
    if (datum == null || art == null) continue;
    final zaehlerId = zaehlerIds[e.tabelle] ??= await db.zaehlerSpeichern(
      name: art.label,
      art: art.name,
      einheit: art.einheit,
      notiz: 'Aus dem Verbrauchsmanager importiert',
    );
    await db.ablesungSpeichern(
      zaehlerId: zaehlerId,
      datum: datum,
      stand: e.wert,
      notiz: e.notiz,
    );
    anzahl++;
  }
  return anzahl;
});
