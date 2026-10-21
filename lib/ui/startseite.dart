import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_steuerung.dart';
import '../zustand.dart';
import 'einstellungen.dart';
import 'formate.dart';
import 'zaehler_liste.dart';

class Startseite extends StatefulWidget {
  const Startseite({super.key});

  @override
  State<Startseite> createState() => _StartseiteState();
}

class _StartseiteState extends State<Startseite> {
  var _seite = 0;

  static const _ziele = [
    (Icons.speed_outlined, Icons.speed, 'Zähler'),
    (Icons.settings_outlined, Icons.settings, 'Einstellungen'),
  ];

  @override
  Widget build(BuildContext context) {
    final breit = MediaQuery.sizeOf(context).width >= 720;
    final inhalt = IndexedStack(
      index: _seite,
      children: const [ZaehlerListe(), Einstellungen()],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hauslog'),
        actions: const [_SyncAnzeige(), SizedBox(width: 8)],
      ),
      body: breit
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _seite,
                  onDestinationSelected: (i) => setState(() => _seite = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final (aus, an, text) in _ziele)
                      NavigationRailDestination(
                        icon: Icon(aus),
                        selectedIcon: Icon(an),
                        label: Text(text),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: inhalt),
              ],
            )
          : inhalt,
      bottomNavigationBar: breit
          ? null
          : NavigationBar(
              selectedIndex: _seite,
              onDestinationSelected: (i) => setState(() => _seite = i),
              destinations: [
                for (final (aus, an, text) in _ziele)
                  NavigationDestination(
                    icon: Icon(aus),
                    selectedIcon: Icon(an),
                    label: text,
                  ),
              ],
            ),
    );
  }
}

/// Symbol oben rechts: Stand des Abgleichs. Antippen gleicht sofort ab.
class _SyncAnzeige extends ConsumerWidget {
  const _SyncAnzeige();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);
    final ungesendet = ref.watch(ungesendetProvider).value ?? 0;

    final (symbol, text) = switch (sync) {
      SyncZustand(angemeldet: false) => (
        Icons.cloud_off_outlined,
        'Nur auf diesem Gerät gespeichert',
      ),
      SyncZustand(laeuft: true) => (Icons.sync, 'Gleiche ab …'),
      SyncZustand(fehler: final f?) => (Icons.cloud_off, f),
      _ when ungesendet > 0 => (
        Icons.cloud_upload_outlined,
        '$ungesendet Änderungen warten auf Abgleich',
      ),
      SyncZustand(letzterErfolg: final t?) => (
        Icons.cloud_done_outlined,
        'Abgeglichen ${zeitAnzeige(t)}',
      ),
      _ => (Icons.cloud_outlined, 'Verbunden'),
    };

    return IconButton(
      tooltip: text,
      icon: Badge(
        isLabelVisible: sync.angemeldet && ungesendet > 0,
        label: Text('$ungesendet'),
        child: Icon(symbol),
      ),
      onPressed: sync.angemeldet
          ? ref.read(syncProvider.notifier).jetztAbgleichen
          : null,
    );
  }
}
