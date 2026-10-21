/// <reference path="../pb_data/types.d.ts" />

// Hauslog-Schema: Zähler und Ablesungen.
//
// Die IDs vergibt die App selbst (offline-fähig), deshalb ist `zaehler` in
// `ablesungen` bewusst ein Textfeld und keine Relation – sonst könnte eine
// Ablesung nicht vor ihrem Zähler synchronisiert werden.
//
// Gelöscht wird nie hart, sondern über `geloescht = true`, damit die Löschung
// auch bei Geräten ankommt, die gerade offline sind.
// `geaendert_am` (ms seit 1970, gesetzt von der App) entscheidet bei
// Konflikten: der neuere Stand gewinnt.

const NUR_ANGEMELDET = "@request.auth.id != ''";

function syncFelder() {
  return [
    { type: "number", name: "geaendert_am", required: true, onlyInt: true },
    { type: "bool", name: "geloescht" },
    { type: "autodate", name: "created", onCreate: true, onUpdate: false },
    { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
  ];
}

function regeln() {
  return {
    listRule: NUR_ANGEMELDET,
    viewRule: NUR_ANGEMELDET,
    createRule: NUR_ANGEMELDET,
    updateRule: NUR_ANGEMELDET,
    deleteRule: null,
  };
}

migrate(
  (app) => {
    const zaehler = new Collection({
      type: "base",
      name: "zaehler",
      ...regeln(),
      fields: [
        { type: "text", name: "name", required: true, max: 200 },
        { type: "text", name: "art", required: true, max: 50 },
        { type: "text", name: "einheit", required: true, max: 20 },
        { type: "text", name: "zaehlernummer", max: 100 },
        { type: "text", name: "notiz", max: 2000 },
        ...syncFelder(),
      ],
      indexes: ["CREATE INDEX idx_zaehler_updated ON zaehler (updated)"],
    });
    app.save(zaehler);

    const ablesungen = new Collection({
      type: "base",
      name: "ablesungen",
      ...regeln(),
      fields: [
        { type: "text", name: "zaehler", required: true, max: 50 },
        { type: "text", name: "datum", required: true, pattern: "^\\d{4}-\\d{2}-\\d{2}$" },
        { type: "number", name: "stand", min: 0 },
        { type: "text", name: "notiz", max: 2000 },
        ...syncFelder(),
      ],
      indexes: [
        "CREATE INDEX idx_ablesungen_updated ON ablesungen (updated)",
        "CREATE INDEX idx_ablesungen_zaehler ON ablesungen (zaehler, datum)",
      ],
    });
    app.save(ablesungen);
  },
  (app) => {
    for (const name of ["ablesungen", "zaehler"]) {
      app.delete(app.findCollectionByNameOrId(name));
    }
  },
);
