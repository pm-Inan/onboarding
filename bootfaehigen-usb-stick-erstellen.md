# Bootfähigen USB-Stick erstellen (Linux)

## Voraussetzungen

- USB-Stick (mind. 8 GB)
- Linux-System mit `dd` (standardmäßig installiert)

## 1. ISO herunterladen

```bash
wget https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso
```

Offizielle Downloadseite: https://ubuntu.com/download/desktop

## 2. Integrität prüfen

```bash
sha256sum ubuntu-24.04.4-desktop-amd64.iso
```

Erwarteten Hash abgleichen mit: https://releases.ubuntu.com/24.04/SHA256SUMS

## 3. USB-Stick identifizieren

```bash
lsblk
```

Stick anhand der Größe identifizieren (z.B. `/dev/sdb`).

> ⚠️ **Richtiges Gerät wählen!** Falsches Gerät = Datenverlust. Immer das Gerät (`sdb`), nicht eine Partition (`sdb1`) verwenden.

## 4. ISO auf Stick schreiben

```bash
sudo dd if=ubuntu-24.04.4-desktop-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

`sdX` durch den tatsächlichen Gerätenamen ersetzen.

> ℹ️ `dd` überschreibt den Stick vollständig — vorheriges Formatieren ist nicht nötig.

## 5. Fertig

Stick abziehen → am Zielgerät einstecken → vom USB booten (meist `F12` oder `F2` beim Start).
