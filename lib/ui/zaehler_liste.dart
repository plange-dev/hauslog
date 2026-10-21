import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../daten/datenbank.dart';
import '../daten/zaehler_art.dart';
import '../zustand.dart';
import 'dialoge.dart';
import 'formate.dart';
import 'kennzahlen.dart';
import 'zaehler_detail.dart';

class ZaehlerListe extends ConsumerWidget {
  const ZaehlerListe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zaehler = ref.watch(zaehlerListeProvider);
    final ablesungen = ref.watch(alleAblesungenProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => zaehlerBearbeiten(context),
        icon: const Icon(Icons.add),
        label: const Text('Zähler'),
      ),
      body: switch ((zaehler, ablesungen)) {
        (AsyncData(value: final z), AsyncData(value: final a)) =>
          z.isEmpty ? const _Leer() : _Raster(zaehler: z, ablesungen: a),
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => Center(child: Text('Fehler: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Leer extends StatelessWidget {
  const _Leer();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Icon(
          Icons.speed,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
        const Text('Noch keine Zähler angelegt.'),
        FilledButton.icon(
          onPressed: () => zaehlerBearbeiten(context),
          icon: const Icon(Icons.add),
          label: const Text('Ersten Zähler anlegen'),
        ),
      ],
    ),
  );
}

class _Raster extends StatelessWidget {
  const _Raster({required this.zaehler, required this.ablesungen});

  final List<Zaehler> zaehler;
  final List<Ablesung> ablesungen;

  @override
  Widget build(BuildContext context) {
    final proZaehler = <String, List<Ablesung>>{};
    for (final a in ablesungen) {
      (proZaehler[a.zaehlerId] ??= []).add(a);
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 168,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: zaehler.length,
      itemBuilder: (_, i) => _ZaehlerKarte(
        zaehler: zaehler[i],
        kennzahlen: Kennzahlen(proZaehler[zaehler[i].id] ?? const []),
      ),
    );
  }
}

class _ZaehlerKarte extends StatelessWidget {
  const _ZaehlerKarte({required this.zaehler, required this.kennzahlen});

  final Zaehler zaehler;
  final Kennzahlen kennzahlen;

  @override
  Widget build(BuildContext context) {
    final art = ZaehlerArt.ausName(zaehler.art);
    final text = Theme.of(context).textTheme;
    final letzte = kennzahlen.letzte;
    final proTag = kennzahlen.letzterAbschnitt?.proTag;
    final jahr = DateTime.now().year;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ZaehlerDetail(zaehlerId: zaehler.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 12,
                children: [
                  CircleAvatar(
                    backgroundColor: art.farbe.withValues(alpha: 0.18),
                    foregroundColor: art.farbe,
                    child: Icon(art.symbol),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zaehler.name,
                          style: text.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          zaehler.zaehlernummer.isEmpty
                              ? art.label
                              : '${art.label} · Nr. ${zaehler.zaehlernummer}',
                          style: text.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (letzte == null)
                Text('Noch keine Ablesung', style: text.bodyMedium)
              else ...[
                Text(
                  mitEinheit(letzte.stand, zaehler.einheit),
                  style: text.headlineSmall?.copyWith(color: art.farbe),
                ),
                Text(
                  [
                    'am ${datumAnzeige(DateTime.parse(letzte.datum))}',
                    if (kennzahlen.abschnitte.isNotEmpty)
                      '$jahr: ${mitEinheit(kennzahlen.imJahr(jahr), zaehler.einheit)}',
                    if (proTag != null)
                      'Ø ${mitEinheit(proTag, zaehler.einheit)}/Tag',
                  ].join(' · '),
                  style: text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
