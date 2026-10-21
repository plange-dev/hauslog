/// <reference path="../pb_data/types.d.ts" />

// Jeder angemeldete Benutzer sieht alle Hauslog-Daten. Deshalb darf sich
// niemand selbst registrieren – Benutzer legt der Admin im PocketBase-
// Dashboard an (Collections → users → New record).

migrate(
  (app) => {
    const users = app.findCollectionByNameOrId("users");
    users.createRule = null;
    app.save(users);
  },
  (app) => {
    const users = app.findCollectionByNameOrId("users");
    users.createRule = "";
    app.save(users);
  },
);
