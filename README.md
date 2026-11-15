# Roadbook Weihnachtspäckchenkonvoi

Webanwendung zum Planen der Hinreise eines Hilfskonvois mit Pkw, Lkw und Reisebussen:

- **Planung:** Start, Ziel, Pausen mit Fahrerwechsel, Zwischenhalte und Hinweise (z. B. Grenze, GO-Box), Lkw-Route über OpenStreetMap, Kartenausschnitte, Teams mit Konvoiteilung, Fahrzeuge mit Rufname, Kennzeichen und Besatzung, Ansprechpartner, Infoseiten
- **Roadbook:** Zeitplan mit Ankunft und Abfahrt, Warnung bei mehr als 4 Stunden ohne Fahrerwechsel, PDF mit Etappen-Seiten, Detailkarten, ausfüllbarem Tankprotokoll (auch am Smartphone oder Tablet) und Notizseite
- **Päckchen zählen:** Ladeliste (Excel/CSV) einlesen, Abgaben erfassen, Restbestand je Geschlecht und Altersgruppe, Ladeplan je Auflieger (13,60 m, 33 Palettenstellplätze) mit verfügbaren Päckchen je Stellplatz

Alle Felder sind beim ersten Öffnen leer. Leere Zahlenfelder rechnen mit den grau angezeigten Standardwerten (z. B. Lkw-Schnitt 70 km/h, Fahrerwechsel nach 4 Stunden). Vorlagen für Infoseiten lassen sich per Knopfdruck einfügen.

Mehrere Personen arbeiten gleichzeitig am selben Konvoi. Änderungen erscheinen bei allen sofort.

## Inhalt des Repositorys

| Datei | Zweck |
|---|---|
| `index.html` | Die komplette Anwendung |
| `config.js` | Verbindung zur Datenbank (Supabase-Adresse und öffentlicher Schlüssel) |
| `supabase/einrichtung.sql` | Richtet Tabellen, Zugriffsregeln und Echtzeit in Supabase ein |
| `.nojekyll` | Sorgt dafür, dass GitHub Pages die Dateien unverändert ausliefert |

Im Repository liegen **keine Konvoidaten**. Namen, Telefonnummern und Kennzeichen stehen nur in der geschützten Datenbank.

---

## Einrichtung (einmalig, ca. 30 Minuten)

### 1. Datenbank bei Supabase anlegen

