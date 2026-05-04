# Refactor Tracker

Dieses Dokument ist die gemeinsame Arbeitsgrundlage fuer laufende Modernisierung, Aufraeumarbeiten und Umbauten im Projekt.

## Zweck

- Festhalten, was noch zu tun ist
- Sichtbar machen, woran gerade gearbeitet wird
- Dokumentieren, was bereits erledigt wurde
- Verhindern, dass mehrere Umbauten gleichzeitig unkoordiniert passieren

## Arbeitsregeln

- Immer nur einen klar abgegrenzten Bereich gleichzeitig bearbeiten
- Erst Struktur und Lesbarkeit verbessern, dann modernisieren
- Keine grossen Umbauten parallel in mehreren Spielen
- Vor jedem neuen Schritt `In Arbeit` aktualisieren
- Nach jedem abgeschlossenen Schritt Eintrag nach `Erledigt` verschieben
- Wenn sich Prioritaeten aendern, nur die Reihenfolge in `Backlog` anpassen

## Status

### In Arbeit

- Noch nichts aktiv in Bearbeitung

### Naechster Fokus

1. `Games/Imposter/Models/GameLogic.swift`
2. `Games/Imposter/Views/GamePlayView.swift`

## Backlog

### Phase 1: Imposter

- `Games/Imposter/Models/GameLogic.swift`
  Ziel: Spielablauf vereinfachen, Verantwortlichkeiten trennen, Logik lesbarer machen
- `Games/Imposter/Views/GamePlayView.swift`
  Ziel: Anzeige von Spiellogik entkoppeln, grosse Ansicht in kleinere Teile aufteilen
- Verwandte Services in `Games/Imposter/Services/`
  Ziel: Hilfslogik sauber einordnen und Doppelungen abbauen
- Kleinere Komponenten in `Games/Imposter/Views/Components/`
  Ziel: nur nachziehen, wenn Kernlogik und Hauptansicht klar sind

### Phase 2: TimesUp

- `Games/TimesUp/Managers/GameManager.swift`
  Ziel: Kernlogik aufraeumen und besser strukturieren
- `Games/TimesUp/Views/TimesUpGameView.swift`
  Ziel: grosse Spielansicht lesbarer und wartbarer machen
- `Games/TimesUp/Views/SettingsView.swift`
  Ziel: Einstellungslogik und Anzeige vereinfachen

### Phase 3: Bet Buddy und Falsche Faehrte

- `Games/Bet Buddy/Services/AlphabetHints.swift`
  Ziel: grosse Daten- und Hinweislogik besser ordnen
- `Games/Bet Buddy/ViewModels/AppViewModel.swift`
  Ziel: Zustandslogik klarer machen
- `Games/Falsche Faehrte/Views/FFSetupView.swift`
  Ziel: Setup-Ansicht in kleinere, klar erkennbare Teile zerlegen

### Phase 4: Projektweite Vereinheitlichung

- `Games Collection/ContentView.swift`
  Ziel: zentrale Einstiegslogik erst nach den Spielumbauten bereinigen
- Gemeinsame Muster fuer Buttons, Header, Einstellungen, Timer und Feedback pruefen
- Veraltete oder uneinheitliche Wege projektweit vereinheitlichen
- Moderne APIs erst nach strukturellem Aufraeumen gezielt uebernehmen

## Erledigt

- Refactor- und Modernisierungsreihenfolge fuer das Projekt festgelegt
- Gemeinsame Tracking-Datei erstellt

## Notizen

- Zeilenzahl allein entscheidet nicht ueber Prioritaet
- Zuerst die Dateien mit dem meisten Pflegeaufwand und dem hoechsten Risiko
- Erst pro Spiel Ordnung schaffen, danach projektweit vereinheitlichen

## Update-Vorlage

Bei Beginn eines Schritts:

- `In Arbeit`: Dateiname + kurzes Ziel eintragen

Bei Abschluss eines Schritts:

- Eintrag aus `In Arbeit` entfernen
- Kurzen Satz unter `Erledigt` ergaenzen
- Falls noetig `Naechster Fokus` anpassen
