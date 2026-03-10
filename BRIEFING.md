# BRIEFING.md – Onboarding SysAdmin

**Erstellt:** 05.03.2026  
**Zuletzt aktualisiert:** 05.03.2026 (Antworten Mathias Leonhardt eingearbeitet)  
**Zielgruppe:** Neuer SysAdmin bei P&M Agentur  
**Zweck:** Schneller Einstieg in die IT-Infrastruktur ohne Vorkenntnisse über das Unternehmen

---

## 1. Kontext – Was ist passiert?

P&M Agentur hat ihre Server von **Berlin nach Hamburg** umgezogen. Das bedeutet:

- Die DEV-Server liefen bisher in Berlin hinter einer **WatchGuard T70** Firewall (IP: `87.234.222.66`)
- Sie laufen jetzt in Hamburg hinter einem **Cisco RV345P** Router (IP: `31.172.106.157`)
- Die VPN-Infrastruktur, Kunden-Whitelists und Proxy-Configs mussten dafür angepasst werden
- Dieser Umzug ist **noch nicht vollständig abgeschlossen** – es gibt offene Punkte (siehe Abschnitt 4)

### Geplanter Firewall-Austausch in Hamburg

Der Cisco RV345P wird durch eine **OPNSense DEC3852 Rack Appliance** ersetzt. Hintergrund:

- Der RV345P ist EOL (keine Firmware-Updates mehr) und hat mehrere Hardware-Limitierungen
- Alle aktuellen Cisco-Modelle erfordern eine kostenpflichtige Subscription (€600–1.000/Jahr)
- Die DEC3852 hat einmalige Kosten von ~€1.299 + ~€80–100 für einen Managed Switch (da aktuell ~12 Ports am Cisco belegt sind) und keine laufenden Lizenzkosten
- Phillip hat das Go gegeben – **Bestellung steht jedoch noch aus!**
- Mauro hat die VPN-Configs bereits auf einer kleinen OPNSense (`192.168.80.59`) vorbereitet und getestet – die Config kann direkt auf die DEC3852 übernommen werden
- Die Umstellung ist für einen Abend geplant (~1h Downtime, alle VPNs kurz down)
- Konfiguration erfolgt in Kooperation mit Mauro Altamura, der die Config bereits vorbereitet und getestet hat
- Nach der Umstellung wird das eingebaute OPNSense-Monitoring für die VPN-Tunnel konfiguriert
- **Wichtig:** Viele der aktuellen VPN-Probleme (Tyczka nur 1 Netz, Adacor NAT, VPN-Client-Routing) sind Cisco-Limitierungen und erledigen sich mit der neuen OPNSense

**Ansprechpartner für die Umstellung:** Inan Bogisch (Konfiguration), bei Bedarf Leon Schumacher & Mathias Leonhardt.

---

## 2. Infrastruktur-Übersicht

### Drei Standorte / Firewalls

| Standort | Gerät | Öffentliche IP | Internes Netz |
|----------|-------|----------------|---------------|
| **Berlin** | WatchGuard T70 | `87.234.222.66` | `192.168.1.0/24`, `192.168.2.0/24` |
| **Hamburg** | Cisco RV345P (→ wird durch OPNSense DEC3852 ersetzt) | `31.172.106.157` | `192.168.80.0/24` (Server), `192.168.81.0/24` (VPN-Clients) |
| **OMC** (Hoster) | OPNSense | `212.77.230.96` | `10.20.30.0/24` |

> **OMC** ist ein externer Hoster bei dem Kundenprojekte wie DLRG und Hückmann laufen. Die OPNSense dort ist über die normale OPNSense-Weboberfläche erreichbar.

### Server in Hamburg (192.168.80.x)

| IP | Server | Funktion | Status |
|----|--------|----------|--------|
| `192.168.80.26` | DB Server (Alt) | MySQL Datenbank | ⚠ SSH nicht erreichbar (MySQL läuft) |
| `192.168.80.27` | Windows Server | Hyper-V | ✅ Online |
| `192.168.80.28` | Bürkert Server | MySQL + Bürkert VPN | ✅ Online |
| `192.168.80.29` | VMware ESXi | Virtualisierung | ✅ Online |
| `192.168.80.59` | OPNSense (klein) | VPN-Test / Vorbereitung DEC3852 | ℹ Testgerät, wird durch DEC3852 abgelöst |
| `192.168.80.74` | DEV Server | Apache Reverse-Proxy, MySQL | ✅ Online |
| `192.168.80.171` | LDAP Server | Verzeichnisdienst | ✅ Online |
| `192.168.80.240` | FC | MySQL | ✅ Online |
| `192.168.80.242` | DSS Fileserver | Dateiablage | ✅ Online |
| `192.168.80.244` | MailServer | Windows 2012 R2 | ✅ Online |
| `192.168.80.254` | QNAP | Veeam-Backup | ✅ GUI erreichbar |