1. Kostenloses Konto auf [supabase.com](https://supabase.com) anlegen.
2. **New project** anlegen. Als Region **Central EU (Frankfurt)** wählen. Das Datenbank-Passwort sicher aufbewahren (wird für das Roadbook nicht gebraucht).
3. Links **SQL Editor** öffnen, den Inhalt von `supabase/einrichtung.sql` einfügen.
   In der **letzten Anweisung** deine E-Mail-Adresse und deinen Namen eintragen, dann **Run**.
4. **Authentication → Sign In / Providers:** „Allow new users to sign up“ **ausschalten**. So kann sich niemand selbst registrieren.
5. **Authentication → Users → Add user → Create new user:** deine E-Mail-Adresse und ein Passwort eintragen, „Auto Confirm User“ anhaken.
6. **Project Settings → API Keys:** die **Project URL** und den **Publishable key** (beginnt mit `sb_publishable_`, alternativ der „anon public“ key) kopieren.
   Den *secret* bzw. *service_role* key niemals verwenden.

### 2. Auf GitHub veröffentlichen

1. Auf GitHub ein neues Repository anlegen, z. B. `roadbook`. Es darf öffentlich sein.
2. Alle Dateien dieses Ordners hochladen („Add file → Upload files“), auch den Ordner `supabase` und die Datei `.nojekyll`.
3. `config.js` im Repository öffnen (Stift-Symbol) und die beiden Werte aus Schritt 1.6 eintragen:
   ```js
   window.ROADBOOK_CONFIG = {
     supabaseUrl: "https://deinprojekt.supabase.co",
     supabaseAnonKey: "sb_publishable_..."
   };
   ```
4. **Settings → Pages:** unter „Build and deployment“ als Quelle **Deploy from a branch**, Branch **main**, Ordner **/(root)** wählen und speichern.
   Nach ein bis zwei Minuten ist das Roadbook unter `https://<dein-github-name>.github.io/roadbook/` erreichbar.

### 3. Adresse in Supabase hinterlegen

**Authentication → URL Configuration:** als **Site URL** die GitHub-Pages-Adresse eintragen und sie auch unter **Redirect URLs** hinzufügen. Das braucht die Funktion „Passwort vergessen“.

### 4. Ausprobieren

Adresse öffnen, anmelden, **Neuen Konvoi anlegen**. Wer schon im Browser geplant hat, hakt „Daten aus diesem Browser übernehmen“ an.

---

## Weitere Personen hinzufügen

1. **Authentication → Users → Add user → Create new user**: E-Mail, Startpasswort, „Auto Confirm User“.
2. **Table Editor → mitglieder → Insert row**: dieselbe E-Mail, Name und Rolle:
   - `planer`: darf alles planen und ändern, Konvois anlegen
   - `leser`: sieht alles, exportiert das PDF und erfasst Päckchen-Abgaben
3. Adresse und Startpasswort weitergeben. Das Passwort lässt sich über „Passwort vergessen“ selbst ändern.

Jemanden entfernen: Zeile in `mitglieder` löschen und den Nutzer unter Authentication → Users löschen.

## So funktioniert die Zusammenarbeit

- Die Planung ist in Bereiche aufgeteilt (Konvoi, Strecke, Route, Fahrzeuge/Teams, Ladeliste, jede Abgabe einzeln). Wer an verschiedenen Bereichen arbeitet, kommt sich nicht in die Quere.
- Ändern zwei Personen **denselben** Bereich im selben Moment, gewinnt die erste Speicherung. Die zweite Person bekommt einen Hinweis und sieht den neuen Stand.
- Ohne Internet bleiben Änderungen im Browser und werden gespeichert, sobald die Verbindung zurück ist (Statusleiste oben).
- Karten werden in jedem Browser selbst erzeugt und nicht in der Datenbank gespeichert.

## Ohne Datenbank nutzen

Bleiben in `config.js` beide Werte leer, läuft das Roadbook ohne Anmeldung. Die Daten liegen dann nur im jeweiligen Browser und lassen sich über „Daten sichern und übertragen“ weitergeben.

## Aktualisieren

Neue Version: `index.html` im Repository ersetzen. `config.js` bleibt unverändert. Die Daten in Supabase bleiben erhalten.

## Datenschutz

- Gespeichert werden personenbezogene Daten der Teilnehmenden (Namen, Telefonnummern, Kennzeichen, E-Mail-Adressen der Nutzer). Nur so viel eintragen, wie für den Konvoi nötig ist.
- Projekt-Region Frankfurt wählen. Den Auftragsverarbeitungsvertrag (DPA) stellt Supabase im Dashboard bzw. auf seiner Website bereit; für Vereine und gGmbHs sollte er abgeschlossen werden.
- Ortssuche, Routen und Kartenkacheln werden direkt aus dem Browser bei OpenStreetMap-Diensten und CARTO abgefragt. Dabei werden Suchbegriffe und Kartenausschnitte, aber keine Teilnehmerdaten übertragen.
- Die Teilnehmenden sollten wissen, dass ihre Daten im Roadbook gespeichert werden.

## Genutzte Dienste und faire Nutzung

| Dienst | Wofür | Hinweis |
|---|---|---|
| Supabase (Free Plan) | Anmeldung, gemeinsame Daten, Echtzeit | Kostenlose Projekte werden nach etwa einer Woche ohne Nutzung pausiert und lassen sich im Dashboard mit einem Klick fortsetzen |
| Nominatim (OpenStreetMap) | Ortssuche | höchstens eine Suche pro Sekunde |
| Valhalla (FOSSGIS) | Lkw-Route | Ersatzweise OSRM-Demoserver (Pkw-Route, wird angezeigt) |
| CARTO, OpenStreetMap Deutschland, OpenTopoMap | Kartenkacheln | Quellenangabe steht auf jeder Karte und im PDF |

Die Dienste sind für gelegentliche Nutzung gedacht. Für ein Konvoi-Team ist das unproblematisch.

## Kontakt

Roadbook-Tool erstellt von **Björn Schirmer**.
Rückfragen und Verbesserungswünsche: bjoern.schirmer@wpk-ggmbh.de · 0173-7600974
