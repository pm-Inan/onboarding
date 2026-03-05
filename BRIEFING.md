# BRIEFING.md – Onboarding SysAdmin

**Erstellt:** 05.03.2026  
**Zielgruppe:** Neuer SysAdmin bei P&M Agentur  
**Zweck:** Schneller Einstieg in die IT-Infrastruktur ohne Vorkenntnisse über das Unternehmen

---

## 1. Kontext – Was ist passiert?

P&M Agentur hat ihre Server von **Berlin nach Hamburg** umgezogen. Das bedeutet:

- Die DEV-Server liefen bisher in Berlin hinter einer **WatchGuard T70** Firewall (IP: `87.234.222.66`)
- Sie laufen jetzt in Hamburg hinter einem **Cisco RV345P** Router (IP: `31.172.106.157`)
- Die VPN-Infrastruktur, Kunden-Whitelists und Proxy-Configs mussten dafür angepasst werden
- Dieser Umzug ist **noch nicht vollständig abgeschlossen** – es gibt offene Punkte (siehe Abschnitt 4)

---

## 2. Infrastruktur-Übersicht

### Drei Standorte / Firewalls

| Standort | Gerät | Öffentliche IP | Internes Netz |
|----------|-------|----------------|---------------|
| **Berlin** | WatchGuard T70 | `87.234.222.66` | `192.168.1.0/24`, `192.168.2.0/24` |
| **Hamburg** | Cisco RV345P | `31.172.106.157` | `192.168.80.0/24` (Server), `192.168.81.0/24` (VPN-Clients) |
| **OMC** (Hoster) | OPNSense | `212.77.230.96` | `10.20.30.0/24` |

> **OMC** ist ein externer Hoster bei dem Kundenprojekte wie DLRG und Hückmann laufen. Die OPNSense dort ist über die normale OPNSense-Weboberfläche erreichbar.

### Server in Hamburg (192.168.80.x)

| IP | Server | Funktion | Status |
|----|--------|----------|--------|
| `192.168.80.26` | DB Server (Alt) | MySQL Datenbank | ⚠ SSH nicht erreichbar |
| `192.168.80.27` | Windows Server | Hyper-V | ✅ Online |
| `192.168.80.28` | Bürkert Server | MySQL + Bürkert VPN | ✅ Online |
| `192.168.80.29` | VMware ESXi | Virtualisierung | ✅ Online |
| `192.168.80.74` | DEV Server | Apache Reverse-Proxy, MySQL | ✅ Online |
| `192.168.80.171` | LDAP Server | Verzeichnisdienst | ✅ Online |
| `192.168.80.240` | FC | MySQL | ✅ Online |
| `192.168.80.242` | DSS Fileserver | Dateiablage | ✅ Online |
| `192.168.80.244` | MailServer | Windows 2012 R2 | ✅ Online |
| `192.168.80.254` | QNAP | Veeam-Backup | ✅ GUI erreichbar |

---

## 3. VPN-Landschaft

### Was ist ein Site-to-Site VPN?
Ein S2S-VPN verbindet zwei Netzwerke dauerhaft miteinander – z.B. Hamburg ↔ Berlin – sodass Server auf beiden Seiten miteinander kommunizieren können als wären sie im gleichen Netz.

### Aktive Site-to-Site Tunnel

| Verbindung | Protokoll | Status | Besonderheit |
|------------|-----------|--------|--------------|
| Berlin ↔ Hamburg | IKEv2 | ✅ Stabil | Hauptverbindung zwischen den Standorten |
| Berlin ↔ OMC | IKEv2 | ✅ Stabil | Über WatchGuard Berlin |
| Hamburg ↔ OMC | IKEv2 | ✅ Stabil | Direktverbindung, stabil |
| Hamburg ↔ Bürkert (neu) | IKEv2 | ✅ Aktiv | Remote: `10.40.0.0/16` |
| Berlin ↔ Bürkert.1 | IKEv2 | ✅ Aktiv | Remote: `10.40.0.0/16` |
| Berlin ↔ Bürkert.2 | IKEv1 | ✅ Aktiv | Remote: `192.168.120.x`, `192.168.151.x` |
| Hamburg ↔ Sonic | IKEv2 | 🟡 Stage OK | Nur 1 Remote-Netz stabil (RV345P-Limit) |
| Hamburg ↔ Tyczka | IKEv2 | 🟡 Eingeschränkt | Nur 1 Remote-Range gleichzeitig aktiv |
| Hamburg ↔ Adacor | IKEv2 | ❌ Nicht funktional | RV345P unterstützt kein Local-NAT |
| Berlin ↔ Tyczka | IKEv2 | ⚠ Offen | Remote-Regel falsch, PSK ausstehend |

### Wichtige Einschränkung: Cisco RV345P

Der Cisco RV345P in Hamburg hat zwei bekannte Hardware-Limitierungen:

1. **VPN-Clients (192.168.81.x) können nicht in S2S-Tunnel geroutet werden** – ein Client der per VPN in Hamburg eingewählt ist, kommt nicht automatisch nach Berlin oder OMC
2. **Kein Local-NAT pro S2S-Tunnel** – deshalb funktioniert der Adacor-Tunnel nicht

> **Hinweis:** Es ist geplant, den Cisco RV345P durch einen neuen Router zu ersetzen. In diesem Fall müssen alle bestehenden VPN-Konfigurationen übertragen werden. Ansprechpartner: Inan Bogisch (Konfiguration), bei Bedarf Leon Schumacher & Mathias Leonhardt.

