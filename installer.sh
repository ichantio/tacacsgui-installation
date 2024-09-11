#!/bin/bash
# Logs output
exec > >(tee -a logs/installer.log) 2>&1
echo ""
echo "Starting installation... at $(date)"
echo ""
# Check if sudo or root are available
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or with sudo"
  exit
fi

# Check if the system is Ubuntu and the version is 22.04
# If it's Ubuntu and version is 24.04, then give a warning and continue
# If it's not Ubuntu, then give an error and exit
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$NAME" == "Ubuntu" ]; then
        if [ "$VERSION_ID" == "22.04" ]; then
            echo "Ubuntu 22.04 detected"
        elif [ "$VERSION_ID" == "24.04" ]; then
            echo "Ubuntu 24.04 detected"
            echo "This script is intended for Ubuntu 22.04"
            echo "It may not work as expected"
            read -p "Do you want to continue? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            echo "Ubuntu version $VERSION_ID is not supported"
            exit 1
        fi
    else
        echo "This script is intended for Ubuntu"
        exit 1
    fi
else
    echo "This script is intended for Ubuntu"
    exit 1
fi

# Where am I?
INSTALLER_DIR=$(pwd)

# Load the configuration file
source ${INSTALLER_DIR}/conf/install_params.conf

echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  Install base required packages...\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
# Check the system is up-to-date
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get upgrade -y > /dev/null 2>&1
sudo apt-get install -y tar expect curl vim net-tools > /dev/null 2>&1

# NTP
sudo apt-get install -y ntp

# PHP8.3
sudo apt-get install -y php8.3 php8.3-curl php8.3-ldap
# NOTE: This will also install apache2
# Other PHP packages:
sudo apt-get install -y php8.3-common php8.3-cli php8.3-dev php8.3-gd php8.3-mbstring php8.3-zip php8.3-mysql php8.3-xml libapache2-mod-php8.3 libapache2-mod-xsendfile
sudo apt-get install -y php8.3-fpm
# PHP FPM
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.3-fpm
sudo systemctl restart apache2

# Add to sudoers.d
sudo cp ${INSTALLER_DIR}/conf/www-data-sudo /etc/sudoers.d/www-data-sudo
sudo chmod 640 /etc/sudoers.d/www-data-sudo

echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  Install and config MYSQL...\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
# MYSQL
# python-software-properties > software-properties-common
sudo apt-get install -y mysql-server python3-mysqldb libmysqlclient-dev

# MYSQL CONFIG
# Generate a random 12 character password
MYSQL_TGUIPASS=$(openssl rand -base64 16 | tr -cd '[:alnum:]' | cut -c1-12)
MYSQL_ROOTPASS=$(openssl rand -base64 16 | tr -cd '[:alnum:]' | cut -c1-12)
# Config MYSQL for TACACS GUI
sudo mysql -u root -e "CREATE DATABASE tgui; CREATE DATABASE tgui_log;"
sudo mysql -u root -e "CREATE USER 'tgui_user'@'localhost' IDENTIFIED BY '$MYSQL_TGUIPASS';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON tgui.* TO 'tgui_user'@'localhost';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON tgui_log.* TO 'tgui_user'@'localhost';"
sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOTPASS'; FLUSH PRIVILEGES;"

