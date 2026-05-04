# PARTY SESSION — Implementierungsplan & Live-Tracking
## Meta-Session: Mehrere Spiele · Gesamtwertung · Party-Abend
### Erstellt: 2026-04-14

> **Diese Datei ist das einzige Dokument für dieses Feature.**
> Bei Verbindungsabbruch: Hier nachschauen. Status, Dateipfade, nächste Schritte — alles hier.

---

## AKTUELLER STAND

```
📍 GERADE HIER → Phase 1 vollständig implementiert · Xcode-Import ausstehend
```

| Phase | Inhalt | Status |
|-------|--------|--------|
| 1 | Datenmodell + ViewModel + alle Views | ✅ FERTIG (Dateien erstellt) |
| 2 | Xcode: Dateien ins Target einbinden | ⬜ MANUELL NÖTIG |
| 3 | Testen im Simulator | ⬜ AUSSTEHEND |
| 4 | Lokalisierung + Polishing | ⬜ AUSSTEHEND |

---

## WAS GEBAUT WURDE

### Feature-Beschreibung

"Party starten" auf dem Hauptscreen öffnet einen vollständigen Session-Flow:
1. Spieler auswählen (aus bestehender Crew oder neu eingeben)
2. 2–6 Spiele auswählen (in beliebiger Reihenfolge)
3. Spiele werden nacheinander gespielt — jedes als vollständige App-Session
4. Nach jedem Spiel: kurze Ergebniseingabe (wer hat gewonnen?)
5. Am Ende: Party-Recap mit Gesamtwertung und Sieger

### Punkte-System
- Gewinner eines Spiels: **+3 Punkte**
- Alle anderen: **+1 Punkt**
- Mehrere Gewinner möglich (z.B. bei Unentschieden)

---

## DATEISTRUKTUR

```
Games Collection/
├── Party/                          ← Neuer Ordner (muss in Xcode eingebunden werden)
│   ├── PartySession.swift          ✅ Erstellt — Datenmodelle
│   ├── PartySessionManager.swift   ✅ Erstellt — ViewModel / State
│   ├── PartyWrapper.swift          ✅ Erstellt — Root-View / Router
│   └── Views/
│       ├── PartySetupView.swift    ✅ Erstellt — Spieler + Spiele auswählen
│       ├── PartyHubView.swift      ✅ Erstellt — Session-Orchestrator
│       ├── PartyBridgeView.swift   ✅ Erstellt — Ergebnisse nach jedem Spiel
│       └── PartyRecapView.swift    ✅ Erstellt — Finale Gesamtwertung
│
└── ContentView.swift               ✅ Modifiziert — Party-Banner + fullScreenCover
```

---

## PHASE 1 — Implementierung ✅

### PartySession.swift
- `PartyGame` Enum: alle 6 Spiele mit Name, Icon, Gradient
- `PartyPlayer`: Spieler mit ID, Name, Gesamtpunktestand
- `PartyGameResult`: Ergebnis eines einzelnen Spiels (Gewinner-IDs, Punkte pro Spieler)
- `PartySession`: Die komplette Session (Spieler, Spiele, Ergebnisse, aktueller Index, State)

### PartySessionManager.swift
- `@Published var session: PartySession?` — der gesamte Session-State
- `@Published var showBridge: Bool` — Bridge-Sheet steuern
- `startSession(players:games:)` — neue Session erstellen
- `gameDismissed()` — Game wurde verlassen, Bridge anzeigen
- `recordResult(winnerIDs:)` — Ergebnis speichern, Punkte verteilen, nächstes Spiel
- `endSession()` — Session beenden

### PartyWrapper.swift
- Routing zwischen Setup → Hub → Recap
- Hält `@StateObject private var manager`

### PartySetupView.swift
- Spieler-Auswahl: Crew-Bubbles aus GlobalPlayerManager + "+" für eigene Namen
- Spiel-Auswahl: 2×3 Grid der 6 Spiele, tippen zum Auswählen
- Reihenfolge: Spiele werden in Tap-Reihenfolge gespielt (Zahl-Badge)
- Start-Button: aktiviert sich ab 2 Spielern + 2 Spielen

### PartyHubView.swift
- Fortschritts-Chips oben (Spiel 1, 2, 3 ..., aktuelles hervorgehoben)
- Große Hero-Card des aktuellen Spiels
- "Jetzt spielen" → fullScreenCover mit dem jeweiligen Game-Wrapper
- Nach Game-Dismiss → `manager.gameDismissed()` → Bridge-Sheet

