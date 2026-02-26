#!/bin/bash

# Anlegen des Root-Users
root_account_creation() {
    # Überprüfen, ob das Skript als Root ausgeführt wird
    if [ "$EUID" -eq 0 ]; then
        echo "Dieses Skript sollte nicht als Root-Benutzer ausgeführt werden."
        exit 1
    fi

    # Benutzernamen festlegen
    USERNAME="pm-root"

    # Passwort vom Benutzer abfragen
    read -s -p "Geben Sie das Passwort für den Benutzer $USERNAME ein: " PASSWORD
    echo

    # Benutzer erstellen und Shell-Zuweisung hinzufügen
    sudo useradd -m -s /bin/bash $USERNAME

    # Passwort für den Benutzer festlegen
    echo "$USERNAME:$PASSWORD" | sudo chpasswd

    # Benutzer zur sudo-Gruppe hinzufügen
    sudo usermod -aG sudo $USERNAME

    echo "Der Benutzer $USERNAME wurde erstellt und zur sudo-Gruppe hinzugefügt."
}

# Preinstall for uninstalled system applications
install_preinstall(){
    sudo apt update
    sudo apt upgrade
    sudo apt install curl -y >/dev/null 2>&1
}

# Postman
install_postman(){
    echo 'Install Postman'
    sudo snap install postman >/dev/null 2>&1
}

# Git Hub Desktop
install_github(){
    echo 'Install GitHub Desktop'
    sudo apt install git -y >/dev/null 2>&1
    # Download des GitHub Packages
    sudo wget https://github.com/shiftkey/desktop/releases/download/release-3.1.1-linux1/GitHubDesktop-linux-3.1.1-linux1.deb >/dev/null 2>&1
    sudo apt install gdebi-core -y >/dev/null 2>&1
    sudo gdebi GitHubDesktop-linux-3.1.1-linux1.deb -n >/dev/null 2>&1

    # Delete the installation Data
    sudo rm GitHubDesktop-linux-3.1.1-linux1.deb
}

# Google Chrome
install_google_chrome(){
    # Download der Chrome Installationsdatei
    echo 'Install Google Chrome'
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb >/dev/null 2>&1
    sudo dpkg -i google-chrome-stable_current_amd64.deb >/dev/null 2>&1

    # Delete the installation Data
    rm google-chrome-stable_current_amd64.deb

    # To join the Bookmarks
    # Start Google Chrome in background
    google-chrome &
    # Wait 2 seconds
    sleep 2
    # Close Google Chrome
    killall chrome


}

# OpenVPN
install_openvpn(){
    echo 'Install OpenVPN'
    sudo apt-get install openvpn -y >/dev/null 2>&1
}

# Slack
install_slack(){
    echo 'Install Slack'
    curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/slack-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/slack-archive-keyring.gpg] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" | sudo tee /etc/apt/sources.list.d/slack.list
    sudo apt update
    sudo apt install slack-desktop
}

# Flameshot
install_flameshot(){
    echo 'Install FlameShot'
    sudo apt install flameshot -y >/dev/null 2>&1
}

# FileZilla
install_filezilla(){
    echo 'Install FileZilla'
    sudo apt install filezilla -y >/dev/null 2>&1
}

