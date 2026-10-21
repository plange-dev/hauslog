import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../daten/datenbank.dart';
import '../export/export.dart';
import '../import/alt_import.dart';
import '../plattform/plattform.dart';
import '../sync/sync_steuerung.dart';
import '../zustand.dart';
import 'dialoge.dart';
import 'formate.dart';

class Einstellungen extends StatelessWidget {
  const Einstellungen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: const Column(
            spacing: 16,
            children: [_ServerKarte(), _DatenKarte()],
          ),
        ),
      ),
    ],
  );
}

class _Abschnitt extends StatelessWidget {
  const _Abschnitt({required this.titel, required this.kinder});

  final String titel;
  final List<Widget> kinder;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(titel, style: Theme.of(context).textTheme.titleMedium),
          ...kinder,
        ],
      ),
    ),
  );
}

// ── Server ──────────────────────────────────────────────────────────────────

class _ServerKarte extends ConsumerStatefulWidget {
  const _ServerKarte();

  @override
  ConsumerState<_ServerKarte> createState() => _ServerKarteState();
}

class _ServerKarteState extends ConsumerState<_ServerKarte> {
  // Wird die Web-Version von PocketBase selbst ausgeliefert, ist der Server
  // dieselbe Adresse.
  late final _url = TextEditingController(
    text: ref.read(syncProvider).serverUrl.isEmpty && kIsWeb
        ? Uri.base.origin
        : ref.read(syncProvider).serverUrl,
  );
  final _email = TextEditingController();
  final _passwort = TextEditingController();
  var _meldetAn = false;

  @override
  void dispose() {
    _url.dispose();
    _email.dispose();
    _passwort.dispose();
    super.dispose();
  }

  Future<void> _anmelden() async {
    setState(() => _meldetAn = true);
    try {
      await ref
          .read(syncProvider.notifier)
          .anmelden(
            url: _url.text,
            email: _email.text,
            passwort: _passwort.text,
          );
      _passwort.clear();
    } on ClientException catch (e) {
      if (mounted) {
        meldung(context, switch (e.statusCode) {
          0 => 'Server nicht erreichbar. Adresse und Netzwerk prüfen.',
          400 => 'E-Mail oder Passwort falsch.',
          _ => 'Anmeldung fehlgeschlagen (${e.statusCode}).',
        }, fehler: true);
      }
    } catch (e) {
      if (mounted) {
        meldung(context, 'Anmeldung fehlgeschlagen: $e', fehler: true);
      }
    } finally {
      if (mounted) setState(() => _meldetAn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncProvider);
    final ungesendet = ref.watch(ungesendetProvider).value ?? 0;

    if (sync.angemeldet) {
      return _Abschnitt(
        titel: 'Gemeinsame Daten',
        kinder: [
          _Zeile('Server', sync.serverUrl),
          _Zeile('Angemeldet als', sync.benutzer!),
          _Zeile(
            'Letzter Abgleich',
            sync.letzterErfolg == null ? '–' : zeitAnzeige(sync.letzterErfolg!),
          ),
          _Zeile('Noch nicht gesendet', '$ungesendet Änderungen'),
          if (sync.fehler != null)
            Text(
              sync.fehler!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: sync.laeuft
                    ? null
                    : ref.read(syncProvider.notifier).jetztAbgleichen,
                icon: const Icon(Icons.sync),
                label: const Text('Jetzt abgleichen'),
              ),
              OutlinedButton(
                onPressed: ref.read(syncProvider.notifier).abmelden,
                child: const Text('Abmelden'),
              ),
            ],
          ),
        ],
      );
    }

    return _Abschnitt(
      titel: 'Gemeinsame Daten',
      kinder: [
        const Text(
          'Ohne Anmeldung speichert Hauslog nur auf diesem Gerät. '
          'Mit einem Hauslog-Server (z. B. auf NAS oder Raspberry Pi) teilen '
          'alle Benutzer dieselben Zähler – auch offline erfasste Werte '
          'werden später abgeglichen.',
        ),
        TextField(
          controller: _url,
          decoration: const InputDecoration(
            labelText: 'Server-Adresse',
            hintText: 'http://raspberrypi.local:8090',
          ),
          keyboardType: TextInputType.url,
        ),
        TextField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'E-Mail'),
          keyboardType: TextInputType.emailAddress,
        ),
        TextField(
          controller: _passwort,
          decoration: const InputDecoration(labelText: 'Passwort'),
          obscureText: true,
          onSubmitted: (_) => _anmelden(),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _meldetAn ? null : _anmelden,
            child: _meldetAn
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Anmelden'),
          ),
        ),
      ],
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile(this.titel, this.wert);

  final String titel;
  final String wert;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 170, child: Text(titel)),
      Expanded(child: SelectableText(wert)),
    ],
  );
}

// ── Export / Import ─────────────────────────────────────────────────────────

class _DatenKarte extends ConsumerWidget {
  const _DatenKarte();

  Future<void> _exportieren(
    BuildContext context,
    WidgetRef ref, {
    required String endung,
    required String typ,
    required Uint8List Function(List<Zaehler>, List<Ablesung>) erzeugen,
  }) async {
    final db = ref.read(datenbankProvider);
    final bytes = erzeugen(await db.alleZaehler(), await db.alleAblesungen());
    try {
      final ziel = await dateiSpeichern(
        name: 'hauslog.$endung',
        endung: endung,
        typ: typ,
        bytes: bytes,
      );
      if (ziel != null && context.mounted) {
        meldung(context, 'Exportiert: $ziel');
      }
    } catch (e) {
      if (context.mounted) {
        meldung(context, 'Export fehlgeschlagen: $e', fehler: true);
      }
    }
  }

  Future<void> _importieren(BuildContext context, WidgetRef ref) async {
    try {
      final eintraege = await altDatenbankLesen();
      if (eintraege == null || !context.mounted) return;
      if (eintraege.isEmpty) {
        meldung(context, 'Die Datei enthält keine Verbrauchsmanager-Daten.');
        return;
      }
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importieren?'),
          content: Text(
            '${eintraege.length} Einträge werden als Ablesungen übernommen. '
            'Dafür werden neue Zähler „Strom“, „Wasser“ und „Gas“ angelegt.\n\n'
            'Mehrfaches Importieren legt die Daten mehrfach an.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Importieren'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final anzahl = await altDatenImportieren(
        ref.read(datenbankProvider),
        eintraege,
      );
      if (context.mounted) meldung(context, '$anzahl Ablesungen importiert.');
    } catch (e) {
      if (context.mounted) {
        meldung(context, 'Import fehlgeschlagen: $e', fehler: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Abschnitt(
    titel: 'Daten',
    kinder: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _exportieren(
              context,
              ref,
              endung: 'csv',
              typ: 'CSV',
              erzeugen: csvErzeugen,
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Als CSV exportieren'),
          ),
          OutlinedButton.icon(
            onPressed: () => _exportieren(
              context,
              ref,
              endung: 'xlsx',
              typ: 'Excel',
              erzeugen: xlsxErzeugen,
            ),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Als Excel exportieren'),
          ),
          if (altImportMoeglich)
            OutlinedButton.icon(
              onPressed: () => _importieren(context, ref),
              icon: const Icon(Icons.upload_file),
              label: const Text('Alte Verbrauchsmanager-Datenbank importieren'),
            ),
        ],
      ),
      FutureBuilder(
        future: datenOrdner(),
        builder: (context, ordner) => Text(
          ordner.data == null
              ? 'Die Daten liegen im Speicher dieses Browsers.'
              : 'Lokale Daten: ${ordner.data}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ],
  );
}
