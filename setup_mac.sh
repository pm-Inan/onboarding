#!/bin/bash

# ============================================================
# Mac Einrichtungsscript
# Ausführen als Mitarbeiter-Account (mit Admin-Rechten)
# nach der macOS Installation und Account-Erstellung
# ============================================================

set -e

# ============================================================
# KONFIGURATION
# ============================================================
ADMIN_USER="admin"

# ============================================================
# HILFSFUNKTIONEN
# ============================================================
log() { echo ""; echo ">>> $1"; echo ""; }

install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log "Homebrew wird installiert..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    else
        log "Homebrew bereits installiert."
    fi
}

install_app() {
    if ! brew list --cask "$1" &> /dev/null; then
        log "Installiere $1..."
        brew install --cask "$1"
    else
        log "$1 bereits installiert."
    fi
}

# ============================================================
# ADMIN VERSTECKEN
# ============================================================
hide_admin() {
    if dscl . read "/Users/$ADMIN_USER" IsHidden 2>/dev/null | grep -q "1"; then
        log "Admin-Account ist bereits versteckt."
        return
    fi

    log "Admin-Account wird versteckt..."
    sudo dscl . create "/Users/$ADMIN_USER" IsHidden 1
    log "Admin-Account '$ADMIN_USER' erfolgreich versteckt."
}

# ============================================================
# SYSTEM KONFIGURIEREN
# ============================================================
configure_system() {
    log "System wird konfiguriert..."

    # Gastaccount deaktivieren
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO
    # Automatische Updates aktivieren
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool YES
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool YES

    log "Systemkonfiguration abgeschlossen."
}

# ============================================================
# FILEVAULT PRÜFEN
# ============================================================
check_filevault() {
    if fdesetup status | grep -q "FileVault is On"; then
        log "FileVault ist bereits aktiv."
    else
        log "FileVault ist nicht aktiv – wird aktiviert..."
        FILEVAULT_KEY=$(sudo fdesetup enable | grep -o '[A-Z0-9-]*')
        echo ""
        echo "======================================================"
        echo "  WICHTIG: FileVault Recovery Key sicher speichern!"
        echo "  $FILEVAULT_KEY"
        echo "======================================================"
        echo ""
        read -p "Recovery Key gespeichert? (Enter zum Fortfahren)"
    fi
}

