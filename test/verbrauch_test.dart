import 'package:flutter_test/flutter_test.dart';
import 'package:hauslog/logik/verbrauch.dart';

void main() {
  Messpunkt p(String datum, double stand) =>
      Messpunkt(datum: DateTime.parse(datum), stand: stand);

  test('Abschnitte sind die Differenzen aufeinanderfolgender Stände', () {
    final a = abschnitteBerechnen([
      p('2026-03-01', 1300),
      p('2026-01-01', 1000),
      p('2026-02-01', 1124),
    ]);
    expect(a.map((x) => x.verbrauch), [124, 176]);
    expect(a.first.tage, 31);
    expect(a.first.proTag, closeTo(4, 0.001));
  });

  test('Fallender Stand (Zählertausch) ergibt keinen Verbrauch', () {
    final a = abschnitteBerechnen([p('2026-01-01', 500), p('2026-02-01', 3)]);
    expect(a.single.verbrauch, isNull);
    expect(a.single.proTag, isNull);
  });

  test('Jahresverbrauch teilt Abschnitte über die Jahresgrenze anteilig', () {
    final a = abschnitteBerechnen([
      p('2025-12-22', 0),
      p('2026-01-11', 200), // 20 Tage, davon 10 in 2026
      p('2026-02-10', 500),
    ]);
    expect(verbrauchImJahr(a, 2026), closeTo(100 + 300, 0.001));
    expect(verbrauchImJahr(a, 2025), closeTo(100, 0.001));
  });
}
