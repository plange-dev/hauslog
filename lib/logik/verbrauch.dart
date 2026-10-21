/// Verbrauchsberechnung aus Zählerständen.
///
/// Ein Zähler zählt nur hoch. Der Verbrauch eines Zeitraums ist deshalb die
/// Differenz zweier aufeinanderfolgender Ablesungen. Fällt der Stand, wurde
/// sehr wahrscheinlich der Zähler getauscht – dieser Abschnitt hat dann keinen
/// sinnvollen Verbrauch.
library;

class Messpunkt {
  const Messpunkt({required this.datum, required this.stand});

  final DateTime datum;
  final double stand;
}

class Verbrauchsabschnitt {
  const Verbrauchsabschnitt({
    required this.von,
    required this.bis,
    required this.verbrauch,
  });

  final DateTime von;
  final DateTime bis;

  /// `null`, wenn der Stand gefallen ist (Zählertausch o. ä.).
  final double? verbrauch;

  int get tage => bis.difference(von).inDays;

  double? get proTag =>
      verbrauch == null || tage <= 0 ? null : verbrauch! / tage;
}

/// Bildet aus Messpunkten (beliebige Reihenfolge) die Abschnitte zwischen
/// aufeinanderfolgenden Ablesungen, älteste zuerst.
List<Verbrauchsabschnitt> abschnitteBerechnen(Iterable<Messpunkt> punkte) {
  final sortiert = punkte.toList()..sort((a, b) => a.datum.compareTo(b.datum));
  return [
    for (var i = 1; i < sortiert.length; i++)
      Verbrauchsabschnitt(
        von: sortiert[i - 1].datum,
        bis: sortiert[i].datum,
        verbrauch: sortiert[i].stand >= sortiert[i - 1].stand
            ? sortiert[i].stand - sortiert[i - 1].stand
            : null,
      ),
  ];
}

/// Verbrauch innerhalb eines Kalenderjahres. Abschnitte, die über die
/// Jahresgrenze reichen, werden anteilig nach Tagen aufgeteilt.
double verbrauchImJahr(List<Verbrauchsabschnitt> abschnitte, int jahr) {
  final jahresBeginn = DateTime(jahr);
  final jahresEnde = DateTime(jahr + 1);
  var summe = 0.0;
  for (final a in abschnitte) {
    if (a.verbrauch == null || a.tage <= 0) continue;
    final von = a.von.isBefore(jahresBeginn) ? jahresBeginn : a.von;
    final bis = a.bis.isAfter(jahresEnde) ? jahresEnde : a.bis;
    final tageImJahr = bis.difference(von).inDays;
    if (tageImJahr <= 0) continue;
    summe += a.verbrauch! * tageImJahr / a.tage;
  }
  return summe;
}
