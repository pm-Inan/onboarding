#!/bin/bash

# ============================================================
# Linux Einrichtungsscript
# Ausführen als Setup-Account (mit sudo-Rechten)
# ============================================================

set -e

# ============================================================
# HILFSFUNKTIONEN
# ============================================================
log() { echo ""; echo ">>> $1"; echo ""; }

# ============================================================
# VORAUSSETZUNGEN
# ============================================================
install_preinstall() {
    log "System wird aktualisiert..."
    sudo apt update
    sudo apt upgrade -y
    sudo apt install curl wget -y
}

# ============================================================
# APPS INSTALLIEREN
# ============================================================
install_postman() {
    log "Installiere Postman..."
    sudo snap install postman
}

install_github() {
    log "Installiere GitHub Desktop..."
    sudo apt install git -y

    # Aktuellste Version von GitHub Desktop ermitteln
    GITHUB_VERSION=$(curl -s https://api.github.com/repos/shiftkey/desktop/releases/latest | grep -o '"tag_name": ".*"' | cut -d'"' -f4 | sed 's/release-//')
    wget "https://github.com/shiftkey/desktop/releases/download/release-${GITHUB_VERSION}/GitHubDesktop-linux-${GITHUB_VERSION}.deb" -O /tmp/github-desktop.deb
    sudo apt install gdebi-core -y
    sudo gdebi /tmp/github-desktop.deb -n
    rm /tmp/github-desktop.deb
}

install_google_chrome() {
    log "Installiere Google Chrome..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome.deb
    sudo dpkg -i /tmp/google-chrome.deb
    rm /tmp/google-chrome.deb

    # Chrome kurz starten damit Profilordner erstellt wird
    google-chrome &
    sleep 2
    killall google-chrome || true
}

install_openvpn() {
    log "Installiere OpenVPN..."
    sudo apt-get install openvpn -y
}

install_slack() {
    log "Installiere Slack..."
    curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/slack-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/slack-archive-keyring.gpg] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" | sudo tee /etc/apt/sources.list.d/slack.list
    sudo apt update
    sudo apt install slack-desktop -y
}

install_flameshot() {
    log "Installiere Flameshot..."
    sudo apt install flameshot -y
}

install_filezilla() {
    log "Installiere FileZilla..."
    sudo apt install filezilla -y
}

install_zsh() {
    log "Installiere ZSH..."
    sudo apt install zsh -y
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_vscode() {
    log "Installiere VS Code..."
    sudo snap install --classic code
}

install_composer() {
    log "Installiere Composer..."
    sudo apt install php-cli unzip -y
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm /tmp/composer-setup.php
}

install_ferdium() {
    log "Installiere Ferdium..."
    FERDIUM_VERSION=$(curl -s https://api.github.com/repos/ferdium/ferdium-app/releases/latest | grep -o '"tag_name": ".*"' | cut -d'"' -f4 | sed 's/v//')
    wget "https://github.com/ferdium/ferdium-app/releases/download/v${FERDIUM_VERSION}/Ferdium-linux-${FERDIUM_VERSION}-amd64.deb" -O /tmp/ferdium.deb
    sudo apt install /tmp/ferdium.deb -y
    rm /tmp/ferdium.deb
}

install_nvm() {
    log "Installiere NVM..."
    NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -o '"tag_name": ".*"' | cut -d'"' -f4)
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

    # NVM in aktuelle Session laden
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    nvm install --lts
    nvm use --lts
}

install_sublime() {
    log "Installiere Sublime Text..."
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt update
    sudo apt install sublime-text -y
}

install_jetbrains_toolbox() {
    log "Installiere JetBrains Toolbox..."
    sudo apt install libfuse2 -y

    # Aktuellste Version ermitteln
    JB_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | grep -o '"linux":{"link":"[^"]*"' | cut -d'"' -f4)
    wget "$JB_URL" -O /tmp/jetbrains-toolbox.tar.gz
    sudo tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /opt/
    sudo mv /opt/jetbrains-toolbox-* /opt/jetbrains
    rm /tmp/jetbrains-toolbox.tar.gz

    log "Öffne JetBrains Toolbox..."
    /opt/jetbrains/jetbrains-toolbox &
}

install_displaylink() {
    log "Installiere DisplayLink..."
    sudo apt update
    curl -o /tmp/synaptics-repository-keyring.deb https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb
    sudo apt install /tmp/synaptics-repository-keyring.deb -y
    sudo apt install displaylink-driver -y
    rm /tmp/synaptics-repository-keyring.deb
}

install_docker() {
    log "Installiere Docker..."
    sudo apt-get install ca-certificates curl gnupg -y

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Docker Gruppe einrichten
    if ! getent group docker > /dev/null; then
        sudo groupadd docker
    fi
    sudo usermod -aG docker "$USER"
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    log "Docker Version:"
    docker -v
    docker compose version
}

# ============================================================
# CHROME BOOKMARKS SETZEN
# ============================================================
create_bookmarks() {
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

    CHROME_DIR="$HOME/.config/google-chrome/Default"
    mkdir -p "$CHROME_DIR"
    echo "$BOOKMARKS_CONTENT" > "$CHROME_DIR/Bookmarks"
    log "Chrome Bookmarks gesetzt."
}

# ============================================================
# HAUPTPROGRAMM
# ============================================================
log "Linux Einrichtung startet..."

install_preinstall
install_postman
install_github
install_google_chrome
create_bookmarks
install_slack
install_openvpn
install_flameshot
install_zsh
install_vscode
install_jetbrains_toolbox
install_composer
install_filezilla
install_ferdium
install_sublime
install_nvm
install_docker
install_displaylink

log "Einrichtung abgeschlossen!"
echo "Hinweis: Bitte neu starten damit Docker und NVM korrekt geladen werden."
