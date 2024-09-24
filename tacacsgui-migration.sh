#!/bin/bash

# Check if sudo or root are available
if [ $(whoami) != 'root' ]
  then echo "Please run this as root"
  exit
fi

backup_tacacsgui() {
    WHEREAMI=$(pwd)
    BACKUP_DATE=$(date --iso-8601)
    BACKUP_DIR="${WHEREAMI}/TACACSGUI_BACKUP"
    mkdir -p "${BACKUP_DIR}/TAC_PLUS"
    mkdir -p "${BACKUP_DIR}/DB"
    mkdir -p "${BACKUP_DIR}/CONFIGMANAGER"
    mkdir -p "${BACKUP_DIR}/PHP"
    mkdir -p "${BACKUP_DIR}/SSL"
    # MySQL credentials and database name
    DB_MAIN="tgui"
    DB_LOG="tgui_log"

    read -p "Enter the MySQL user, ideally root user: " MYSQL_USER
    read -p "Enter the password for the MySQL user $DB_USER: " -s USERINPUT_PWD
    export MYSQL_PWD=$USERINPUT_PWD

    # DUMP_MAIN_DB="${BACKUP_DATE}_${DB_MAIN}.sql"
    # DUMP_LOG_DB="${BACKUP_DATE}_${DB_LOG}.sql"

    mysqldump --user=$MYSQL_USER --databases tgui > "${BACKUP_DIR}/DB/tgui.sql"
    # mysqldump --user=$MYSQL_USER --databases tgui_log > "${BACKUP_DIR}/DB/tgui_log.sql"

    # tac_plus configuration files
    cp /opt/tacacsgui/tac_plus.cfg "${BACKUP_DIR}/TAC_PLUS/tac_plus.conf"
    cp /opt/tacacsgui/web/api/config.php "${BACKUP_DIR}/PHP/config.php"
    cp /opt/tgui_data/confManager/config.yaml "${BACKUP_DIR}/CONFIGMANAGER/config.yaml"
    cp /opt/tgui_data/confManager/cron.yaml "${BACKUP_DIR}/CONFIGMANAGER/cron.yaml"
    cp /opt/tgui_data/ssl/* "${BACKUP_DIR}/SSL/"

    tar -czvf "${WHEREAMI}/${BACKUP_DATE}_tacacsgui.tar.gz" TACACSGUI_BACKUP

    echo "Backup completed successfully. Backup file: ${WHEREAMI}/${BACKUP_DATE}_tacacsgui.tar.gz"
    echo "Please transfer this to the new server and run restore as required."
}

restore_tacacsgui() {
    echo "EXTREMELY DESTRUCTIVE ACTION. PLEASE BE SURE YOU WANT TO DO THIS."
    echo "BACKUP/SNAPSHOT THE VM BEFORE PROCEEDING."
    read -p "DO YOU REALLY WANT TO DO THIS? THIS WILL OVERWRITE THE CURRENT DATABASE AND CONFIGURATION FILES. [y/n]: " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Aborting..."
        exit 1
    fi
    echo ""
    read -p "ARE YOU SURE? THIS CANNOT BE UNDONE. [y/n]: " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Aborting..."
        exit 1
    fi

    WHEREAMI=$(pwd)
    find -name "*_tacacsgui.tar.gz" -exec tar -xvf {} \;
    BACKUP_DIR="${WHEREAMI}/TACACSGUI_BACKUP"

    # MySQL credentials and database name
    DB_MAIN="tgui"
    DB_LOG="tgui_log"    
    
    # Restore the DB
    echo "Restoring tgui database..."
    mysql -u root tgui < ${BACKUP_DIR}/DB/tgui.sql
    # echo "tgui_log doesn't need to be restored. It's a log database." 
    # read -p "Do you want to restore tgui_log database? [y/n]: " -n 1 -r
    # if [[ $REPLY =~ ^[Yy]$ ]]
    # then
    #    echo "Restoring tgui_log database..."
    #     mysql -u root tgui_log < DB/tgui_log.sql
    # fi
    mysql -u root -e "USE tgui;UPDATE api_settings SET update_url = 'https://localhost/updates' WHERE id = 1;"
    mysql -u root -e "USE tgui;UPDATE api_settings SET update_activated = 0 WHERE id = 1;"
    mysql -u root -e "USE tgui;UPDATE api_settings SET update_signin = 0 WHERE id = 1;"


    # tac_plus configuration files
    sudo cp "${BACKUP_DIR}/TAC_PLUS/tac_plus.conf" /opt/tacacsgui/tac_plus.cfg
    # sudo cp "/PHP/config.php" /opt/tacacsgui/web/api/config.php
    sudo cp "${BACKUP_DIR}/CONFIGMANAGER/config.yaml" /opt/tgui_data/confManager/config.yaml
    sudo cp "${BACKUP_DIR}/CONFIGMANAGER/cron.yaml" /opt/tgui_data/confManager/cron.yaml
    sudo cp ${BACKUP_DIR}/SSL/* /opt/tgui_data/ssl/

    echo "Restore completed successfully."
}


# Main logic
case "$1" in
    backup)
        backup_tacacsgui
        ;;
    restore)
        restore_tacacsgui
        ;;
    *)
        echo "Usage: $0 [backup|restore]"
        exit 1
        ;;
esac