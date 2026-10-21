import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../daten/datenbank.dart';
import '../daten/zaehler_art.dart';
import '../logik/verbrauch.dart';
import '../zustand.dart';
import 'dialoge.dart';
import 'formate.dart';
import 'kennzahlen.dart';

class ZaehlerDetail extends ConsumerWidget {
  const ZaehlerDetail({super.key, required this.zaehlerId});

  final String zaehlerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zaehler = ref.watch(zaehlerProvider(zaehlerId));
    final ablesungen = ref.watch(ablesungenProvider(zaehlerId));

    return switch ((zaehler, ablesungen)) {
      (AsyncData(value: final z?), AsyncData(value: final a)) => _Inhalt(
        zaehler: z,
        ablesungen: a,
      ),
      // Gelöscht (auch durch einen anderen Benutzer).
      (AsyncData(value: null), _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Dieser Zähler wurde gelöscht.')),
      ),
      (AsyncError(:final error), _) ||
      (_, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Fehler: $error')),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Inhalt extends ConsumerWidget {
  const _Inhalt({required this.zaehler, required this.ablesungen});

  final Zaehler zaehler;

  /// Neueste zuerst.
  final List<Ablesung> ablesungen;

  Future<void> _loeschen(BuildContext context, WidgetRef ref) async {
    final ok = await loeschenBestaetigen(
      context,
      '„${zaehler.name}“ und alle ${ablesungen.length} Ablesungen löschen? '
      'Das gilt für alle Benutzer.',
    );
    if (!ok) return;
    await ref.read(datenbankProvider).zaehlerLoeschen(zaehler.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final art = ZaehlerArt.ausName(zaehler.art);
    final kennzahlen = Kennzahlen(ablesungen);
    final jahr = DateTime.now().year;
    final e = zaehler.einheit;

    return Scaffold(
      appBar: AppBar(
        title: Text(zaehler.name),
        actions: [
          IconButton(
            tooltip: 'Bearbeiten',
            icon: const Icon(Icons.edit),
            onPressed: () => zaehlerBearbeiten(context, zaehler: zaehler),
          ),
          IconButton(
            tooltip: 'Löschen',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _loeschen(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ablesungBearbeiten(
          context,
          zaehler: zaehler,
          vorheriger: kennzahlen.letzte?.stand,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ablesung'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (zaehler.zaehlernummer.isNotEmpty || zaehler.notiz.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                [
                  if (zaehler.zaehlernummer.isNotEmpty)
                    'Zählernummer ${zaehler.zaehlernummer}',
                  if (zaehler.notiz.isNotEmpty) zaehler.notiz,
                ].join(' · '),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Kachel(
                titel: 'Letzter Stand',
                wert: kennzahlen.letzte == null
                    ? '–'
                    : mitEinheit(kennzahlen.letzte!.stand, e),
                farbe: art.farbe,
              ),
              _Kachel(
                titel: 'Verbrauch $jahr',
                wert: kennzahlen.abschnitte.isEmpty
                    ? '–'
                    : mitEinheit(kennzahlen.imJahr(jahr), e),
              ),
              _Kachel(
                titel: 'Verbrauch ${jahr - 1}',
                wert: kennzahlen.abschnitte.isEmpty
                    ? '–'
                    : mitEinheit(kennzahlen.imJahr(jahr - 1), e),
              ),
              _Kachel(
                titel: 'Ø pro Tag (zuletzt)',
                wert: switch (kennzahlen.letzterAbschnitt?.proTag) {
                  final v? => mitEinheit(v, e),
                  null => '–',
                },
              ),
            ],
          ),
          if (kennzahlen.abschnitte.length >= 2) ...[
            const SizedBox(height: 16),
            _Diagramm(
              abschnitte: kennzahlen.abschnitte,
              einheit: e,
              farbe: art.farbe,
            ),
          ],
          const SizedBox(height: 16),
          Text('Ablesungen', style: Theme.of(context).textTheme.titleMedium),
          if (ablesungen.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Noch keine Ablesung erfasst.'),
            ),
          for (var i = 0; i < ablesungen.length; i++)
            _AblesungZeile(
              zaehler: zaehler,
              ablesung: ablesungen[i],
              vorherige: i + 1 < ablesungen.length ? ablesungen[i + 1] : null,
            ),
        ],
      ),
    );
  }
}

class _Kachel extends StatelessWidget {
  const _Kachel({required this.titel, required this.wert, this.farbe});

  final String titel;
  final String wert;
  final Color? farbe;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 200,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titel, style: text.bodySmall),
              Text(wert, style: text.titleLarge?.copyWith(color: farbe)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AblesungZeile extends ConsumerWidget {
  const _AblesungZeile({
    required this.zaehler,
    required this.ablesung,
    this.vorherige,
  });

  final Zaehler zaehler;
  final Ablesung ablesung;
  final Ablesung? vorherige;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = vorherige;
    String? verbrauch;
    if (v != null) {
      final abschnitt = abschnitteBerechnen([
        Messpunkt(datum: DateTime.parse(v.datum), stand: v.stand),
        Messpunkt(datum: DateTime.parse(ablesung.datum), stand: ablesung.stand),
      ]).single;
      verbrauch = abschnitt.verbrauch == null
          ? 'Stand gefallen (Zählertausch?)'
          : '+${mitEinheit(abschnitt.verbrauch!, zaehler.einheit)} '
                'in ${abschnitt.tage} Tagen';
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${datumAnzeige(DateTime.parse(ablesung.datum))}   '
        '${mitEinheit(ablesung.stand, zaehler.einheit)}',
      ),
      subtitle: Text(
        [?verbrauch, if (ablesung.notiz.isNotEmpty) ablesung.notiz].join(' · '),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (aktion) async {
          if (aktion == 'bearbeiten') {
            await ablesungBearbeiten(
              context,
              zaehler: zaehler,
              ablesung: ablesung,
              vorheriger: v?.stand,
            );
          } else if (await loeschenBestaetigen(
            context,
            'Ablesung vom ${datumAnzeige(DateTime.parse(ablesung.datum))} löschen?',
          )) {
            await ref.read(datenbankProvider).ablesungLoeschen(ablesung.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'bearbeiten', child: Text('Bearbeiten')),
          PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
        ],
      ),
    );
  }
}

/// Verbrauch je Ablesungszeitraum (die letzten 12).
class _Diagramm extends StatelessWidget {
  const _Diagramm({
    required this.abschnitte,
    required this.einheit,
    required this.farbe,
  });

  final List<Verbrauchsabschnitt> abschnitte;
  final String einheit;
  final Color farbe;

  @override
  Widget build(BuildContext context) {
    final letzte = abschnitte.length > 12
        ? abschnitte.sublist(abschnitte.length - 12)
        : abschnitte;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Verbrauch je Ablesungszeitraum ($einheit)',
                style: text.titleSmall,
              ),
            ),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (gruppe, _, stab, _) {
                        final a = letzte[gruppe.x];
                        return BarTooltipItem(
                          '${datumAnzeige(a.von)} – ${datumAnzeige(a.bis)}\n'
                          '${mitEinheit(stab.toY, einheit)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (wert, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            zahlAnzeige(wert),
                            style: text.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (wert, meta) {
                          final bis = letzte[wert.toInt()].bis;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${bis.month.toString().padLeft(2, '0')}/'
                              '${bis.year % 100}',
                              style: text.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < letzte.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: letzte[i].verbrauch ?? 0,
                            color: farbe,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
