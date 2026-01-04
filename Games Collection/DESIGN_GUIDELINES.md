# Games Collection – Design & Style Guide

Dieses Dokument definiert die Design-Standards für die "Games Collection" App. Ziel ist ein einheitliches ("aus einem Guss"), modernes und user-freundliches Erlebnis über alle Spiele hinweg.

Jedes neue Spiel **muss** diesen Richtlinien folgen.

---

## 1. Navigation & Struktur

### Einstiegspunkt (Home)
*   **Kein Main Menu:** Jedes Spiel startet direkt in seinem Setup-Screen (z.B. `GameSetupView`, `SettingsView`).
*   **Navigation Stack:** Nutze `NavigationStack` für die Navigation innerhalb des Spiels.
*   **Header (Top Bar):**
    *   **Position:** `HStack` mit `padding(.top, 20)` und `padding(.bottom, 10)`.
    *   **Links:** "Zurück"-Button (Kreis, `dismiss()` Aktion).
    *   **Rechts (Reihenfolge):**
        1.  🏆 **Trophäe** (Leaderboard)
        2.  📂 **Ordner** (Kategorie-Verwaltung/Auswahl)
        3.  ⚙️ **Zahnrad** (Spiel-Einstellungen)
        4.  ❓ **Fragezeichen** (Anleitung/Info)
    *   **Button-Style:**
        *   Größe: `.frame(width: 36, height: 36)`
        *   Hintergrund: `Circle()` mit `Color.white.opacity(0.1)` (oder `0.08` bis `0.15`).
        *   Icon-Farben: Trophäe (Gelb), Ordner (Orange), Fragezeichen (Weiß), Zahnrad (Grau).

### Schließen der App
*   Der Zurück-Button im Header ist der einzige Weg, das Spiel zu verlassen.
*   **Wichtig:** Im `ContentView` darf **kein** separater X-Button über dem `fullScreenCover` liegen.

---

## 2. Visuelles Design (Theme)

### Farben & Hintergrund
*   **Modus:** Grundsätzlich **Dark Mode**.
*   **Hintergrund:** Ein dunkler `LinearGradient`, der zum Charakter des Spiels passt (z.B. Lila/Blau für Time's Up, Rot/Orange für Imposter), aber immer dunkel und "neon-artig" bleibt.
    *   *Beispiel:* `colors: [Color.black, Color.blue.opacity(0.15), ...]`
*   **Glas-Effekt:** Nutze `.ultraThinMaterial` oder `Color.white.opacity(0.08)` für Karten und Listen-Hintergründe.

### Container & Rahmen
*   **Haupt-Container (Settings):**
    *   Eckradius: `cornerRadius(22)`
    *   Hintergrund: `Color.black.opacity(0.25)`
    *   Rahmen: `Stroke(Color.white.opacity(0.08), lineWidth: 1)`
    *   Padding: `.padding(20)` (Standard Theme-Padding).

### Listen-Elemente (Rows)
*   **Stil:** Keine Standard-List, sondern `VStack` mit `HStack`-Zeilen.
*   **Abstand:** `spacing: 12` zwischen den Zeilen.
*   **Row-Design:**
    *   Padding: `.padding(.horizontal, 14)` und `.padding(.vertical, 12)`.
    *   Hintergrund: `Color.black.opacity(0.25)` oder `.cardBackground`.
    *   Eckradius: `cornerRadius(18)`.
*   **Icons in Rows:**
    *   Form: `RoundedRectangle(cornerRadius: 12)`.
    *   Größe: `44x44`.
    *   Hintergrund: Leichter Gradient oder Opacity passend zur Akzentfarbe.

---

## 3. Interaktionen & Buttons

### Primärer Button ("Spiel starten")
*   **Form:** `Capsule()`.
*   **Höhe/Padding:** `.padding(.vertical, 16)` (oder 18).
*   **Position:** Unten am Bildschirmrand (Floating).
*   **Abstand zum Rand:** `32pt` vom unteren Bildschirmrand (erreicht durch Container-Padding 20 + Button-Padding 12).
*   **Style:** `LinearGradient` (z.B. Grün zu Blau für "Start").

### Haptik
*   Nutze `UIImpactFeedbackGenerator` für Buttons.
*   `.light` für normale Klicks (Toggles, Auswahl).
*   `.medium` für wichtige Aktionen (Spiel starten, Speichern).

---

## 4. Kategorien-Verwaltung
*   **Zugriff:** Über das 📂 Ordner-Icon im Header.
*   **Layout:** Liste von Kategorien (keine Kacheln/Grid).
*   **Funktionen:**
    *   Hinzufügen (+ Icon im Header).
    *   Bearbeiten (Stift-Icon).
    *   Löschen (Mülleimer, nur bei eigenen Kategorien).
    *   Standard-Kategorien sind mit einem Schloss 🔒 geschützt.
*   **Detail-Ansicht:** Öffnet sich via `NavigationLink` (im selben Stack).

---

## Checkliste für neue Spiele

1.  [ ] `MainMenuView` entfernen/überspringen.
2.  [ ] `SettingsView` (oder `SetupView`) als Einstiegspunkt definieren.
3.  [ ] Top Bar mit 36x36 Icons (Trophäe, Ordner, Zahnrad, ?) einbauen.
4.  [ ] Top Padding auf `20` setzen.
5.  [ ] Container-Style für Einstellungen übernehmen (Rounded 22, Dark BG).
6.  [ ] Start-Button Abstand unten auf `32` setzen.
7.  [ ] Farben anpassen (Dark Mode + Spiel-Akzent), aber Struktur beibehalten.
8.  [ ] X-Button in `ContentView` entfernen.
