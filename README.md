# 🖥️ Device Onboarding

Dieses Repository enthält Scripts zur Einrichtung neuer Mitarbeitergeräte (macOS & Linux).

---

## Warum immer neu installieren?

Gebrauchte Geräte werden grundsätzlich neu aufgesetzt. So wird sichergestellt dass:
- Keine Daten oder Zugänge des Vorgängers übrig bleiben
- Das Gerät sauber und ohne unbekannte Software übergeben wird
- Alle Sicherheitseinstellungen korrekt gesetzt sind

---

## Ablauf

### 1. macOS

1. macOS neu installieren
2. Im Setup-Assistenten den Admin-Account anlegen → Benutzername: **`admin`**
3. Mitarbeiter-Account anlegen → Benutzername: **`pm-name`** (z.B. `pm-max`)
4. Als `pm-name` einloggen
5. Script ausführen:
```bash
chmod +x setup_mac.sh
./setup_mac.sh
```

### 2. Linux

1. Linux neu installieren
2. Im Setup den Admin-Account anlegen → Benutzername: **`pm-admin`**
3. Mitarbeiter-Account anlegen → Benutzername: **`pm-name`** (z.B. `pm-max`)
4. Als `pm-name` einloggen
5. Script ausführen:
```bash
chmod +x setup_linux.sh
./setup_linux.sh
```
6. Nach Abschluss neu starten

---

## Was machen die Scripts?

### setup_mac.sh
| Was | Warum |
|-----|-------|
| `admin` Account verstecken | Mitarbeiter sieht keinen zweiten Account, IT hat trotzdem immer Zugang |
| Gastaccount deaktivieren | Verhindert Zugriff ohne Passwort |
| Automatische Updates aktivieren | Gerät bleibt aktuell ohne manuellen Aufwand |
| FileVault prüfen/aktivieren | Festplatte ist verschlüsselt – bei Verlust des Geräts sind keine Daten lesbar |
| Apps installieren | Slack, Chrome, Teams, Tunnelblick, Firefox, Jabra Direct |
| Chrome Bookmarks setzen | Wichtige Unternehmenslinks direkt verfügbar |

### setup_linux.sh
| Was | Warum |
|-----|-------|
| System updaten | Saubere Basis vor der Installation |
| Apps installieren | Postman, GitHub Desktop, Chrome, Slack, VS Code, JetBrains Toolbox, Docker und mehr |
| Immer aktuellste Version | Versionen werden automatisch über die jeweilige API ermittelt |
| Chrome Bookmarks setzen | Wichtige Unternehmenslinks direkt verfügbar |
| Docker einrichten | Mitarbeiter kann Docker direkt ohne sudo nutzen |

---

## Admin-Zugang bei Geräterückgabe

### macOS
Login-Screen → **„Anderer Benutzer"** → Benutzername `admin` + Passwort eingeben

### Linux
Mit dem `pm-admin` Account einloggen

---

## Hinweise
- Den **FileVault Recovery Key** (macOS) nach der Einrichtung in der [Geräteliste (Google Sheets)](https://docs.google.com) eintragen
