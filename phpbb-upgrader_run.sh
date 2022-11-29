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
## the downloaded zip has a phpBB root dir inside
PHPBB_NEW_TEMP_DIR_FILES=${PHPBB_NEW_TEMP_DIR}phpBB3/

fxMessage "👴 Old instance (to be zipped):    ##${PHPBB_BACKUP_OLD_DIR}##"
fxMessage "🗜 Backup, zipped:                  ##${PHPBB_BACKUP_ZIP}##"
fxMessage "⏬ New, downloaded version (zip):  ##${PHPBB_DOWNLOADED_ZIP}##"
fxMessage "🛕 New instance:                   ##${PHPBB_NEW_TEMP_DIR}##"
fxMessage "😢 New instance subfolder:         ##${PHPBB_NEW_TEMP_DIR_FILES}##"

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

fxOK "OK, got it!"
fxInfo "$(ls -lh ${PHPBB_DOWNLOADED_ZIP})"

fxTitle "Test the downloaded file..."
unzip -qt ${PHPBB_DOWNLOADED_ZIP}
if [ "$?" != 0 ]; then
  rm -f "${PHPBB_DOWNLOADED_ZIP}"
  fxCatastrophicError "Failure!"
fi

fxTitle "Unzipping..."
unzip -qo "${PHPBB_DOWNLOADED_ZIP}" -d "${PHPBB_NEW_TEMP_DIR}"
UNZIP_RESULT=$?
rm -f "${PHPBB_DOWNLOADED_ZIP}"
if [ "$UNZIP_RESULT" != 0 ]; then
  fxCatastrophicError "Failure!"
fi

fxTitle "Checking unzipped files..."
ls -l "${PHPBB_NEW_TEMP_DIR}"
echo "-----"
ls -l "${PHPBB_NEW_TEMP_DIR_FILES}"
if [ ! -f "${PHPBB_NEW_TEMP_DIR_FILES}viewtopic.php" ]; then
  rm -rf "${PHPBB_NEW_TEMP_DIR}"
  fxCatastrophicError "viewtopic.php doesn't exist in ${PHPBB_NEW_TEMP_DIR_FILES}viewtopic.php"
fi

fxTitle "Closing the board..."
${PHPBB_CLI} config:set board_disable 1

zzmysqldump ${PHPBB_ZZMYSQLDUMP_PROFILE_NAME}

fxTitle "Zipping the current instance for backup..."
zip -qr9 "${PHPBB_BACKUP_ZIP}" "${PHPBB_DIR}"
fxOK "OK, backup zip created in ##${PHPBB_BACKUP_ZIP}##"
fxInfo "$(ls -lh ${PHPBB_BACKUP_ZIP})"

fxTitle "Test the backup..."
unzip -l ${PHPBB_BACKUP_ZIP}
unzip -qt ${PHPBB_BACKUP_ZIP}
if [ "$?" != 0 ]; then
  rm -f "${PHPBB_BACKUP_ZIP}"
  fxCatastrophicError "Failure!"
fi

fxEndFooter
