#!/bin/bash

# ============================================================
# Linux Einrichtungsscript (v5 – finale Version)
# Ausführen als Setup-Account (mit sudo-Rechten)
#
# Optionale Umgebungsvariablen:
#   GITHUB_TOKEN=ghp_...   → Erhöht GitHub API Rate-Limit (60 → 5000/h)
#   DRY_RUN=1              → Zeigt nur an was installiert würde
#   VERSIONS_FILE=path     → Datei mit gepinnten Versionen (siehe unten)
#   NO_COLOR=1             → Deaktiviert farbige Ausgabe
#
# Format versions.conf (optional):
#   GITHUB_DESKTOP_VERSION=3.4.12
#   FERDIUM_VERSION=7.0.0
#   NVM_VERSION=v0.40.1
# ============================================================

set -euo pipefail

# ============================================================
# GLOBALE VARIABLEN
# ============================================================
DRY_RUN="${DRY_RUN:-0}"
VERSIONS_FILE="${VERSIONS_FILE:-}"
LOG_FILE=""
TMP_FILES=()
SCRIPT_START=$(date +%s)

# Tracking-Arrays fuer Zusammenfassung
INSTALLED=()
SKIPPED=()
FAILED=()

# ============================================================
# FARBEN (Terminal + Log-Datei getrennt)
# ============================================================
setup_colors() {
    if [ "${NO_COLOR:-0}" = "1" ] || [ ! -t 1 ]; then
        C_RED="" C_YELLOW="" C_GREEN="" C_CYAN="" C_BOLD="" C_RESET=""
    else
        C_RED="\033[0;31m"
        C_YELLOW="\033[0;33m"
        C_GREEN="\033[0;32m"
        C_CYAN="\033[0;36m"
        C_BOLD="\033[1m"
        C_RESET="\033[0m"
    fi
}

# ============================================================
# LOGGING
# ============================================================
init_log() {
    local candidate="/var/log/linux-setup-$(date +%F-%H%M%S).log"
    if sudo touch "$candidate" 2>/dev/null && sudo chmod 644 "$candidate" 2>/dev/null; then
        LOG_FILE="$candidate"
    else
        LOG_FILE="/tmp/linux-setup-$(date +%F-%H%M%S).log"
        touch "$LOG_FILE"
    fi
}

# Schreibt in Log-Datei OHNE Farben, auf Terminal MIT Farben
_log_raw() {
    local color="$1"
    local prefix="$2"
    local msg="$3"
    # Log-Datei (ohne Farben)
    echo "[$(date '+%H:%M:%S')] $prefix $msg" >> "$LOG_FILE"
    # Terminal (mit Farben)
    echo -e "${color}${C_BOLD}$prefix${C_RESET} $msg"
}

log()  { echo "" >> "$LOG_FILE"; _log_raw "$C_CYAN"   ">>>" "$1"; }
warn() { _log_raw "$C_YELLOW" "[WARNUNG]" "$1"; }
err()  { _log_raw "$C_RED"    "[FEHLER]"  "$1"; }
ok()   { _log_raw "$C_GREEN"  "[OK]"      "$1"; }

# ============================================================
# LAUFZEIT-TRACKING
# ============================================================
phase_start() {
    PHASE_NAME="$1"
    PHASE_START=$(date +%s)
    log "Phase: $PHASE_NAME"
}

phase_end() {
    local duration=$(( $(date +%s) - PHASE_START ))
    local mins=$((duration / 60))
    local secs=$((duration % 60))
    log "Phase '$PHASE_NAME' abgeschlossen in ${mins}m ${secs}s"
}

# ============================================================
# ZUSAMMENFASSUNG TRACKEN
# ============================================================
track_installed() { INSTALLED+=("$1"); }
track_skipped()   { SKIPPED+=("$1"); }
track_failed()    { FAILED+=("$1"); }