### PartyBridgeView.swift
- Sheet nach jedem Spiel
- Spieler-Liste mit Gewinner-Toggle (Stern/Häkchen)
- Punkte-Vorschau: "+3 Gewinner · +1 Andere"
- "Weiter" → `manager.recordResult(winnerIDs:)`

### PartyRecapView.swift
- Podium: 1. Platz groß in der Mitte, 2. links, 3. rechts
- Vollständige Rangliste darunter
- Spiel-für-Spiel Zusammenfassung
- "Neue Party" / "Fertig" Buttons

### ContentView.swift Änderungen
- `@State private var isPartyPresented = false` (neu)
- Gold-Banner "Party starten" vor dem Spielgrid eingefügt
- `.fullScreenCover(isPresented: $isPartyPresented) { PartyWrapper() }` (neu)

---

## PHASE 2 — Xcode-Import ⬜ MANUELL

> ⚠️ **Diese Schritte müssen manuell in Xcode gemacht werden**

1. **Xcode öffnen**
2. Im **Project Navigator** (links) auf das Projekt-Root klicken
3. Rechtsklick auf den `Games Collection` Ordner → **"Add Files to Games Collection..."**
4. Den Ordner `Party/` auswählen (bei `/Games Collection/Games Collection/Party/`)
5. Sicherstellen: ✅ **"Add to target: Games Collection"** ist angehakt
6. Klick auf **"Add"**
7. Xcode sollte jetzt alle 7 Party-Dateien im Navigator zeigen
8. **Cmd+B** → Build — es sollten 0 Errors sein

---

## PHASE 3 — Testen ⬜

Folgende Szenarien im Simulator testen:

| Test | Erwartet |
|------|----------|
| Party starten → Setup erscheint | ✅ Gold-Banner, Setup-View |
| 0 Spieler auswählen → Start-Button grau | ✅ Disabled |
| 1 Spiel auswählen → Start-Button grau | ✅ Disabled |
| 2+ Spieler + 2+ Spiele → Start aktiv | ✅ Enabled |
| Spiel starten → Game-Wrapper öffnet | ✅ fullScreenCover |
| Game verlassen → Bridge-Sheet | ✅ "Wer hat gewonnen?" |
| Gewinner auswählen → Weiter | ✅ Punkte aktualisiert, nächstes Spiel |
| Letztes Spiel fertig → Recap | ✅ Podium + Rangliste |
| "Neue Party" → zurück zu Setup | ✅ Fresh Start |
| "Fertig" → zurück zu ContentView | ✅ Dismiss |

---

## PHASE 4 — Polishing ⬜

| Aufgabe | Priorität |
|---------|-----------|
| DE-Strings in Localizable.strings eintragen | 🟠 Hoch |
| Animationen testen auf echter Hardware (120fps) | 🟠 Hoch |
| Haptics beim Gewinner-Toggle + Recap | 🟡 Mittel |
| `accessibilityLabel` für alle interaktiven Elemente | 🟡 Mittel |
| Party-Session in UserDefaults persistieren (Resume nach App-Kill) | 🟢 Nice-to-have |
| Push-Notification "Deine Party wartet" nach 7 Tagen ohne Session | 🟢 Nice-to-have |

---

## BEKANNTE EINSCHRÄNKUNGEN / ENTSCHEIDUNGEN

| Thema | Entscheidung |
|-------|-------------|
| Punkte-Erfassung | Manuell nach jedem Spiel — keine automatische Hook-in in Spiellogik |
| Spieler-Persistenz | Nur während der Session im Speicher — kein UserDefaults |
| Spiel-Reihenfolge | Festgelegt bei Setup, nicht änderbar während der Session |
| Min. Spieler | 2 |
| Min. Spiele | 2 |
| Max. Spiele | Alle 6 |
| Multiplayer | Nicht unterstützt in V1 — nur Single-Device Session |

---

## OFFENE FRAGEN (für spätere Versionen)

- [ ] Soll die Session nach App-Kill wiederherstellbar sein?
- [ ] Soll der Gastgeber die Spielreihenfolge während der Session ändern können?
- [ ] Sollen Teams statt Einzelspieler bewertet werden?
- [ ] Soll der Recap geteilt werden können (Screenshot/Share-Sheet)?

---

*Erstellt: 2026-04-14 — Phase 1 implementiert*