---

## 3. VPN-Landschaft

### Aktive Site-to-Site Tunnel

| Verbindung | Protokoll | Status | Besonderheit |
|------------|-----------|--------|--------------|
| Berlin ↔ Hamburg | IKEv2 | ✅ Stabil | Hauptverbindung zwischen den Standorten |
| Berlin ↔ OMC | IKEv2 | ✅ Stabil | Über WatchGuard Berlin |
| Hamburg ↔ OMC | IKEv2 | ✅ Stabil | Direktverbindung |
| Hamburg ↔ Bürkert (neu) | IKEv2 | ✅ Aktiv | Remote: `10.40.0.0/16` |
| Berlin ↔ Bürkert.1 | IKEv2 | ✅ Aktiv | Remote: `10.40.0.0/16` |
| Berlin ↔ Bürkert.2 | IKEv1 | ✅ Aktiv | Remote: `192.168.120.x`, `192.168.151.x` |
| Hamburg ↔ Sonic | IKEv2 | ✅ Erledigt | Christian Wenzel (Sonic) bestätigt am 18.12.2025 |
| Hamburg ↔ Tyczka | IKEv2 | 🟡 Eingeschränkt | Nur 1 Remote-Range gleichzeitig (Cisco-Limit) – entfällt mit OPNSense |
| Hamburg ↔ Adacor | IKEv2 | ❌ Nicht funktional | Kein Local-NAT am Cisco – entfällt mit OPNSense |
| Berlin ↔ Tyczka | IKEv2 | ⚠ Offen | Remote-Regel falsch, PSK unklar. Ansprechpartner bei Tyczka: Marcel Cebulla |
| Berlin ↔ Cornelsen | IKEv2 | ⚠ Prüfen | Testumgebung vom Netz genommen (Jan 2026) – Tunnel kann deaktiviert werden |
| Berlin ↔ Dorma | IKEv2 | ⚠ Unklar | Dorma ist aktiver Kunde! Möglicherweise Ablösung durch WireGuard (Sven Mack weiß mehr) |
| Berlin ↔ Sonic.2 | IKEv2 | ⚠ Prüfen | Ob sonic.2 (62.209.53.124) noch gebraucht wird, ist unklar |

### Wichtige Einschränkung: Cisco RV345P (temporär!)

Der Cisco RV345P hat bekannte Hardware-Limitierungen – diese entfallen nach dem Austausch durch die OPNSense DEC3852:

1. **VPN-Clients (192.168.81.x) können nicht in S2S-Tunnel geroutet werden**
2. **Kein Local-NAT pro S2S-Tunnel** (Adacor-Problem)
3. **Nur 1 SA bei Multi-Netz VPNs** (Tyczka-Problem)
4. **Kein ESP-Forwarding** (verhinderte OPNSense-hinter-Cisco-Lösung)

### Workaround für Entwickler (bis OPNSense installiert ist)
Wer auf alle Standorte zugreifen muss, verbindet sich mit **beiden VPNs gleichzeitig**:
- **Cisco IPSec** → Hamburg (`192.168.80.x`)
- **WatchGuard SSL-VPN** → Berlin + OMC (`192.168.1/2.x`, `10.20.30.x`)

---

## 4. Offene Aufgaben & Prioritäten

### 🔴 Dringend

| Aufgabe | Details | Ansprechpartner |
|---------|---------|-----------------|
| DEC3852 bestellen | Phillip hat Go gegeben, Bestellung steht noch aus | Mathias Leonhardt |
| 14 Apache Proxy-Configs ohne Hamburg-Netz | Bulk-Fix-Script aus README ausführen – Risiko minimal | Jeder mit SSH-Zugang zum DEV-Server |
| Fruchthof Whitelisting | Jira-Ticket FNE-23618 (Daniel Jüdel) – kein E-Mail-Kontakt gefunden | Daniel Jüdel |
| Indunorm Whitelisting | Ansprechpartner: Dirk Küppers (dirk.kueppers@indunorm.de) oder Joel Kretschmer (Joel.Kretschmer@hsr.de) | Mathias Leonhardt |