# ZSH
isntall_zsh(){
    echo 'Install ZSH'
    sudo apt install zsh -y >/dev/null 2>&1
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

# VSCode
install_vscode(){
    echo 'Install VS Code'
    sudo snap install --classic code >/dev/null 2>&1 
}

# Composer
install_composer(){
    echo 'Install Composer'
    sudo apt install php-cli unzip -y >/dev/null 2>&1
    cd ~
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
}

# ferdium
install_ferdium(){
    echo 'Install Ferdium'
    wget https://github.com/ferdium/ferdium-app/releases/download/v6.7.2/Ferdium-linux-6.7.2-amd64.deb
    sudo apt install ./Ferdium-linux-6.7.2-amd64.deb -y >/dev/null 2>&1
}

# nvm
install_nvm(){
    echo 'Install NVM'
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
    echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm' >> ~/.bash_profile
    source ~/.bash_profile
    nvm ls-remote
    nvm install v16.2.0
    nvm install stable
}

# Sublime
install_sublime(){
    echo 'Install Sublime'
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt update
    sudo apt install sublime-text -y >/dev/null 2>&1
}

# Jetbrains toolbox
install_jetbrains_toolbox(){
    echo 'Jetbrains Toolbox Install'
    sudo apt install libfuse2 >/dev/null 2>&1
    wget https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-2.0.3.17006.tar.gz -P ~/Downloads >/dev/null 2>&1
    cd /opt/ >/dev/null 2>&1
    sudo tar -xvzf ~/Downloads/jetbrains-toolbox-2.0.3.17006.tar.gz >/dev/null 2>&1
    sudo mv jetbrains-toolbox-2.0.3.17006 jetbrains >/dev/null 2>&1
    echo 'open Jetbrains Toolbox'
    sudo jetbrains/jetbrains-toolbox >/dev/null 2>&1
    cd >/dev/null 2>&1

    rm ~/Downloads/jetbrains-toolbox-2.0.3.17006.tar.gz
}

# Displaylink
install_displaylink(){
    echo 'Displaylink Adapter'
    sudo apt update
    curl -o /tmp/synaptics-repository-keyring.deb https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb
    chmod +x /tmp/synaptics-repository-keyring.deb
    sudo apt install /tmp/synaptics-repository-keyring.deb
    sudo apt install displaylink-driver
}

# Docker Compose
install_docker(){
    echo 'Install Docker'
    sudo apt-get install ca-certificates curl gnupg -y >/dev/null 2>&1

    sudo install -m 0755 -d /etc/apt/keyrings >/dev/null 2>&1
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg >/dev/null 2>&1
    sudo chmod a+r /etc/apt/keyrings/docker.gpg >/dev/null 2>&1

    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y >/dev/null 2>&1

    sudo curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

    sudo chmod a+x /usr/local/bin/docker-compose

    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

    if [ -z "$(cat /etc/group | grep docker)" ]; then
    sudo groupadd docker
    fi
}

# Docker settings customization (create sudo user)
docker_post_install(){
    echo 'Docker Post Install'
    sudo usermod -aG docker $USER >/dev/null 2>&1

    sudo systemctl enable docker.service >/dev/null 2>&1

    sudo systemctl enable containerd.service >/dev/null 2>&1

    newgrp docker
    exec bash
}

# Function for a better overview during installation
placeholder(){
    echo ''
}

# Docker Version Controll
version_control(){
    echo ''
    echo ''
    echo '******************************************'
    docker -v
    echo '******************************************'
    docker-compose -v
    echo '******************************************'
    echo ''
    echo ''
}

# Creating Bookmarks for Google Chrom
create_bookmarks(){
    # Define Bookmarks-Data
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
    chrome_dir="$HOME/.config/google-chrome"
    default_dir="$chrome_dir/Default"

    # Erstelle das Verzeichnis, wenn es nicht existiert
    mkdir -p "$default_dir"

    # Erstelle die Bookmarks-Datei und schreibe den Inhalt
    echo "$bookmarks_content" > "$default_dir/Bookmarks"
}

# Reopen Toolbox for Updates
reopen_toolbox(){
    cd /opt/jetbrains
    ./jetbrains-toolbox
    cd
}



# Install Beginn / Calling the functions
sudo apt-get update >/dev/null 2>&1
#root_account_creation
placeholder
install_preinstall
placeholder
install_postman
placeholder
install_github
placeholder
install_google_chrome
placeholder
create_bookmarks
placeholder
install_slack
placeholder
install_openvpn
placeholder
install_flameshot
placeholder
isntall_zsh
placeholder
install_vscode
placeholder
install_jetbrains_toolbox
placeholder
install_composer
placeholder
install_filezilla
placeholder
install_ferdium
placeholder
install_sublime
placeholder
install_nvm
placeholder
install_docker
version_control
placeholder
reopen_toolbox
placeholder
install_displaylink
docker_post_install
