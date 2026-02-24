#!/bin/bash

# Prüfen, ob Homebrew installiert ist, und wenn nicht, es installieren
if ! command -v brew &> /dev/null; then
    echo "Homebrew wird installiert..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Homebrew-Pfad in die Umgebungsvariablen aufnehmen
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Funktion zum Installieren von Anwendungen
install_app() {
    if ! brew list --cask "$1" &> /dev/null; then
        echo "Installiere $1..."
        brew install --cask "$1"
    else
        echo "$1 ist bereits installiert."
    fi
}

# Function for installing NPM
install_npm() {
    echo "Install NPM"
    brew update
    brew doctor
    export PATH="/usr/local/bin:$PATH"
    brew install node
    npm install -g grunt-cli
}

# Function to create the pm-root User
create_root(){
    # Passwort abfragen
    read -s -p "Set a password for User pm-root: " password
    echo

    # Create User and set root permissions
    sudo dscl . -create "/Users/pm-root"
    sudo dscl . -create "/Users/pm-root" UserShell /bin/bash
    sudo dscl . -create "/Users/pm-root" RealName "pm-root"
    sudo dscl . -create "/Users/pm-root" UniqueID "1001"
    sudo dscl . -create "/Users/pm-root" PrimaryGroupID "80"
    sudo dscl . -create "/Users/pm-root" NFSHomeDirectory "/Users/pm-root"
    sudo dscl . -passwd "/Users/pm-root" "$password"
    sudo dscl . -append "/Groups/admin" GroupMembership "pm-root"

    echo "User pm-root successfully created!"
}


set_chrome_bookmarks(){
    # Definiere den Inhalt der Bookmarks-Datei
    bookmarks_content='{
    "checksum": "daccfdc8bf0ab5629bb57cc709afdfc7",
    "roots": {
        "bookmark_bar": {
            "children": [ {
                "date_added": "13359554733157401",
                "date_last_used": "13359554796463300",
                "guid": "050bbde0-c32c-4978-bd63-a4f6760023fb",
                "id": "11",
                "meta_info": {
                "power_bookmark_meta": ""
                },
                "name": "GMail P&M",
                "type": "url",
                "url": "https://mail.google.com/mail/u/0/#inbox"
            }, {
                "date_added": "13359554695853436",
                "date_last_used": "0",
                "guid": "77942dbd-030b-4f75-b94f-71b7be6f6a81",
                "id": "10",
                "meta_info": {
                "power_bookmark_meta": ""
                },
                "name": "Calendar P&M",
                "type": "url",
                "url": "https://calendar.google.com/calendar/u/0/r"
            }, {
                "date_added": "13359555042862825",
                "date_last_used": "0",
                "guid": "95ef6e91-4965-4611-9354-ca40fea0863c",
                "id": "17",
                "meta_info": {
                "power_bookmark_meta": ""
                },
                "name": "Google Drive",
                "type": "url",
                "url": "https://drive.google.com/drive/home"
            }, {
                "date_added": "13359554825396685",
                "date_last_used": "0",
                "guid": "2cdf27ae-9eea-47b4-a8a8-6c9e7527d558",
                "id": "12",
                "meta_info": {
                "power_bookmark_meta": ""
                },
                "name": "SIPLA",
                "type": "url",
                "url": "https://pmagentur.sipla.pm-projects.de/account/login"
            }, {
                "date_added": "13359554875156917",
                "date_last_used": "0",
                "guid": "898964c6-cd18-4f3a-b09c-8c8efa209962",
                "id": "13",
                "meta_info": {
                "power_bookmark_meta": ""
                },
                "name": "Atlassian",
                "type": "url",
                "url": "https://id.atlassian.com/login?continue=https%3A%2F%2Fid.atlassian.com%2Fjoin%2Fuser-access%3Fresource%3Dari%253Acloud%253Ajira%253A%253Asite%252Ffc30d626-c7c8-44e4-9b1c-e1cc1894dd1e%26continue%3Dhttps%253A%252F%252Fpmsoftware.atlassian.net%252Fjira&application=jira"
            }, {
                "date_added": "13359554914685384",
                "date_last_used": "0",
                "guid": "0a53253f-c622-4b06-809f-b45622f4f4b3",
                "id": "14",
                "meta_info": {
                "power_bookmark_meta": ""
                },
                "name": "Float",
                "type": "url",
                "url": "https://pm-agentur.float.com/login"
            }, {
                "date_added": "13359554937479990",
                "date_last_used": "0",
                "guid": "6c9fd19c-4f6c-46be-8ca6-56c00997070b",
                "id": "15",
                "meta_info": {
                "power_bookmark_meta": ""
                },
                "name": "Personio",
                "type": "url",
                "url": "https://pm-team.personio.de/login/index"
            }, {
                "date_added": "13359555009550867",
                "date_last_used": "0",
                "guid": "8163a63f-e554-4e18-95a4-827034764f09",
                "id": "16",
                "meta_info": {
                "power_bookmark_meta": ""
                },
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
            "children": [  ],
            "date_added": "13359548210640092",
            "date_last_used": "0",
            "date_modified": "13359548221900383",
            "guid": "82b081ec-3dd3-529c-8475-ab6c344590dd",
            "id": "2",
            "name": "Other bookmarks",
            "type": "folder"
        },
        "synced": {
            "children": [  ],
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

    # Pfade definieren
    chrome_dir="$HOME/Library/Application Support/Google/Chrome"
    default_dir="$chrome_dir/Default"

    # Erstelle das Verzeichnis, wenn es nicht existiert
    mkdir -p "$default_dir"

    # Erstelle die Bookmarks-Datei und schreibe den Inhalt
    echo "$bookmarks_content" > "$default_dir/Bookmarks"
}

# Open Chrome to build Folders
open_chrome(){
    # Google Chrome öffnen
    open -a "Google Chrome"

    # Warte 2 Sekunden
    sleep 2

    # Google Chrome schließen
    osascript -e 'quit app "Google Chrome"'
}


# Anwendungen installieren
# Slack
install_app "slack"
#Google Chrome
install_app "google-chrome"
# Set Chrome Bookmarks
open_chrome
set_chrome_bookmarks
# Teams
install_app "microsoft-teams" 
# Tunnelblick
install_app "tunnelblick"
# Firefox
install_app "firefox"  
# Jabra Headset Software
install_app "jabra-direct"   
# Ferdium
#install_app "ferdium"  

# Install NPM with node
#install_npm

# Create root user
create_root


echo "Installation abgeschlossen."