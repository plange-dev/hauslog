import 'dart:math';

const _zeichen = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _zufall = Random.secure();

/// Neue Datensatz-ID im PocketBase-Format (15 Zeichen, a–z und 0–9).
///
/// Die App vergibt IDs selbst, damit Datensätze offline angelegt und später
/// ohne Umschlüsseln zum Server übertragen werden können.
String neueId() =>
    List.generate(15, (_) => _zeichen[_zufall.nextInt(_zeichen.length)]).join();

/// Datum als `JJJJ-MM-TT`, so wie es in Datenbank und Server steht.
String datumText(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime datumAusText(String s) => DateTime.parse(s);
