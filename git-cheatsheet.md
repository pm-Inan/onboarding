# Git Cheatsheet

> **Hinweis:** Wie du dich per SSH oder HTTPS mit GitHub verbindest, ist am Ende dieser Datei beschrieben.

---

## Inhalt

1. [Typischer Arbeitsablauf](#1-typischer-arbeitsablauf)
2. [Repo klonen](#2-repo-klonen)
3. [Repo aktualisieren](#3-repo-aktualisieren)
4. [Branch erstellen & wechseln](#4-branch-erstellen--wechseln)
5. [Status prüfen](#5-status-prüfen)
6. [Änderungen stagen & committen](#6-änderungen-stagen--committen)
7. [Push – Änderungen hochladen](#7-push--änderungen-hochladen)
8. [Nützliche Befehle](#8-nützliche-befehle)
9. [Verbindung zu GitHub (HTTPS & SSH)](#9-verbindung-zu-github)

---

## 1. Typischer Arbeitsablauf
```bash
git pull origin development             # aktuellen Stand holen
git checkout -b feature/mein-branch    # neuen Branch erstellen
# ...Dateien bearbeiten...
git add .                               # alles stagen
git commit -m "docs: was wurde gemacht"
git push origin feature/mein-branch    # Branch pushen
```

---

## 2. Repo klonen
Einmalig wenn du ein Repo zum ersten Mal auf deinen Rechner holst.
```bash
git clone https://github.com/user/repo.git
cd repo
```

---

## 3. Repo aktualisieren
Wenn du bereits geklont hast und die neuesten Änderungen holen willst.
```bash
git pull origin main        # oder 'development' statt 'main'
```

---

## 4. Branch erstellen & wechseln
Für neue Features oder Aufgaben immer einen eigenen Branch erstellen.
```bash
git checkout -b feature/mein-branch    # erstellen + wechseln
git checkout main                       # zu einem anderen Branch wechseln
git branch                              # alle lokalen Branches anzeigen
```

---

## 5. Status prüfen
Zeigt welche Dateien geändert oder neu sind.
```bash
git status
```

---

## 6. Änderungen stagen & committen
Dateien für den Commit vorbereiten und dann speichern.
```bash
git add datei.md              # einzelne Datei stagen
git add .                     # alle Änderungen stagen
git commit -m "beschreibung"  # commit erstellen
```

---

## 7. Push – Änderungen hochladen
Lokale Commits auf GitHub hochladen.
```bash
git push origin feature/mein-branch    # Branch pushen
git push origin main                    # main pushen
```

---

## 8. Nützliche Befehle
```bash
git log --oneline        # Commit-Historie kompakt anzeigen
git diff                 # Änderungen seit letztem Commit anzeigen
git restore datei.md     # Änderungen an einer Datei rückgängig machen
git stash                # Änderungen temporär wegräumen
git stash pop            # weggeräumte Änderungen wiederherstellen
```

---

## 9. Verbindung zu GitHub

### Option A – HTTPS (einfacher Einstieg)
Kein Setup nötig, aber du brauchst einen **Personal Access Token** als Passwort.
Token erstellen unter: https://github.com/settings/tokens → Haken bei **repo**

```bash
git clone https://USERNAME:TOKEN@github.com/user/repo.git
```

Token wird nach dem ersten Mal meist vom System gespeichert.

---

### Option B – SSH (empfohlen für dauerhaften Einsatz)
Einmalig einrichten, danach kein Token mehr nötig.

**1. SSH-Key erstellen:**
```bash
ssh-keygen -t ed25519 -C "deine@email.de"
# Einfach Enter drücken bis fertig
```

**2. Public Key anzeigen und kopieren:**
```bash
cat ~/.ssh/id_ed25519.pub
```

**3. Key bei GitHub hinterlegen:**
- Gehe auf https://github.com/settings/keys
- Klicke **New SSH key**
- Füge den kopierten Key ein und speichern

**4. Verbindung testen:**
```bash
ssh -T git@github.com
# Erwartete Antwort: "Hi USERNAME! You've successfully authenticated..."
```

**5. Repo per SSH klonen:**
```bash
git clone git@github.com:user/repo.git
```
