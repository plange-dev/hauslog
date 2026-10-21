import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../daten/datenbank.dart';
import '../daten/zaehler_art.dart';
import '../zustand.dart';
import 'formate.dart';

Future<bool> loeschenBestaetigen(BuildContext context, String frage) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen?'),
        content: Text(frage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    ) ??
    false;

void meldung(BuildContext context, String text, {bool fehler = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: fehler ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

// ── Zähler ──────────────────────────────────────────────────────────────────

/// Legt einen Zähler an oder bearbeitet [zaehler]. Gibt die ID zurück.
Future<String?> zaehlerBearbeiten(BuildContext context, {Zaehler? zaehler}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _ZaehlerDialog(zaehler: zaehler),
    );

class _ZaehlerDialog extends ConsumerStatefulWidget {
  const _ZaehlerDialog({this.zaehler});

  final Zaehler? zaehler;

  @override
  ConsumerState<_ZaehlerDialog> createState() => _ZaehlerDialogState();
}

class _ZaehlerDialogState extends ConsumerState<_ZaehlerDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.zaehler?.name);
  late final _einheit = TextEditingController(
    text: widget.zaehler?.einheit ?? ZaehlerArt.strom.einheit,
  );
  late final _nummer = TextEditingController(
    text: widget.zaehler?.zaehlernummer,
  );
  late final _notiz = TextEditingController(text: widget.zaehler?.notiz);
  late var _art = widget.zaehler == null
      ? ZaehlerArt.strom
      : ZaehlerArt.ausName(widget.zaehler!.art);

  @override
  void dispose() {
    for (final c in [_name, _einheit, _nummer, _notiz]) {
      c.dispose();
    }
    super.dispose();
  }

  void _artGewaehlt(ZaehlerArt? art) {
    if (art == null) return;
    setState(() {
      // Einheit nur nachziehen, wenn sie noch der Vorlage entspricht.
      if (_einheit.text == _art.einheit) _einheit.text = art.einheit;
      _art = art;
    });
  }

  Future<void> _speichern() async {
    if (!_form.currentState!.validate()) return;
    final id = await ref
        .read(datenbankProvider)
        .zaehlerSpeichern(
          id: widget.zaehler?.id,
          name: _name.text.trim(),
          art: _art.name,
          einheit: _einheit.text.trim(),
          zaehlernummer: _nummer.text.trim(),
          notiz: _notiz.text.trim(),
        );
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.zaehler == null ? 'Neuer Zähler' : 'Zähler bearbeiten',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                DropdownButtonFormField<ZaehlerArt>(
                  initialValue: _art,
                  decoration: const InputDecoration(labelText: 'Art'),
                  items: [
                    for (final a in ZaehlerArt.values)
                      DropdownMenuItem(
                        value: a,
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(a.symbol, color: a.farbe, size: 20),
                            Text(a.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: _artGewaehlt,
                ),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'z. B. Strom Hauptzähler',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Bitte einen Namen angeben'
                      : null,
                ),
                Row(
                  spacing: 12,
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _einheit,
                        decoration: const InputDecoration(labelText: 'Einheit'),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _nummer,
                        decoration: const InputDecoration(
                          labelText: 'Zählernummer (optional)',
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _notiz,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notiz (optional)',
                    hintText: 'z. B. Keller, links neben der Tür',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _speichern, child: const Text('Speichern')),
      ],
    );
  }
}

// ── Ablesung ────────────────────────────────────────────────────────────────

/// Erfasst eine neue Ablesung oder bearbeitet [ablesung].
/// [vorheriger] ist der zuletzt erfasste Stand, als Plausibilitätshinweis.
Future<void> ablesungBearbeiten(
  BuildContext context, {
  required Zaehler zaehler,
  Ablesung? ablesung,
  double? vorheriger,
}) => showDialog<void>(
  context: context,
  builder: (_) => _AblesungDialog(
    zaehler: zaehler,
    ablesung: ablesung,
    vorheriger: vorheriger,
  ),
);

class _AblesungDialog extends ConsumerStatefulWidget {
  const _AblesungDialog({
    required this.zaehler,
    this.ablesung,
    this.vorheriger,
  });

  final Zaehler zaehler;
  final Ablesung? ablesung;
  final double? vorheriger;

  @override
  ConsumerState<_AblesungDialog> createState() => _AblesungDialogState();
}

class _AblesungDialogState extends ConsumerState<_AblesungDialog> {
  final _form = GlobalKey<FormState>();
  late var _datum = widget.ablesung == null
      ? DateUtils.dateOnly(DateTime.now())
      : DateTime.parse(widget.ablesung!.datum);
  late final _stand = TextEditingController(
    text: widget.ablesung == null ? '' : zahlAnzeige(widget.ablesung!.stand),
  );
  late final _notiz = TextEditingController(text: widget.ablesung?.notiz);
  String? _hinweis;

  @override
  void dispose() {
    _stand.dispose();
    _notiz.dispose();
    super.dispose();
  }

  void _standGeaendert(String text) {
    final wert = zahlLesen(text);
    final vorher = widget.vorheriger;
    setState(() {
      _hinweis = wert != null && vorher != null && wert < vorher
          ? 'Kleiner als die letzte Ablesung (${zahlAnzeige(vorher)}) – '
                'Zähler getauscht?'
          : null;
    });
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (gewaehlt != null) setState(() => _datum = gewaehlt);
  }

  Future<void> _speichern() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(datenbankProvider)
        .ablesungSpeichern(
          id: widget.ablesung?.id,
          zaehlerId: widget.zaehler.id,
          datum: _datum,
          stand: zahlLesen(_stand.text)!,
          notiz: _notiz.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final einheit = widget.zaehler.einheit;
    return AlertDialog(
      title: Text(
        widget.ablesung == null ? 'Ablesung erfassen' : 'Ablesung bearbeiten',
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                widget.zaehler.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              OutlinedButton.icon(
                onPressed: _datumWaehlen,
                icon: const Icon(Icons.calendar_today),
                label: Text(datumAnzeige(_datum)),
              ),
              TextFormField(
                controller: _stand,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Zählerstand',
                  suffixText: einheit,
                  helperText: _hinweis,
                  helperStyle: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                onChanged: _standGeaendert,
                onFieldSubmitted: (_) => _speichern(),
                validator: (v) {
                  final wert = zahlLesen(v ?? '');
                  if (wert == null) return 'Bitte eine Zahl eingeben';
                  if (wert < 0) return 'Der Stand kann nicht negativ sein';
                  return null;
                },
              ),
              TextFormField(
                controller: _notiz,
                decoration: const InputDecoration(
                  labelText: 'Notiz (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _speichern, child: const Text('Speichern')),
      ],
    );
  }
}
