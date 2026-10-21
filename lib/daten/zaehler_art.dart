import 'package:flutter/material.dart';

/// Vorlagen für Zählerarten. Gespeichert wird nur [name]; Einheit und
/// Bezeichnung des Zählers sind frei änderbar.
enum ZaehlerArt {
  strom('Strom', 'kWh', Icons.bolt, Color(0xFFF4A261)),
  wasser('Wasser', 'm³', Icons.water_drop, Color(0xFF457B9D)),
  warmwasser('Warmwasser', 'm³', Icons.hot_tub, Color(0xFFE76F51)),
  gas('Gas', 'm³', Icons.local_fire_department, Color(0xFF52B788)),
  waerme('Wärme', 'kWh', Icons.thermostat, Color(0xFFD62828)),
  heizoel('Heizöl', 'l', Icons.oil_barrel, Color(0xFF6D597A)),
  einspeisung('PV-Einspeisung', 'kWh', Icons.solar_power, Color(0xFFE9C46A)),
  sonstiges('Sonstiges', '', Icons.speed, Color(0xFF8D99AE));

  const ZaehlerArt(this.label, this.einheit, this.symbol, this.farbe);

  final String label;
  final String einheit;
  final IconData symbol;
  final Color farbe;

  static ZaehlerArt ausName(String name) => ZaehlerArt.values.firstWhere(
    (a) => a.name == name,
    orElse: () => ZaehlerArt.sonstiges,
  );
}