print_summary() {
    local total_duration=$(( $(date +%s) - SCRIPT_START ))
    local total_mins=$((total_duration / 60))
    local total_secs=$((total_duration % 60))

    echo "" | tee -a "$LOG_FILE"
    echo "============================================================" | tee -a "$LOG_FILE"
    echo " ZUSAMMENFASSUNG" | tee -a "$LOG_FILE"
    echo "============================================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo -e " Gesamtdauer: ${C_BOLD}${total_mins}m ${total_secs}s${C_RESET}" | tee -a "$LOG_FILE"
    echo " Gesamtdauer: ${total_mins}m ${total_secs}s" >> "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    if [ ${#INSTALLED[@]} -gt 0 ]; then
        echo -e " ${C_GREEN}Installiert (${#INSTALLED[@]}):${C_RESET}" 
        echo " Installiert (${#INSTALLED[@]}):" >> "$LOG_FILE"
        for item in "${INSTALLED[@]}"; do
            echo -e "   ${C_GREEN}+${C_RESET} $item"
            echo "   + $item" >> "$LOG_FILE"
        done
    fi

    if [ ${#SKIPPED[@]} -gt 0 ]; then
        echo -e " ${C_YELLOW}Uebersprungen (${#SKIPPED[@]}):${C_RESET}"
        echo " Uebersprungen (${#SKIPPED[@]}):" >> "$LOG_FILE"
        for item in "${SKIPPED[@]}"; do
            echo -e "   ${C_YELLOW}-${C_RESET} $item"
            echo "   - $item" >> "$LOG_FILE"
        done
    fi

    if [ ${#FAILED[@]} -gt 0 ]; then
        echo -e " ${C_RED}Fehlgeschlagen (${#FAILED[@]}):${C_RESET}"
        echo " Fehlgeschlagen (${#FAILED[@]}):" >> "$LOG_FILE"
        for item in "${FAILED[@]}"; do
            echo -e "   ${C_RED}!${C_RESET} $item"
            echo "   ! $item" >> "$LOG_FILE"
        done
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "============================================================" | tee -a "$LOG_FILE"
    echo " Log-Datei: $LOG_FILE" | tee -a "$LOG_FILE"
    echo "============================================================" | tee -a "$LOG_FILE"
}

# ============================================================
# HILFSFUNKTIONEN
# ============================================================

# Aufräumung bei Abbruch oder Ende
cleanup() {
    local exit_code=$?
    if [ ${#TMP_FILES[@]} -gt 0 ]; then
        rm -f "${TMP_FILES[@]}" 2>/dev/null || true
    fi
    if [ $exit_code -ne 0 ]; then
        err "Script mit Fehlercode $exit_code abgebrochen. Log: $LOG_FILE"
    fi
}
trap cleanup EXIT

# Temporäre Datei im Hauptprozess registrieren
register_tmp() {
    local f="/tmp/setup-$$-${1}"
    TMP_FILES+=("$f")
    echo "$f"
}

# Robuste Prüfung: Binary im PATH → dpkg → snap
is_available() {
    local pkg="$1"
    local cmd="${2:-$1}"
    command -v "$cmd" &>/dev/null 2>&1 || dpkg -s "$pkg" &>/dev/null 2>&1 || snap list "$pkg" &>/dev/null 2>&1
}

# Dry-Run-Guard
dry_run_skip() {
    if [ "$DRY_RUN" = "1" ]; then
        log "[DRY RUN] Wuerde ausfuehren: $1"
        return 0
    fi
    return 1
}

# --- JSON-Parsing (jq bevorzugt, python3 Fallback) ---
json_extract() {
    local json="$1"
    local jq_expr="$2"
    local py_expr="$3"

    if command -v jq &>/dev/null; then
        echo "$json" | jq -r "$jq_expr" 2>/dev/null || true
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print($py_expr)
except Exception:
    print('')
" <<< "$json" 2>/dev/null || true
    else
        err "Weder jq noch python3 verfuegbar – kann JSON nicht parsen."
        return 1
    fi
}

# API-Versionen validieren
check_api_version() {
    local version="$1"
    local name="$2"
    if [ -z "$version" ]; then
        err "Konnte Version fuer $name nicht ermitteln (API Rate-Limit oder Netzwerkfehler)."
        return 1
    fi
    if ! [[ "$version" =~ ^v?[0-9]+([.0-9]+)* ]]; then
        err "Unerwartetes Versionsformat fuer $name: '$version'"
        return 1
    fi
}

# --- GitHub-API ---
gh_api() {
    local url="$1"
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$url"
    else
        curl -fsSL "$url"
    fi
}

gh_latest_tag() {
    local repo="$1"
    local api_json
    api_json=$(gh_api "https://api.github.com/repos/$repo/releases/latest") || {
        err "GitHub API Aufruf fehlgeschlagen fuer $repo"
        return 1
    }
    json_extract "$api_json" '.tag_name' "d.get('tag_name','')"
}

gh_asset_url() {
    local repo="$1"
    local pattern="$2"
    local api_json
    api_json=$(gh_api "https://api.github.com/repos/$repo/releases/latest") || {
        err "GitHub API Aufruf fehlgeschlagen fuer $repo"
        return 1
    }

    if command -v jq &>/dev/null; then
        echo "$api_json" | jq -r ".assets[] | select(.name | test(\"$pattern\")) | .browser_download_url" 2>/dev/null | head -1
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, re, sys
try:
    d = json.load(sys.stdin)
    for a in d.get('assets', []):
        if re.search(r'''$pattern''', a.get('name', '')):
            print(a['browser_download_url'])
            break
except Exception:
    pass
" <<< "$api_json" 2>/dev/null || true
    else
        err "Weder jq noch python3 verfuegbar."
        return 1
    fi
}

# Version aus Konfig-Datei lesen
pinned_version() {
    local key="$1"
    if [ -n "$VERSIONS_FILE" ] && [ -f "$VERSIONS_FILE" ]; then
        grep -oP "^${key}=\K.*" "$VERSIONS_FILE" 2>/dev/null || true
    fi
}

# GUID-Generator
gen_guid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen
    elif [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
    elif command -v python3 &>/dev/null; then
        python3 -c "import uuid; print(uuid.uuid4())"
    else
        od -x /dev/urandom 2>/dev/null | head -1 | awk '{print $2$3"-"$4"-"$5"-"$6"-"$7$8$9}' || echo "$(date +%s)-$RANDOM-$RANDOM-$RANDOM"
    fi
}

# ============================================================
# PHASE 1: GRUNDPAKETE
# ============================================================
install_preinstall() {
    phase_start "Grundpakete"
    dry_run_skip "apt update + Grundpakete" && { phase_end; return; }

    sudo apt update 2>&1 | tee -a "$LOG_FILE"
    sudo apt install -y curl wget gnupg ca-certificates software-properties-common 2>&1 | tee -a "$LOG_FILE"

    if ! command -v jq &>/dev/null; then
        sudo apt install -y jq 2>&1 | tee -a "$LOG_FILE"
    fi
    phase_end
}

# ============================================================
# PHASE 2: ALLE REPOS HINZUFÜGEN + apt update
# ============================================================
add_all_repositories() {
    phase_start "Paketquellen"
    dry_run_skip "Repository-Einrichtung" && { phase_end; return; }

    sudo install -m 0755 -d /etc/apt/keyrings

    # --- Slack ---
    if ! is_available slack-desktop slack; then
        if ! [ -f /usr/share/keyrings/slack-archive-keyring.gpg ]; then
            log "Slack-Repo wird hinzugefuegt..."
            curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey \
                | gpg --dearmor \
                | sudo tee /usr/share/keyrings/slack-archive-keyring.gpg > /dev/null 2>&1
            echo "deb [signed-by=/usr/share/keyrings/slack-archive-keyring.gpg] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" \
                | sudo tee /etc/apt/sources.list.d/slack.list > /dev/null
        fi
    fi

    # --- Sublime Text ---
    if ! is_available sublime-text subl; then
        if ! [ -f /etc/apt/trusted.gpg.d/sublimehq-archive.gpg ]; then
            log "Sublime-Text-Repo wird hinzugefuegt..."
            wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
                | gpg --dearmor \
                | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null 2>&1
            echo "deb https://download.sublimetext.com/ apt/stable/" \
                | sudo tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
        fi
    fi

    # --- VS Code (offizielles Microsoft-Repo) ---
    if ! is_available code code; then
        if ! [ -f /etc/apt/keyrings/microsoft.gpg ]; then
            log "VS-Code-Repo wird hinzugefuegt..."
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
                | gpg --dearmor \
                | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null 2>&1
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
                | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        fi
    fi

    # --- Docker ---
    if ! is_available docker-ce docker; then
        if ! [ -f /etc/apt/keyrings/docker.gpg ]; then
            log "Docker-Repo wird hinzugefuegt..."
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
                | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>&1 | tee -a "$LOG_FILE"
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
                | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
    fi

    log "Paketlisten werden aktualisiert..."
    sudo apt update 2>&1 | tee -a "$LOG_FILE"
    phase_end
}

# ============================================================
# PHASE 3: APT-PAKETE
# ============================================================
install_apt_packages() {
    phase_start "APT-Pakete"

    local packages=()

    is_available git git               || packages+=(git)
    is_available slack-desktop slack    || packages+=(slack-desktop)
    is_available sublime-text subl     || packages+=(sublime-text)
    is_available code code             || packages+=(code)
    is_available openvpn openvpn       || packages+=(openvpn)
    is_available flameshot flameshot   || packages+=(flameshot)
    is_available filezilla filezilla   || packages+=(filezilla)
    is_available zsh zsh               || packages+=(zsh)
    command -v php &>/dev/null         || packages+=(php-cli unzip)

    if ! is_available docker-ce docker; then
        packages+=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
    fi

    if [ ${#packages[@]} -gt 0 ]; then
        log "Zu installieren: ${packages[*]}"
        dry_run_skip "apt install ${packages[*]}" && { phase_end; return; }
        if sudo apt install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"; then
            for pkg in "${packages[@]}"; do
                track_installed "$pkg (apt)"
            done
        else
            for pkg in "${packages[@]}"; do
                track_failed "$pkg (apt)"
            done
        fi
    else
        log "Alle APT-Pakete bereits installiert."
        track_skipped "APT-Pakete (alle vorhanden)"
    fi
    phase_end
}

# ============================================================
# PHASE 4: POSTMAN
# ============================================================
install_postman() {
    if is_available postman postman; then
        ok "Postman bereits installiert."
        track_skipped "Postman"
        return
    fi
    log "Installiere Postman (tar.gz)..."
    dry_run_skip "Postman Download + Installation" && return

    local dl_path="$1"
    if ! curl -fsSL -o "$dl_path" "https://dl.pstmn.io/download/latest/linux64" 2>&1 | tee -a "$LOG_FILE"; then
        warn "Postman Download fehlgeschlagen."
        track_failed "Postman"
        return
    fi
    if [ ! -s "$dl_path" ]; then
        warn "Postman Download leer."
        track_failed "Postman"
        return
    fi

    sudo rm -rf /opt/Postman
    sudo mkdir -p /opt/Postman
    sudo tar -xzf "$dl_path" --strip-components=1 -C /opt/Postman 2>&1 | tee -a "$LOG_FILE"

    mkdir -p "$HOME/.local/share/applications"

    local icon_path
    icon_path=$(find /opt/Postman -name "icon.png" -type f 2>/dev/null | head -1)
    if [ -z "$icon_path" ]; then
        icon_path="/opt/Postman/app/resources/app/assets/icon.png"
    fi

    cat > "$HOME/.local/share/applications/postman.desktop" << DESKTOP_EOF
[Desktop Entry]
Type=Application
Name=Postman
Icon=$icon_path
Exec=/opt/Postman/Postman
Categories=Development;
Terminal=false
DESKTOP_EOF
    ok "Postman installiert."
    track_installed "Postman"
}

# ============================================================
# PHASE 5: EXTERNE INSTALLER
# ============================================================

# --- Download-Funktionen (parallelisierbar) ---

download_github_desktop() {
    local dl_path="$1"
    if is_available github-desktop github-desktop; then return 0; fi

    local version
    version=$(pinned_version "GITHUB_DESKTOP_VERSION")

    if [ -n "$version" ]; then
        wget -q "https://github.com/shiftkey/desktop/releases/download/release-${version}/GitHubDesktop-linux-amd64-${version}.deb" -O "$dl_path" 2>&1 | tee -a "$LOG_FILE" || return 1
    else
        local url
        url=$(gh_asset_url "shiftkey/desktop" "amd64\\.deb$")
        if [ -z "$url" ]; then return 1; fi
        wget -q "$url" -O "$dl_path" 2>&1 | tee -a "$LOG_FILE" || return 1
    fi
}

download_ferdium() {
    local dl_path="$1"
    if is_available ferdium ferdium; then return 0; fi

    local version
    version=$(pinned_version "FERDIUM_VERSION")

    if [ -n "$version" ]; then
        wget -q "https://github.com/ferdium/ferdium-app/releases/download/v${version}/Ferdium-linux-${version}-amd64.deb" -O "$dl_path" 2>&1 | tee -a "$LOG_FILE" || return 1
    else
        local url
        url=$(gh_asset_url "ferdium/ferdium-app" "amd64\\.deb$")
        if [ -z "$url" ]; then return 1; fi
        wget -q "$url" -O "$dl_path" 2>&1 | tee -a "$LOG_FILE" || return 1
    fi
}

# --- Generische .deb-Installation ---

install_deb_package() {
    local name="$1"
    local deb_path="$2"
    local check_pkg="$3"
    local check_cmd="$4"

    if is_available "$check_pkg" "$check_cmd"; then
        ok "$name bereits installiert."
        track_skipped "$name"
        return
    fi
    if [ ! -s "$deb_path" ]; then
        warn "$name: .deb nicht vorhanden oder leer."
        track_failed "$name"
        return
    fi
    log "Installiere $name..."
    dry_run_skip "$name Installation" && return
    if sudo apt install -y "$deb_path" 2>&1 | tee -a "$LOG_FILE"; then
        ok "$name installiert."
        track_installed "$name"
    else
        err "$name Installation fehlgeschlagen."
        track_failed "$name"
    fi
}

install_google_chrome() {
    if is_available google-chrome-stable google-chrome-stable; then
        ok "Google Chrome bereits installiert."
        track_skipped "Google Chrome"
        return
    fi
    log "Installiere Google Chrome..."
    dry_run_skip "Google Chrome Installation" && return

    local dl_path="$1"
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O "$dl_path" 2>&1 | tee -a "$LOG_FILE"
    if [ ! -s "$dl_path" ]; then
        warn "Chrome Download leer."
        track_failed "Google Chrome"
        return
    fi
    if sudo apt install -y "$dl_path" 2>&1 | tee -a "$LOG_FILE"; then
        mkdir -p "$HOME/.config/google-chrome/Default"
        ok "Google Chrome installiert."
        track_installed "Google Chrome"
    else
        err "Google Chrome Installation fehlgeschlagen."
        track_failed "Google Chrome"
    fi
}

install_composer() {
    if command -v composer &>/dev/null; then
        ok "Composer bereits installiert."
        track_skipped "Composer"
        return
    fi
    if ! command -v php &>/dev/null; then
        warn "PHP nicht verfuegbar – Composer uebersprungen."
        track_failed "Composer (PHP fehlt)"
        return
    fi
    log "Installiere Composer..."
    dry_run_skip "Composer Installation" && return

    local installer_path="$1"
    curl -sS https://getcomposer.org/installer -o "$installer_path" 2>&1 | tee -a "$LOG_FILE"

    local expected_hash actual_hash
    expected_hash=$(curl -sS https://composer.github.io/installer.sig)
    actual_hash=$(php -r "echo hash_file('sha384', '$installer_path');")
    if [ "$expected_hash" != "$actual_hash" ]; then
        err "Composer Installer-Hash stimmt nicht ueberein!"
        err "  Erwartet: $expected_hash"
        err "  Erhalten: $actual_hash"
        track_failed "Composer (Hash-Mismatch)"
        return
    fi

    if sudo php "$installer_path" --install-dir=/usr/local/bin --filename=composer 2>&1 | tee -a "$LOG_FILE"; then
        ok "Composer installiert."
        track_installed "Composer"
    else
        err "Composer Installation fehlgeschlagen."
        track_failed "Composer"
    fi
}

install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        ok "NVM bereits installiert."
        track_skipped "NVM"
        return
    fi
    log "Installiere NVM..."
    dry_run_skip "NVM Installation" && return

    local nvm_tag
    nvm_tag=$(pinned_version "NVM_VERSION")
    if [ -z "$nvm_tag" ]; then
        nvm_tag=$(gh_latest_tag "nvm-sh/nvm") || {
            warn "NVM-Version konnte nicht ermittelt werden."
            track_failed "NVM (Version unbekannt)"
            return
        }
    fi
    if ! check_api_version "$nvm_tag" "NVM"; then
        track_failed "NVM (ungueltige Version)"
        return
    fi

    local install_script="$1"
    if ! curl -fsSL -o "$install_script" "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_tag}/install.sh" 2>&1 | tee -a "$LOG_FILE"; then
        warn "NVM Installer konnte nicht heruntergeladen werden."
        track_failed "NVM (Download)"
        return
    fi
    if ! bash "$install_script" 2>&1 | tee -a "$LOG_FILE"; then
        warn "NVM Installation fehlgeschlagen – nach Neustart erneut versuchen."
        track_failed "NVM"
        return
    fi

    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck disable=SC1091
        \. "$NVM_DIR/nvm.sh" || {
            warn "NVM konnte nicht in die aktuelle Session geladen werden."
            track_installed "NVM (ohne LTS – Neustart noetig)"
            return
        }
        if nvm install --lts 2>&1 | tee -a "$LOG_FILE"; then
            ok "NVM + Node LTS installiert."
            track_installed "NVM + Node LTS"
        else
            warn "nvm install --lts fehlgeschlagen – nach Neustart erneut versuchen."
            track_installed "NVM (ohne LTS)"
        fi
    else
        track_installed "NVM (Neustart noetig)"
    fi
}

install_jetbrains_toolbox() {
    if [ -f "/opt/jetbrains/jetbrains-toolbox" ]; then
        ok "JetBrains Toolbox bereits installiert."
        track_skipped "JetBrains Toolbox"
        return
    fi
    log "Installiere JetBrains Toolbox..."
    dry_run_skip "JetBrains Toolbox Installation" && return

    sudo apt install -y libfuse2 2>&1 | tee -a "$LOG_FILE"

    local api_json jb_url
    api_json=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" 2>/dev/null) || {
        warn "JetBrains API nicht erreichbar."
        track_failed "JetBrains Toolbox (API)"
        return
    }

    jb_url=$(json_extract "$api_json" \
        '.TBA[0].downloads.linux.link' \
        "d['TBA'][0]['downloads']['linux']['link']")

    if [ -z "$jb_url" ]; then
        warn "JetBrains Toolbox URL konnte nicht ermittelt werden."
        track_failed "JetBrains Toolbox (URL)"
        return
    fi

    local dl_path="$1"
    wget -q "$jb_url" -O "$dl_path" 2>&1 | tee -a "$LOG_FILE"
    if [ ! -s "$dl_path" ]; then
        warn "JetBrains Toolbox Download leer."
        track_failed "JetBrains Toolbox (Download)"
        return
    fi
    sudo rm -rf /opt/jetbrains
    sudo mkdir -p /opt/jetbrains
    sudo tar -xzf "$dl_path" --strip-components=1 -C /opt/jetbrains 2>&1 | tee -a "$LOG_FILE"
    ok "JetBrains Toolbox installiert -> nach Neustart starten: /opt/jetbrains/jetbrains-toolbox"
    track_installed "JetBrains Toolbox"
}

install_displaylink() {
    if dpkg -s displaylink-driver &>/dev/null 2>&1; then
        ok "DisplayLink bereits installiert."
        track_skipped "DisplayLink"
        return
    fi
    log "Installiere DisplayLink..."
    dry_run_skip "DisplayLink Installation" && return

    local keyring_url="https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb"
    local dl_path="$1"
    local http_code

    http_code=$(curl -sSL -o "$dl_path" -w "%{http_code}" "$keyring_url" 2>/dev/null) || true

    if [ "$http_code" != "200" ] || [ ! -s "$dl_path" ]; then
        warn "DisplayLink Keyring konnte nicht heruntergeladen werden (HTTP $http_code)."
        warn "Bitte manuell installieren: https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu"
        track_failed "DisplayLink (Keyring-Download)"
        return
    fi

    sudo apt install -y "$dl_path" 2>&1 | tee -a "$LOG_FILE"
    sudo apt update 2>&1 | tee -a "$LOG_FILE"
    if sudo apt install -y displaylink-driver 2>&1 | tee -a "$LOG_FILE"; then
        ok "DisplayLink installiert."
        track_installed "DisplayLink"
    else
        err "DisplayLink Installation fehlgeschlagen."
        track_failed "DisplayLink"
    fi
}

# ============================================================
# PHASE 6: SHELL-KONFIGURATION
# ============================================================
configure_zsh() {
    dry_run_skip "ZSH-Konfiguration" && return

    if [ -d "$HOME/.oh-my-zsh" ]; then
        ok "Oh-My-Zsh bereits installiert."
        track_skipped "Oh-My-Zsh"
    else
        log "Installiere Oh-My-Zsh..."
        local omz_installer
        omz_installer=$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh 2>/dev/null) || true
        if [ -z "$omz_installer" ]; then
            warn "Oh-My-Zsh Installer konnte nicht heruntergeladen werden."
            track_failed "Oh-My-Zsh (Download)"
            return
        fi
        if RUNZSH=no CHSH=no sh -c "$omz_installer" 2>&1 | tee -a "$LOG_FILE"; then
            ok "Oh-My-Zsh installiert."
            track_installed "Oh-My-Zsh"
        else
            warn "Oh-My-Zsh Installation fehlgeschlagen."
            track_failed "Oh-My-Zsh"
            return
        fi
    fi

    local zsh_path current_shell
    zsh_path=$(command -v zsh) || {
        warn "zsh nicht im PATH gefunden."
        return
    }
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_shell" != "$zsh_path" ]; then
        sudo chsh -s "$zsh_path" "$USER" 2>&1 | tee -a "$LOG_FILE"
        log "Standard-Shell auf ZSH gesetzt."
    fi

    # NVM-Integration in .zshrc
    if [ -d "$HOME/.nvm" ] && ! grep -q 'NVM_DIR' "$HOME/.zshrc" 2>/dev/null; then
        log "NVM-Konfiguration wird in .zshrc eingetragen..."
        cat >> "$HOME/.zshrc" << 'EOF'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
    fi
}

configure_docker() {
    if ! is_available docker-ce docker; then
        return
    fi
    dry_run_skip "Docker-Konfiguration" && return

    if ! getent group docker > /dev/null; then
        sudo groupadd docker
    fi
    if ! groups "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER"
    fi
    sudo systemctl enable docker.service 2>&1 | tee -a "$LOG_FILE"
    sudo systemctl enable containerd.service 2>&1 | tee -a "$LOG_FILE"

    log "Docker Version:"
    docker -v 2>&1 | tee -a "$LOG_FILE" || true
    docker compose version 2>&1 | tee -a "$LOG_FILE" || true
    track_installed "Docker-Konfiguration"
}

# ============================================================
# CHROME BOOKMARKS
# ============================================================
create_bookmarks() {
    log "Chrome Bookmarks werden gesetzt..."
    dry_run_skip "Chrome Bookmarks" && return

    local chrome_dir="$HOME/.config/google-chrome/Default"
    mkdir -p "$chrome_dir"

    if [ -f "$chrome_dir/Bookmarks" ]; then
        warn "Chrome Bookmarks existieren bereits – ueberspringe."
        track_skipped "Chrome Bookmarks"
        return
    fi

    local guid_bar guid_other guid_synced
    local guid_1 guid_2 guid_3 guid_4 guid_5 guid_6 guid_7 guid_8
    guid_bar=$(gen_guid); guid_other=$(gen_guid); guid_synced=$(gen_guid)
    guid_1=$(gen_guid); guid_2=$(gen_guid); guid_3=$(gen_guid); guid_4=$(gen_guid)
    guid_5=$(gen_guid); guid_6=$(gen_guid); guid_7=$(gen_guid); guid_8=$(gen_guid)

    cat > "$chrome_dir/Bookmarks" << BOOKMARKS_EOF
{
    "checksum": "",
    "roots": {
        "bookmark_bar": {
            "children": [ {
                "guid": "$guid_1",
                "id": "11",
                "name": "GMail P&M",
                "type": "url",
                "url": "https://mail.google.com/mail/u/0/#inbox"
            }, {
                "guid": "$guid_2",
                "id": "10",
                "name": "Calendar P&M",
                "type": "url",
                "url": "https://calendar.google.com/calendar/u/0/r"
            }, {
                "guid": "$guid_3",
                "id": "17",
                "name": "Google Drive",
                "type": "url",
                "url": "https://drive.google.com/drive/home"
            }, {
                "guid": "$guid_4",
                "id": "12",
                "name": "SIPLA",
                "type": "url",
                "url": "https://pmagentur.sipla.pm-projects.de/account/login"
            }, {
                "guid": "$guid_5",
                "id": "13",
                "name": "Atlassian",
                "type": "url",
                "url": "https://id.atlassian.com/login?continue=https%3A%2F%2Fid.atlassian.com%2Fjoin%2Fuser-access%3Fresource%3Dari%253Acloud%253Ajira%253A%253Asite%252Ffc30d626-c7c8-44e4-9b1c-e1cc1894dd1e%26continue%3Dhttps%253A%252F%252Fpmsoftware.atlassian.net%252Fjira&application=jira"
            }, {
                "guid": "$guid_6",
                "id": "14",
                "name": "Float",
                "type": "url",
                "url": "https://pm-agentur.float.com/login"
            }, {
                "guid": "$guid_7",
                "id": "15",
                "name": "Personio",
                "type": "url",
                "url": "https://pm-team.personio.de/login/index"
            }, {
                "guid": "$guid_8",
                "id": "16",
                "name": "Vaultwarden Web",
                "type": "url",
                "url": "https://vault.pm-software.net/obfc23bxx124/#/login"
            } ],
            "guid": "$guid_bar",
            "id": "1",
            "name": "Bookmarks bar",
            "type": "folder"
        },
        "other": {
            "children": [],
            "guid": "$guid_other",
            "id": "2",
            "name": "Other bookmarks",
            "type": "folder"
        },
        "synced": {
            "children": [],
            "guid": "$guid_synced",
            "id": "3",
            "name": "Mobile bookmarks",
            "type": "folder"
        }
    },
    "version": 1
}
BOOKMARKS_EOF
    ok "Chrome Bookmarks gesetzt."
    track_installed "Chrome Bookmarks"
}

# ============================================================
# HAUPTPROGRAMM
# ============================================================
setup_colors
init_log

log "Linux Einrichtung startet... (Log: $LOG_FILE)"

if [ "$DRY_RUN" = "1" ]; then
    log "=== DRY RUN MODUS – es werden keine Aenderungen vorgenommen ==="
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
    warn "Kein GITHUB_TOKEN gesetzt. GitHub API Rate-Limit: 60 Requests/Stunde."
    warn "Optional: export GITHUB_TOKEN='ghp_...' vor Ausfuehrung setzen."
fi

# --- Alle tmp-Pfade im Hauptprozess registrieren ---
TMP_CHROME=$(register_tmp "google-chrome.deb")
TMP_GHD=$(register_tmp "github-desktop.deb")
TMP_FERDIUM=$(register_tmp "ferdium.deb")
TMP_POSTMAN=$(register_tmp "postman.tar.gz")
TMP_COMPOSER=$(register_tmp "composer-setup.php")
TMP_NVM=$(register_tmp "nvm-install.sh")
TMP_JETBRAINS=$(register_tmp "jetbrains-toolbox.tar.gz")
TMP_DISPLAYLINK=$(register_tmp "synaptics-keyring.deb")

# Phase 1
install_preinstall

# Phase 2
add_all_repositories

# Phase 3
install_apt_packages

# Phase 4
phase_start "Postman"
install_postman "$TMP_POSTMAN"
phase_end

# Phase 5
phase_start "Externe Pakete"
install_google_chrome "$TMP_CHROME"
create_bookmarks

if [ "$DRY_RUN" != "1" ]; then
    log "Parallele Downloads starten..."
    download_github_desktop "$TMP_GHD" &
    pid_ghd=$!
    download_ferdium "$TMP_FERDIUM" &
    pid_ferdium=$!

    install_composer "$TMP_COMPOSER"
    install_nvm "$TMP_NVM"

    wait "$pid_ghd" || warn "GitHub Desktop Download fehlgeschlagen."
    wait "$pid_ferdium" || warn "Ferdium Download fehlgeschlagen."

    install_deb_package "GitHub Desktop" "$TMP_GHD" "github-desktop" "github-desktop"
    install_deb_package "Ferdium" "$TMP_FERDIUM" "ferdium" "ferdium"
else
    dry_run_skip "GitHub Desktop Download + Installation"
    dry_run_skip "Ferdium Download + Installation"
    install_composer "$TMP_COMPOSER"
    install_nvm "$TMP_NVM"
fi

install_jetbrains_toolbox "$TMP_JETBRAINS"
install_displaylink "$TMP_DISPLAYLINK"
phase_end

# Phase 6
phase_start "Konfiguration"
configure_zsh
configure_docker
phase_end

# System-Upgrade am Ende
if [ "$DRY_RUN" != "1" ]; then
    phase_start "System-Upgrade"
    log "Kann einige Minuten dauern..."
    sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
    phase_end
fi

# Zusammenfassung
print_summary

echo ""
echo "Hinweise:"
echo "  - Bitte neu starten damit Docker, NVM und ZSH korrekt geladen werden."
echo "  - JetBrains Toolbox manuell starten: /opt/jetbrains/jetbrains-toolbox"
