# Falsche Fährte — Implementierungsplan

## Ziel
Neues Party-Spiel "Falsche Fährte" (Fibbage-inspiriert) als 6. Spiel integrieren.
iOS 26, Modern, Premium, DAU-sicher, aus einem Guss mit den anderen Spielen.

## Spielprinzip
1. App zeigt eine seltsame, aber wahre Frage (z.B. "Womit putzten sich Römer die Zähne?")
2. Jeder Spieler tippt eine glaubwürdige Lüge ein
3. Alle Antworten (Lügen + echte Antwort) erscheinen auf dem Screen
4. Jeder muss tippen: Was ist die Wahrheit?
5. Punkte: Wahrheit erraten (2 Pkt) + andere mit eigener Lüge täuschen (1 Pkt pro getäuschtem Spieler)

## Design-Entscheidungen
- **Theme-Farbe:** Violett/Indigo (#7B5CF0) — "Verhör/Detektiv-Ästhetik"
- **Icon:** `magnifyingglass.circle.fill` / `questionmark.bubble.fill`
- **Modi:** Single-Device (reihum eingeben) UND Multi-Device (MPC, jeder auf eigenem Handy)
- **Fragen-Datenbank:** 120+ kuriose wahre Fakten (DE+EN), 3 Packs
- **Kein Ausscheiden** — alle spielen bis zum Ende, Punkte entscheiden

## Phasen-Übersicht

| Phase | Inhalt | Status |
|-------|--------|--------|
| 1 | Struktur + Models + 120+ Fragen JSON | ✅ done |
| 2 | Style + ViewModel + Spiellogik | pending |
| 3 | SetupView + Wrapper | ✅ done |
| 4 | Spielphasen-Views (Bluffen → Abstimmen → Auflösung) | ✅ done |
| 5 | GameOverView + ContentView-Integration + Lokalisierung | ✅ done |

## Ziel-Dateistruktur
```
Games/Falsche Faehrte/
├── FalscheFaehrteWrapper.swift
├── Models/
│   ├── FFQuestion.swift
│   ├── FFPlayer.swift
│   ├── FFSettings.swift
│   └── FFRound.swift
├── ViewModels/
│   └── FFViewModel.swift
├── Views/
│   ├── FFSetupView.swift
│   ├── FFBluffPhaseView.swift
│   ├── FFVotePhaseView.swift
│   ├── FFRevealPhaseView.swift
│   └── FFGameOverView.swift
├── Components/
│   ├── FFStyle.swift
│   └── FFAnswerCard.swift
└── Resources/
    └── ff_questions.json
```

## Entscheidungen-Log
- Prefix FF (FalscheFaehrte) für alle Types um Konflikte zu vermeiden
- Single-Device-Modus first, MPC als Erweiterung
- 3 Fragen-Packs: Klassisch / Krass / Extrem
- Punkte-System: 2 für Wahrheit + 1 pro getäuschten Spieler (Fibbage-bewährt)
- Antworten werden zufällig gemischt angezeigt (echte Antwort nicht markiert)