### Workaround für Entwickler
Wer auf alle Standorte zugreifen muss, verbindet sich mit **beiden VPNs gleichzeitig**:
- **Cisco IPSec** → Hamburg (`192.168.80.x`)
- **WatchGuard SSL-VPN** → Berlin + OMC (`192.168.1/2.x`, `10.20.30.x`)

Linux-User können `vpnc` + WatchGuard parallel nutzen – funktioniert stabil.

---

## 4. Offene Aufgaben & Prioritäten

### 🔴 Dringend

| Aufgabe | Details | Ansprechpartner |
|---------|---------|-----------------|
| 14 Apache Proxy-Configs ohne Hamburg-Netz | `192.168.80.0/24` fehlt in IP-Whitelist → potenzielle „Forbidden"-Fehler bei Kunden | Mathias Leonhardt |
| SSH auf DB-Server `192.168.80.26` nicht erreichbar | MySQL läuft, SSH nicht – Ursache unklar | Mathias Leonhardt |
| 3 QNAPs physisch nicht auffindbar | Nur `.87`, `.92` (uninitialisiert) und `.254` (Veeam) antworten auf ARP | Inan Bogisch (vor Ort prüfen) |

### 🟡 Mittel

| Aufgabe | Details | Ansprechpartner |
|---------|---------|-----------------|
| Adacor-Tunnel | RV345P kann kein Local-NAT – neue Hardware nötig (DEC3842 oder OPNSense mit /29) | Mauro Altamura |
| Tyczka ERP-Range aktivieren | Umschalten erfordert gleichzeitige Änderung durch Datagroup | Mauro Altamura |
| Sonic: Live-Server stabiler anbinden | Aktuell nur Stage über 1 Remote-Netz stabil | Mauro Altamura |
| Kunden-Whitelisting abschließen | Neue IP `31.172.106.157` noch nicht bei allen Kunden hinterlegt | Mathias Leonhardt |

### ⚪ Offen / Unklar

| Aufgabe | Details | Ansprechpartner |
|---------|---------|-----------------|
| Cornelsen & Dorma VPN-Status | Kein bekannter Status in der Dokumentation | Mauro Altamura |
| IBM Server falsche Static IP | Zugangsdaten benötigt | Mathias Leonhardt |
| Backup-Strategie bestätigen | Veeam + restic – sind alle Jobs nach Umzug noch aktiv? | Mathias Leonhardt |
| VPN-Monitoring einrichten | Aktuell nur manuelle Prüfung | Mathias Leonhardt |

---

## 5. Team & Ansprechpartner

| Person | Rolle | Standort | Zuständig für |
|--------|-------|----------|---------------|
| **Mathias Leonhardt** | CTO & QMB | Hamburg | Gesamtkoordination, Entscheidungen |
| **Sven Mack** | Head of Engineering | Hamburg | Software-Entwicklung |
| **Leon Schumacher** | Team Lead Software Engineering | Hamburg | Software-Entwicklung |
| **Mauro Altamura** | VPN/Firewall | Berlin | WatchGuard, Cisco, OPNSense |
| **Daniel Jüdel** | Team Lead DXP/Ibexa | Berlin | Bürkert-Projekt |
| **Inan Bogisch** | SysAdmin (Werkstudent) | Hamburg | Hardware vor Ort, administrative Aufgaben mitverwalten – keine Entscheidungsgewalt oder Vollverantwortung |

> **Hinweis:** Dennis Rumpf wird in der AGENTS.md als Ansprechpartner für Hardware vor Ort genannt, ist jedoch seit März 2026 nicht mehr im Unternehmen. Er war sowohl als Entwickler als auch für VPN-Verwaltung und administrative Aufgaben zuständig. Ein Teil seiner administrativen Aufgaben wird seitdem von Inan Bogisch mitverwaltet.

---

## 6. Wichtige Dateien & Zugänge

### Im Repo (GitHub)
| Datei | Inhalt |
|-------|--------|
| `README.md` | Vollständige VPN-Landschaft mit Diagrammen |
| `AGENTS.md` | Kontext und Anweisungen für KI-Agenten |
| `fragen.md` | Offene Fragen die noch geklärt werden müssen |

### Lokal (nicht im Repo – sensible Daten!)
| Datei | Inhalt |
|-------|--------|
| `T70.xml` | WatchGuard Berlin Config (enthält PSKs!) |
| `RV345P_configuration_*.xml` | Cisco Hamburg Config |
| `Server-Umzug-IPs.xlsx` | Kunden-Whitelisting Status |

### DEV-Server Zugang
```bash
ssh devel@192.168.80.74
```
Apache Proxy-Configs liegen unter `/etc/apache2/sites-enabled/`

---

## 7. Nützliche Befehle

### VPN-Tunnel Status prüfen (auf OPNSense oder WatchGuard UI)
Die Tunnel werden über die jeweiligen Web-UIs verwaltet, nicht per CLI.

### Apache Proxy-Config prüfen (DEV-Server)
```bash
# Alle Proxy-Configs anzeigen
ls /etc/apache2/sites-enabled/*proxy*.conf

# Whitelist einer Config prüfen
grep -A 10 "Proxy" /etc/apache2/sites-enabled/<config>.conf

# Hamburg-Netz in Config hinzufügen
sudo nano /etc/apache2/sites-enabled/<config>.conf
# Einfügen: Allow from 192.168.80.0/24

# Apache neu laden
sudo systemctl reload apache2
```

### Alle Proxy-Configs ohne Hamburg-Netz finden
```bash
for conf in /etc/apache2/sites-enabled/*proxy*.conf; do
  if grep -q 'Proxy' "$conf" && ! grep -q '192.168.80' "$conf"; then
    echo "Fehlt: $conf"
  fi
done
```
