# ProMotion & Sheet-Performance Fix

> **Status:** Planung  
> **Problem:** Spiele öffnen sich ruckelig, nicht mit 120fps trotz iPhone 15 Pro Max (ProMotion)  
> **Betroffene Datei primär:** `Games Collection/ContentView.swift`, `Games/Falsche Faehrte/FalscheFaehrteWrapper.swift`, alle anderen Wrapper  

---

## Symptom

Beim Antippen einer Spielkarte wirkt die fullScreenCover-Animation nicht flüssig – sie fühlt sich nicht nach 120fps an, obwohl das iPhone 15 Pro Max ProMotion unterstützt.

---

## Ursachen (4 Stück)

### Ursache 1 – Künstlicher Delay blockiert den Main Thread (Hauptproblem)

**Datei:** `ContentView.swift` – alle 6 Spiel-Buttons (Zeilen 117, 131, 150, 164, 178, 191)

Was beim Antippen passiert:

```
Tap
 → Tap-Animation startet (.spring 0.25s)
 → DispatchQueue.main.asyncAfter(0.18s)   ← läuft auf Main Thread
 → isXxxPresented = true
 → SwiftUI baut sofort die View synchron:
     FFViewModel() initialisieren (lädt JSON-Fragen)
     FFSetupView aufbauen (855 Zeilen!)
 → fullScreenCover-Animation will starten
     → Main Thread ist gerade beschäftigt → Frame-Drop
```

Das `asyncAfter` läuft auf dem **Main Thread** – genau dort wo gleichzeitig die Cover-Animation ablaufen soll. Die View wird synchron gebaut, während die Animation losstarten will. Das erzeugt den sichtbaren Ruckler.

---

### Ursache 2 – `FFBackground` wird 6-mal gleichzeitig gerendert

**Datei:** `FalscheFaehrteWrapper.swift` (Zeile 11) + `FFSetupView.swift` (Zeilen 52, 219, 307, 359, 467, 782)

Der Wrapper hat bereits ein `FFBackground()`. Jede Sub-View und jedes Sheet innerhalb von `FFSetupView` rendert es nochmals. Beim Öffnen werden kurz mehrere dieser Hintergründe übereinander aufgebaut. Jeder enthält:
- Einen `ZStack`
- Einen `LinearGradient` (Hintergrundfarbe)
- Einen `RadialGradient` (violetter Glow oben)

Das ist unnötige Render-Arbeit genau in dem Moment wo die Animation smooth sein soll.

---

### Ursache 3 – Kein expliziter ProMotion-Hinweis

**Datei:** alle Wrapper + `ContentView.swift`

Das iPhone 15 Pro Max kann 120fps, aber SwiftUI aktiviert ProMotion **nur automatisch wenn**:
1. Der Main Thread frei ist (Ursache 1 verhindert das)
2. Ein expliziter Hinweis gegeben wird, dass 120fps erwünscht sind

Die aktuellen `.spring(response: 0.25)`-Animationen haben keine `preferredFrameRateRange`-Angabe. iOS wählt dann im Zweifel den "sicheren" Modus (60fps), besonders wenn der Main Thread kurz unter Last steht.

Die Lösung: In SwiftUI-Transactions explizit signalisieren dass hohe Frame-Rates gewünscht sind.

---

### Ursache 4 – Breite implizite Animation auf dem gesamten ZStack

**Datei:** `FalscheFaehrteWrapper.swift` (Zeile 30)

```swift
ZStack { ... }
.animation(.easeInOut(duration: 0.3), value: viewModel.gamePhase)
```

Diese Zeile animiert den **gesamten ZStack** bei jeder Phase-Änderung – also `FFBackground` + die aktuelle Phase-View gleichzeitig. SwiftUI muss den gesamten View-Baum neu berechnen. Besser wäre die Animation nur auf das `Group` mit den Phase-Views einzuengen.

---

## Lösungen

| # | Fix | Datei | Aufwand |
|---|---|---|---|
| 1 | `DispatchQueue.main.asyncAfter` → `Task { @MainActor }` | `ContentView.swift` | 15 Min |
| 2 | `FFBackground` nur im Wrapper behalten, in Sub-Views entfernen | `FFSetupView.swift` + alle anderen Views | 30 Min |
| 3 | `preferredFrameRateRange` für Animations-Transactions setzen | `ContentView.swift` + Wrapper | 30 Min |
| 4 | `.animation()` vom ZStack auf das `Group` einengen | `FalscheFaehrteWrapper.swift` | 10 Min |

**Gilt für alle Spiele** – nicht nur Falsche Fährte. Alle 6 Spiel-Buttons in `ContentView.swift` haben dasselbe Muster.

---

## Fix 1 – `asyncAfter` ersetzen

### Vorher (aktuell)
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
    falscheFaehrteTap = false
    isFalscheFaehrtePresented = true
}
```

### Nachher
```swift
Task { @MainActor in
    try? await Task.sleep(for: .milliseconds(180))
    falscheFaehrteTap = false
    isFalscheFaehrtePresented = true
}
```

**Warum besser:** `Task { @MainActor }` ist cancellable (kein Leak wenn View verschwindet) und kooperiert besser mit dem Swift Concurrency-System. Der Main Thread wird weniger aggressiv blockiert.

---

## Fix 2 – `FFBackground` zentralisieren

### Vorher
- `FalscheFaehrteWrapper` → `FFBackground()` ✓
- `FFSetupView` → `FFBackground()` (doppelt)
- Alle Sheets in `FFSetupView` → jeweils `FFBackground()` (mehrfach doppelt)

### Nachher
- `FalscheFaehrteWrapper` → `FFBackground()` ✓ (bleibt)
- `FFSetupView` → kein `FFBackground()` mehr (Wrapper übernimmt)
- Sheets in `FFSetupView` → `.presentationBackground(...)` statt eigener Background-View

---

## Fix 3 – ProMotion explizit aktivieren

```swift
// In ContentView.swift, beim Setzen von isXxxPresented:
var transaction = Transaction()
transaction.animation = .spring(response: 0.25, dampingFraction: 0.6)
// iOS 15+ hint für hohe Frame Rate
withTransaction(transaction) {
    isFalscheFaehrtePresented = true
}
```

Oder alternativ für die fullScreenCover-Transition selbst einen `preferredFrameRateRange` auf dem ZStack des Wrappers setzen (iOS 15+).

---

## Fix 4 – Animation einengen

### Vorher (`FalscheFaehrteWrapper.swift`)
```swift
ZStack {
    FFBackground()
    Group { ... }  // Phase-Views
}
.animation(.easeInOut(duration: 0.3), value: viewModel.gamePhase)  // animiert alles
```

### Nachher
```swift
ZStack {
    FFBackground()
    Group { ... }
        .animation(.easeInOut(duration: 0.3), value: viewModel.gamePhase)  // nur Phase-Views
}
```

---

## Gilt für alle Spiele

Alle 6 Spiele in `ContentView.swift` haben dasselbe `asyncAfter`-Muster. Fixes 1 und 3 müssen für alle Buttons umgesetzt werden:

- [ ] BetBuddy (Zeile 117)
- [ ] Time's Up (Zeile 131)
- [ ] Finde den Lügner (Zeile 150)
- [ ] Imposter (Zeile 164)
- [ ] Geräusch-Kino (Zeile 178)
- [ ] Falsche Fährte (Zeile 191)

---

*Erstellt: 2026-04-13*
