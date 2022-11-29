#!/usr/bin/env bash
SCRIPT_NAME=phpbb-upgrader

## bash-fx
if [ -z $(command -v curl) ]; then sudo apt update && sudo apt install curl -y; fi

if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

fxHeader "🆙 phpBB Upgrader"
rootCheck

if [ -z "$1" ]; then
  fxCatastrophicError "No profile provided!"
fi

fxConfigLoader "$1"

fxTitle "Path check..."
if [ -z "${PHPBB_DIR}" ] || [ ! -d "${PHPBB_DIR}" ]; then
  fxCatastrophicError "phpBB directory ##${PHPBB_DIR}## not found!"
fi

PHPBB_DIR=${PHPBB_DIR%/}/
fxOK "OK, ##${PHPBB_DIR}## found!"

if  [ ! -f "${PHPBB_DIR}viewtopic.php" ]; then
  fxCatastrophicError "File ##${PHPBB_DIR}viewtopic.php## not found!"
fi

fxOK "OK, ##${PHPBB_DIR}viewtopic.php## found!"

fxTitle "Retriving zip URL..."
PHPBB_LOCATION_URL=https://raw.githubusercontent.com/TurboLabIt/phpbb-upgrader/main/phpbb-latest-url.txt
fxInfo "${PHPBB_LOCATION_URL}"
PHPBB_NEW_ZIP=$(curl -L --fail-with-body ${PHPBB_LOCATION_URL})
if [ "$?" != 0 ]; then
  fxCatastrophicError "Failure! Response: ##${PHPBB_NEW_ZIP}##"
fi

PHPBB_NEW_ZIP=$(echo ${PHPBB_NEW_ZIP} | xargs)
fxOK "OK, download URL is ##${PHPBB_NEW_ZIP}##"

fxTitle "Creating backup directory..."
fxInfo "${PHPBB_BACKUP_DIR}"
mkdir -p "${PHPBB_BACKUP_DIR}"

fxTitle "Preparing variables..."
PHPBB_BACKUP_OLD_DIR=${PHPBB_BACKUP_DIR}forum_old/
PHPBB_BACKUP_ZIP=${PHPBB_BACKUP_DIR}phpbb-upgrader-backup.zip
PHPBB_DOWNLOADED_ZIP=/tmp/phpbb-upgrader_new-version.zip
PHPBB_NEW_TEMP_DIR=${PHPBB_BACKUP_DIR}forum_new/

fxMessage "👴 Old copy (to be zipped):        ##${PHPBB_BACKUP_OLD_DIR}##"
fxMessage "🗜 Backup, zipped:                  ##${PHPBB_BACKUP_ZIP}##"
fxMessage "⏬ New, downloaded version (zip):  ##${PHPBB_DOWNLOADED_ZIP}##"
fxMessage "🛕 New version:                    ##${PHPBB_NEW_TEMP_DIR}##"

fxTitle "Removing any leftovers..."
rm -rf "${PHPBB_BACKUP_OLD_DIR}"
rm -f "${PHPBB_BACKUP_ZIP}"
rm -f "${PHPBB_DOWNLOADED_ZIP}"
rm -rf "${PHPBB_NEW_TEMP_DIR}"

fxTitle "New version check..."
PHPBB_CLI="sudo -u www-data -H XDEBUG_MODE=off php ${PHPBB_DIR}bin/phpbbcli.php"
${PHPBB_CLI} update:check

fxTitle "Downloading the new phpBB package..."
fxInfo "${PHPBB_NEW_ZIP}"
curl --fail-with-body -Lo "${PHPBB_DOWNLOADED_ZIP}" "${PHPBB_NEW_ZIP}"
if [ "$?" != 0 ]; then
  fxMessage "$(cat ${PHPBB_DOWNLOADED_ZIP})"
  rm -f "${PHPBB_DOWNLOADED_ZIP}"
  fxCatastrophicError "Failure!"
fi

fxInfo "$(ls -lh ${PHPBB_DOWNLOADED_ZIP})"

fxEndFooter