### 🟡 Mittel

| Aufgabe | Details | Ansprechpartner |
|---------|---------|-----------------|
| SSH auf DB-Server `192.168.80.26` | MySQL läuft, SSH nicht. Prüfen ob VM auf ESXi → über vSphere-Konsole reingehen | Mathias Leonhardt |
| 3 QNAPs physisch nicht auffindbar | Vor-Ort-Prüfung bei nächstem Hamburg-Besuch | Mathias Leonhardt |
| QNAPs .87 und .92 konfigurieren | Vermutlich neue QNAPs von Dennis aufgestellt aber nie konfiguriert – als Backup-Ziele einrichten | Mathias Leonhardt |
| Backup-Übersicht erstellen | Veeam-Jobs auf .254 prüfen, restic-Configs auf Servern checken | Mathias Leonhardt |
| IBM Server Zugangsdaten | Mathias sucht noch – falls nicht gefunden: Konsole/IPMI Reset vor Ort | Mathias Leonhardt |
| Tyczka ERP-Range aktivieren | Koordination über Marcel Cebulla → Datagroup (~1-2 Werktage Vorlauf) | Mauro Altamura |
| Dorma VPN-Status klären | IPSec-Tunnel oder WireGuard-Ablösung? Sven Mack weiß mehr | Mauro Altamura / Sven Mack |
| Cornelsen-Tunnel deaktivieren | Testumgebung vom Netz seit Jan 2026 – Tunnel auf WatchGuard prüfen | Mauro Altamura |
| Sonic.2 prüfen | Wird 62.209.53.124 noch gebraucht? | Mauro Altamura |

### ⚪ Offen / Unklar

| Aufgabe | Details | Ansprechpartner |
|---------|---------|-----------------|
| Lederer & MK Whitelisting | Keine Rückmeldung bisher | Mathias Leonhardt |
| VPN-Monitoring einrichten | OPNSense hat eingebaute Monitoring-Funktionen – wird nach DEC3852-Umstellung konfiguriert. Als Alternative wäre ein Ping-Script mit Slack-Alert möglich | Inan Bogisch (Vorschlag erwünscht) |
| Bürkert-PSK Speicherort | Bewusst nicht im Repo – liegt vermutlich im Passwortmanager | Daniel Jüdel |

---

## 5. Team & Ansprechpartner

| Person | Rolle | Standort | Zuständig für |
|--------|-------|----------|---------------|
| **Mathias Leonhardt** | CTO & QMB | Hamburg | Gesamtkoordination, Entscheidungen, Hardware vor Ort |
| **Sven Mack** | Head of Engineering | Hamburg | Software-Entwicklung, Dorma/WireGuard |
| **Leon Schumacher** | Team Lead Software Engineering | Hamburg | Software-Entwicklung |
| **Mauro Altamura** | VPN/Firewall | Berlin | WatchGuard Berlin, VPN-Konfigurationen |
| **Daniel Jüdel** | Team Lead DXP/Ibexa | Berlin | Bürkert-Projekt, Fruchthof |
| **Inan Bogisch** | SysAdmin (Werkstudent) | Hamburg | Hardware vor Ort mitverwalten, administrative Aufgaben – keine Entscheidungsgewalt oder Vollverantwortung |

> **Hinweis:** Dennis Rumpf wird in der AGENTS.md als Ansprechpartner für Hardware vor Ort genannt, ist jedoch seit März 2026 nicht mehr im Unternehmen. Seine Hardware- und Admin-Aufgaben gehen an Mathias Leonhardt über, ein Teil wird von Inan Bogisch mitverwaltet.

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

### Kunden-Whitelisting Status (Stand 05.03.2026)

| Status | Kunden |
|--------|--------|
| ✅ Erledigt | Murexin, Hückmann, Depesche, Niehues, DLRG, Orthegroh, Cornelsen, Sonic, Tyczka |
| ⏳ Keine Rückmeldung | Lederer, MK |
| 🔴 Noch kontaktieren | Fruchthof, Indunorm |

### DEV-Server Zugang
```bash
ssh devel@192.168.80.74
```
Apache Proxy-Configs liegen unter `/etc/apache2/sites-enabled/`

### WatchGuard Berlin
Zugang über: `https://192.168.1.249:8080` (nur über VPN nach Berlin erreichbar)  
→ Änderungen bitte nur durch Mauro Altamura!

---

## 7. Nützliche Befehle

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