# ============================================================
# CHROME BOOKMARKS SETZEN
# ============================================================
set_chrome_bookmarks() {
    log "Chrome Bookmarks werden gesetzt..."

    BOOKMARKS_CONTENT='{
    "checksum": "daccfdc8bf0ab5629bb57cc709afdfc7",
    "roots": {
        "bookmark_bar": {
            "children": [ {
                "date_added": "13359554733157401",
                "date_last_used": "13359554796463300",
                "guid": "050bbde0-c32c-4978-bd63-a4f6760023fb",
                "id": "11",
                "meta_info": { "power_bookmark_meta": "" },
                "name": "GMail P&M",
                "type": "url",
                "url": "https://mail.google.com/mail/u/0/#inbox"
            }, {
                "date_added": "13359554695853436",
                "date_last_used": "0",
                "guid": "77942dbd-030b-4f75-b94f-71b7be6f6a81",
                "id": "10",
                "meta_info": { "power_bookmark_meta": "" },
                "name": "Calendar P&M",
                "type": "url",
                "url": "https://calendar.google.com/calendar/u/0/r"
            }, {
                "date_added": "13359555042862825",
                "date_last_used": "0",
                "guid": "95ef6e91-4965-4611-9354-ca40fea0863c",
                "id": "17",
                "meta_info": { "power_bookmark_meta": "" },
                "name": "Google Drive",
                "type": "url",
                "url": "https://drive.google.com/drive/home"
            }, {
                "date_added": "13359554825396685",
                "date_last_used": "0",
                "guid": "2cdf27ae-9eea-47b4-a8a8-6c9e7527d558",
                "id": "12",
                "meta_info": { "power_bookmark_meta": "" },
                "name": "SIPLA",
                "type": "url",
                "url": "https://pmagentur.sipla.pm-projects.de/account/login"
            }, {
                "date_added": "13359554875156917",
                "date_last_used": "0",
                "guid": "898964c6-cd18-4f3a-b09c-8c8efa209962",
                "id": "13",
                "meta_info": { "power_bookmark_meta": "" },
                "name": "Atlassian",
                "type": "url",
                "url": "https://id.atlassian.com/login?continue=https%3A%2F%2Fid.atlassian.com%2Fjoin%2Fuser-access%3Fresource%3Dari%253Acloud%253Ajira%253A%253Asite%252Ffc30d626-c7c8-44e4-9b1c-e1cc1894dd1e%26continue%3Dhttps%253A%252F%252Fpmsoftware.atlassian.net%252Fjira&application=jira"
            }, {
                "date_added": "13359554914685384",
                "date_last_used": "0",
                "guid": "0a53253f-c622-4b06-809f-b45622f4f4b3",
                "id": "14",
                "meta_info": { "power_bookmark_meta": "" },
                "name": "Float",
                "type": "url",
                "url": "https://pm-agentur.float.com/login"
            }, {
                "date_added": "13359554937479990",
                "date_last_used": "0",
                "guid": "6c9fd19c-4f6c-46be-8ca6-56c00997070b",
                "id": "15",
                "meta_info": { "power_bookmark_meta": "" },
                "name": "Personio",
                "type": "url",
                "url": "https://pm-team.personio.de/login/index"
            }, {
                "date_added": "13359555009550867",
                "date_last_used": "0",
                "guid": "8163a63f-e554-4e18-95a4-827034764f09",
                "id": "16",
                "meta_info": { "power_bookmark_meta": "" },
                "name": "Vaultwarden Web",
                "type": "url",
                "url": "https://vault.pm-software.net/obfc23bxx124/#/login"
            } ],
            "date_added": "13359548210640088",
            "date_last_used": "0",
            "date_modified": "13359555090749722",
            "guid": "0bc5d13f-2cba-5d74-951f-3f233fe6c908",
            "id": "1",
            "name": "Bookmarks bar",
            "type": "folder"
        },
        "other": {
            "children": [],
            "date_added": "13359548210640092",
            "date_last_used": "0",
            "date_modified": "13359548221900383",
            "guid": "82b081ec-3dd3-529c-8475-ab6c344590dd",
            "id": "2",
            "name": "Other bookmarks",
            "type": "folder"
        },
        "synced": {
            "children": [],
            "date_added": "13359548210640094",
            "date_last_used": "0",
            "date_modified": "0",
            "guid": "4cf2e351-0e85-532b-bb37-df045d8f8d0f",
            "id": "3",
            "name": "Mobile bookmarks",
            "type": "folder"
        }
    },
    "version": 1
    }'

    CHROME_DIR="$HOME/Library/Application Support/Google/Chrome"
    mkdir -p "$CHROME_DIR/Default"
    echo "$BOOKMARKS_CONTENT" > "$CHROME_DIR/Default/Bookmarks"
    log "Chrome Bookmarks gesetzt."
}

open_and_close_chrome() {
    open -a "Google Chrome"
    sleep 2
    osascript -e 'quit app "Google Chrome"'
}

# ============================================================
# APPS INSTALLIEREN
# ============================================================
install_apps() {
    log "Apps werden installiert..."
    install_app "slack"
    install_app "google-chrome"
    install_app "microsoft-teams"
    install_app "tunnelblick"
    install_app "firefox"
    install_app "jabra-direct"
    log "App-Installation abgeschlossen."
}

# ============================================================
# HAUPTPROGRAMM
# ============================================================
log "Mac Einrichtung startet..."

hide_admin
configure_system
check_filevault
install_homebrew
install_apps
open_and_close_chrome
set_chrome_bookmarks

log "Einrichtung abgeschlossen!"
echo "Der Mac ist fertig eingerichtet."