# SAVE MYSQL PASSWORDS
sudo unbuffer expect -c "
spawn mysql_config_editor set --login-path=root --host=localhost --user=root --password
expect -nocase \"Enter password:\" {send \"$MYSQL_ROOTPASS\r\"; interact}
" > /dev/null
sudo unbuffer expect -c "
spawn mysql_config_editor set --login-path=tacacsgui --host=localhost --user=tgui_user --password
expect -nocase \"Enter password:\" {send \"$MYSQL_TGUIPASS\r\"; interact}
" > /dev/null
echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  root and tgui_user mysql password encrypted using mysql_config_editor\033[0m"
echo -e "\033[0;31m  View using my_print_defaults -s [root|tacacsgui] as root user\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
echo ""
echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  Install Python packages...\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
# PYTHON
sudo apt-get install -y python3-pip software-properties-common meson python3-git python3-typing-extensions python3-greenlet python3-gitdb python3-markupsafe python3-dbus
# Needs this for mysqlclient
sudo apt-get install -y python3-dev default-libmysqlclient-dev build-essential libcurl4-openssl-dev libssl-dev
# More stuff
sudo apt-get install -y pkg-config libcairo2-dev libjpeg-dev libgif-dev make gcc openssl curl zip unzip libnet-ldap-perl ldap-utils libapache2-mod-xsendfile libpcre3-dev:amd64 libbind-dev
# System base python instead of pip
sudo apt-get install -y python3-sqlalchemy python3-alembic python3-pyotp python3-mysqldb python3-pexpect python3-requests python3-pycurl python3-yaml python3-gi
# pyyaml is python3-yaml
# argparse is standard in new python3
# pygobject is python3-gi
# python3 -m pip install --upgrade pip
# python3 -m pip install pyyaml argparse pygobject

echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  Install TACACSGUI...\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
# Create opt
sudo mkdir -p /opt/tacacsgui
# Clone main repo
sudo git clone https://github.com/ichantio/tacacsgui.git /opt/tacacsgui
#
sudo chown -R www-data:www-data /opt/tacacsgui
sudo find /opt/tacacsgui -type d -exec chmod 755 {} \;
sudo find /opt/tacacsgui/web -type f -exec chmod 644 {} \;
sudo touch /opt/tacacsgui/tacTestOutput.txt
sudo touch /opt/tacacsgui/tac_plus.cfg
sudo touch /opt/tacacsgui/tac_plus.cfg_test
# PHP conf
sudo cp /opt/tacacsgui/web/api/config_example.php /opt/tacacsgui/web/api/config.php
sudo sed -i "s/<datatabase_passwd_here>/${MYSQL_TGUIPASS}/g" /opt/tacacsgui/web/api/config.php
# Permissions and Ownership
sudo chown -R www-data:www-data /opt/tacacsgui
sudo chmod 774 /opt/tacacsgui/main.sh /opt/tacacsgui/backup.sh /opt/tacacsgui/tac_plus.sh
sudo chmod 774 /opt/tacacsgui/interfaces.py
sudo chmod 777 /opt/tacacsgui/parser/tacacs_parser.sh
sudo chmod 660 /opt/tacacsgui/tac_plus.cfg*
sudo chmod 660 /opt/tacacsgui/tacTestOutput.txt
sudo find /opt/tacacsgui/web -type d -exec chmod 755 {} \;
sudo find /opt/tacacsgui/web -type f -exec chmod 644 {} \;
sudo chmod 640 /opt/tacacsgui/web/api/config.php


# Create folder for data storage
sudo mkdir -p /opt/tgui_data/backups
sudo mkdir -p /opt/tgui_data/ha
sudo mkdir -p /opt/tgui_data/confManager/configs
sudo mkdir -p /opt/tgui_data/ssl
sudo mkdir -p /var/log/tacacsgui/apache2
sudo mkdir -p /var/log/tacacsgui/tac_plus
# Create default files
sudo touch /opt/tgui_data/ha/ha.yaml
sudo echo -n '[]' > /opt/tgui_data/ha/ha.yaml
sudo touch /opt/tgui_data/confManager/config.yaml
sudo echo -n '[]' > /opt/tgui_data/confManager/config.yaml
sudo touch /opt/tgui_data/confManager/cron.yaml
sudo echo -n '[]' > /opt/tgui_data/confManager/cron.yaml
# Took ownership
sudo chown -R www-data:www-data /opt/tgui_data
sudo chown -R www-data:www-data /var/log/tacacsgui
sudo find /opt/tgui_data -type d -exec chmod 755 {} \;

# CHECK IF VARIABLE for GENERATING SSL CERT and KEY or GENERATE CSR instead
sed -i "s/tacacsgui.lan/${WEBSERVER_NAME}/g" ${INSTALLER_DIR}/conf/web_*.cnf
if [ $WEBSERVER_SELFSIGNED_CERT = 1 ]; then
    echo "Generating SSL cert and key..."
    sudo openssl req -x509 -nodes -days 365 -new -keyout /opt/tgui_data/ssl/tacacsgui.local.key -out /opt/tgui_data/ssl/tacacsgui.local.cer -config ${INSTALLER_DIR}/conf/web_ssl_params.cnf
    sudo chown root:root /opt/tgui_data/ssl/tacacsgui.local.cer
    sudo chmod 644 /opt/tgui_data/ssl/tacacsgui.local.cer
    echo -e "SSL cert and key generated, \033[0;36m/opt/tgui_data/ssl/\033[0m"
    echo "You can change to your own later"
else
    echo "Generating CSR..."
    sudo openssl req -new -nodes -keyout /opt/tgui_data/ssl/tacacsgui.local.key -out /opt/tgui_data/ssl/tacacsgui.local.csr -config ${INSTALLER_DIR}/conf/web_ssl_params.cnf
    sudo chown root:root /opt/tgui_data/ssl/tacacsgui.local.csr
    sudo chmod 644 /opt/tgui_data/ssl/tacacsgui.local.csr
    echo "CSR generated, /opt/tgui_data/ssl/tacacsgui.local.csr"
    echo -e "Please get a cert from your provider and save to: \033[0;36m/opt/tgui_data/ssl/tacacsgui.local.cer\033[0m"
    echo -e "Cert file permission: \033[0;31mroot:root, 644\033[0m"
    sudo cat /opt/tgui_data/ssl/tacacsgui.local.csr
fi
# Key permissions
sudo chown root:ssl-cert /opt/tgui_data/ssl/tacacsgui.local.key
sudo chmod 640 /opt/tgui_data/ssl/tacacsgui.local.key

echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  Install PHP packages via composer...\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
# PHP COMPOSER
mkdir composer
cd composer/
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
HASH=$(curl -sS https://composer.github.io/installer.sig)
sudo php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
# Make composer cache folder writable by www-data
sudo mkdir -p /var/www/.cache/composer/repo/https---repo.packagist.org/
sudo mkdir -p /var/www/.cache/composer/files/
sudo chmod -R 777 /var/www/.cache/composer/repo/https---repo.packagist.org/
sudo chmod -R 777 /var/www/.cache/composer/files/
# Install PHP packages
sudo -u www-data composer update -d /opt/tacacsgui/web/api --ignore-platform-req=php
sudo -u www-data composer install -d /opt/tacacsgui/web/api --ignore-platform-req=php
cd ${INSTALLER_DIR}


echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  Install tac_plus...\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
# Setup TAC_PLUS
# TAC_PLUS included 2024-09-11 download
# git clone https://github.com/MarcJHuber/event-driven-servers.git tac_plus
tar -xvf tac_plus.tgz
cd ${INSTALLER_DIR}/tac_plus/
${INSTALLER_DIR}/tac_plus/configure --with-pcre2 tac_plus
sudo make
sudo make install
cd ${INSTALLER_DIR}

sudo cp ${INSTALLER_DIR}/conf/tac_plus_base.cfg /opt/tacacsgui/tac_plus.cfg
sudo cp ${INSTALLER_DIR}/conf/tac_plus_init.conf /etc/init/tac_plus.conf
sudo chown root:root /etc/init/tac_plus.conf
sudo chmod 644 /etc/init/tac_plus.conf

sudo cp /opt/tacacsgui/tac_plus.sh /etc/init.d/tac_plus
sudo chown root:root /etc/init.d/tac_plus
sudo chmod 750 /etc/init.d/tac_plus
sudo systemctl daemon-reload
sudo systemctl enable tac_plus
sudo systemctl start tac_plus

echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  Enable TACACSGUI apache...\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
# Setup apache
sudo cp ${INSTALLER_DIR}/conf/web_tacacsgui* /etc/apache2/sites-available/
sudo a2enmod rewrite ssl xsendfile headers
sudo systemctl restart apache2
sudo a2dissite 000-default.conf
sudo a2ensite web_tacacsgui_default.conf
sudo a2ensite web_tacacsgui_global.conf
sudo a2ensite web_tacacsgui_ssl.conf
sudo systemctl restart apache2

ACCESS_IP_ADDRESS=$(hostname -I | cut -d' ' -f1)

echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;36m  Installation completed. Access via https://${ACCESS_IP_ADDRESS}\033[0m"
echo -e "\033[0;36m  Default user and password: tacgui/tacgui\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;36m  SSL certs and key are in /opt/tgui_data/ssl\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"
echo -e "\033[0;31m  root and tgui_user mysql password encrypted using mysql_config_editor\033[0m"
echo -e "\033[0;31m  This let you use mysql -u root (as root) to enter DB automatically \033[0m"
echo -e "\033[0;31m  View using my_print_defaults -s [root|tacacsgui] as root user\033[0m"
echo -e "\033[0;33m#########################################################################\033[0m"


# END