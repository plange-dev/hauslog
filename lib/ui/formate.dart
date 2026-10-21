import 'package:intl/intl.dart';

final _datum = DateFormat('dd.MM.yyyy');
final _zeit = DateFormat('dd.MM.yyyy HH:mm');
final _zahl = NumberFormat('#,##0.###', 'de');

String datumAnzeige(DateTime d) => _datum.format(d);

String zeitAnzeige(DateTime d) => _zeit.format(d);

String zahlAnzeige(double v) => _zahl.format(v);

String mitEinheit(double v, String einheit) =>
    einheit.isEmpty ? zahlAnzeige(v) : '${zahlAnzeige(v)} $einheit';

/// Liest Zahlen wie `1234,5`, `1.234,5` oder `1234.5`.
double? zahlLesen(String text) {
  var t = text.trim().replaceAll(' ', '');
  if (t.contains(',')) t = t.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(t);
}
