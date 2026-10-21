import '../daten/datenbank.dart';
import '../logik/verbrauch.dart';

/// Abgeleitete Werte eines Zählers für die Anzeige.
class Kennzahlen {
  Kennzahlen(List<Ablesung> ablesungen)
    : letzte = ablesungen.isEmpty
          ? null
          : ablesungen.reduce((a, b) => b.datum.compareTo(a.datum) > 0 ? b : a),
      abschnitte = abschnitteBerechnen(
        ablesungen.map(
          (a) => Messpunkt(datum: DateTime.parse(a.datum), stand: a.stand),
        ),
      );

  final Ablesung? letzte;

  /// Älteste zuerst.
  final List<Verbrauchsabschnitt> abschnitte;

  Verbrauchsabschnitt? get letzterAbschnitt =>
      abschnitte.isEmpty ? null : abschnitte.last;

  double imJahr(int jahr) => verbrauchImJahr(abschnitte, jahr);
}
