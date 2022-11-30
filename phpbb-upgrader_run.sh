#!/usr/bin/env bash

## Based on https://www.phpbb.com/support/docs/en/3.3/ug/upgradeguide/update_full/

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

fxTitle "Preparing variables..."
PHPBB_BACKUP_DIR=${PHPBB_BACKUP_DIR%/}/
PHPBB_BACKUP_ZIP=${PHPBB_BACKUP_DIR}phpbb-upgrader-backup.zip
PHPBB_DOWNLOADED_ZIP=/tmp/phpbb-upgrader_new-version.zip
PHPBB_NEW_TEMP_DIR=/tmp/phpbb-upgrader_new-instance/
## the downloaded zip has a phpBB root dir inside
PHPBB_NEW_TEMP_DIR_FILES=${PHPBB_NEW_TEMP_DIR}phpBB3/
PHPBB_LOCATION_URL=https://raw.githubusercontent.com/TurboLabIt/phpbb-upgrader/main/phpbb-latest-url.txt

fxMessage "👴 Old instance backup:            ##${PHPBB_BACKUP_DIR}##"
fxMessage "🗜 Backup, zipped:                  ##${PHPBB_BACKUP_ZIP}##"
fxMessage "⏬ New, downloaded version (zip):  ##${PHPBB_DOWNLOADED_ZIP}##"
fxMessage "🛕 New instance:                   ##${PHPBB_NEW_TEMP_DIR}##"
fxMessage "😢 New instance subfolder:         ##${PHPBB_NEW_TEMP_DIR_FILES}##"
fxMessage "🐐 Zip locator:                    ##${PHPBB_LOCATION_URL}##"

fxTitle "Creating the backup directory..."
fxInfo "${PHPBB_BACKUP_DIR}"
mkdir -p "${PHPBB_BACKUP_DIR}"

fxTitle "Removing any leftovers..."
rm -rf "${PHPBB_BACKUP_DIR}"
rm -f "${PHPBB_BACKUP_ZIP}"
rm -rf "${PHPBB_NEW_TEMP_DIR}"

fxTitle "New version check..."
PHPBB_CLI="sudo -u www-data -H XDEBUG_MODE=off php ${PHPBB_DIR}bin/phpbbcli.php"
${PHPBB_CLI} update:check

fxTitle "Retriving zip URL..."
fxInfo "${PHPBB_LOCATION_URL}"
PHPBB_NEW_ZIP=$(curl -L --fail-with-body ${PHPBB_LOCATION_URL})
if [ "$?" != 0 ]; then
  fxCatastrophicError "Failure! Response: ##${PHPBB_NEW_ZIP}##"
fi

PHPBB_NEW_ZIP=$(echo ${PHPBB_NEW_ZIP} | xargs)
fxOK "OK, download URL is ##${PHPBB_NEW_ZIP}##"

fxTitle "Downloading the new phpBB package..."
if [ ! -f "${PHPBB_DOWNLOADED_ZIP}" ]; then

  fxInfo "${PHPBB_NEW_ZIP}"
  curl --fail-with-body -Lo "${PHPBB_DOWNLOADED_ZIP}" "${PHPBB_NEW_ZIP}"
  if [ "$?" != 0 ]; then
    fxMessage "$(cat ${PHPBB_DOWNLOADED_ZIP})"
    rm -f "${PHPBB_DOWNLOADED_ZIP}"
    fxCatastrophicError "Failure!"
  fi

  fxOK "OK, got it!"

  fxTitle "Test the downloaded file..."
  unzip -qt ${PHPBB_DOWNLOADED_ZIP}
  if [ "$?" != 0 ]; then
    rm -f "${PHPBB_DOWNLOADED_ZIP}"
    fxCatastrophicError "Failure!"
  fi

else

  fxOK "Cached zip found, download skipped!"
fi

fxInfo "Downloaded zip: ##${PHPBB_DOWNLOADED_ZIP}##"
fxInfo "$(ls -lh ${PHPBB_DOWNLOADED_ZIP})"

fxTitle "Unzipping..."
unzip -qo "${PHPBB_DOWNLOADED_ZIP}" -d "${PHPBB_NEW_TEMP_DIR}"
if [ "$?" != 0 ]; then
  rm -f "${PHPBB_DOWNLOADED_ZIP}"
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

fxTitle "Removing stuff from the extracted data..."
rm -f "${PHPBB_NEW_TEMP_DIR_FILES}config.php"
rm -rf "${PHPBB_NEW_TEMP_DIR_FILES}files"
rm -rf "${PHPBB_NEW_TEMP_DIR_FILES}images"
rm -rf "${PHPBB_NEW_TEMP_DIR_FILES}store"
rm -rf "${PHPBB_NEW_TEMP_DIR_FILES}docs"

fxTitle "Closing the board..."
${PHPBB_CLI} config:set board_disable 1

zzmysqldump ${PHPBB_ZZMYSQLDUMP_PROFILE_NAME}

fxTitle "Copying stuff over from the old directory to the new one..."
cp -a "${PHPBB_DIR}.gitignore" "${PHPBB_NEW_TEMP_DIR_FILES}"
cp -a "${PHPBB_DIR}config.php" "${PHPBB_NEW_TEMP_DIR_FILES}"
cp -a "${PHPBB_DIR}ext" "${PHPBB_NEW_TEMP_DIR_FILES}"
cp -a "${PHPBB_DIR}files" "${PHPBB_NEW_TEMP_DIR_FILES}"
cp -a "${PHPBB_DIR}images" "${PHPBB_NEW_TEMP_DIR_FILES}"
cp -a "${PHPBB_DIR}store" "${PHPBB_NEW_TEMP_DIR_FILES}"
cp -a "${PHPBB_DIR}styles" "${PHPBB_NEW_TEMP_DIR_FILES}styles_old"
cp -a "${PHPBB_DIR}mobiquo" "${PHPBB_NEW_TEMP_DIR_FILES}"
cp -a "${PHPBB_DIR}language" "${PHPBB_NEW_TEMP_DIR_FILES}language_old"

fxTitle "Removing stuff from the new instance..."
find "${PHPBB_NEW_TEMP_DIR_FILES}store" -type f -mtime +15 -name '*.log' -delete

fxTitle "Merging some directories..."
rsync -a "${PHPBB_NEW_TEMP_DIR_FILES}styles/" "${PHPBB_NEW_TEMP_DIR_FILES}styles_old/"
rm -rf "${PHPBB_NEW_TEMP_DIR_FILES}styles"
mv "${PHPBB_NEW_TEMP_DIR_FILES}styles_old" "${PHPBB_NEW_TEMP_DIR_FILES}styles"

rsync -a "${PHPBB_NEW_TEMP_DIR_FILES}language/" "${PHPBB_NEW_TEMP_DIR_FILES}language_old/"
rm -rf "${PHPBB_NEW_TEMP_DIR_FILES}language"
mv "${PHPBB_NEW_TEMP_DIR_FILES}language_old" "${PHPBB_NEW_TEMP_DIR_FILES}language"

fxTitle "DB upgrade..."
chmod ugo=rwx ${PHPBB_NEW_TEMP_DIR} -R
sudo -u www-data -H XDEBUG_MODE=off php ${PHPBB_NEW_TEMP_DIR_FILES}bin/phpbbcli.php db:migrate --safe-mode

fxTitle "Setting root:www-data as owner..."
chown root:www-data "${PHPBB_NEW_TEMP_DIR_FILES}" -R

fxTitle "Applying strict permissions..."
# reset, to make "rwX" work as expected
chmod ugo= "${PHPBB_NEW_TEMP_DIR_FILES}" -R
chmod u=rwX,g=rX,o= "${PHPBB_NEW_TEMP_DIR_FILES}" -R
chmod ug=r,o= "${PHPBB_NEW_TEMP_DIR_FILES}config.php"

fxTitle "Making some folders writable by www-data..."
chmod ug=rwX,o= ${PHPBB_NEW_TEMP_DIR_FILES}cache -R
chmod ug=rwX,o= ${PHPBB_NEW_TEMP_DIR_FILES}images/avatars/upload -R
chmod ug=rwX,o= ${PHPBB_NEW_TEMP_DIR_FILES}files -R
chmod ug=rwX,o= ${PHPBB_NEW_TEMP_DIR_FILES}store -R

fxTitle "Removing the install directory..."
rm -rf "${PHPBB_NEW_TEMP_DIR_FILES}install"

fxTitle "🚀🚀🚀 BRACE FOR IMPACT - MOVING THE OLD INSTANCE TO BACKUP 🚀🚀🚀"
mv "${PHPBB_DIR}" "${PHPBB_BACKUP_DIR}"

fxTitle "🚀🚀🚀 HOLD TIGHT - MOVING THE NEW INSTANCE IN 🚀🚀🚀"
mv "${PHPBB_NEW_TEMP_DIR_FILES}" "${PHPBB_DIR}"

fxTitle "💨 Running ${PHPBB_AFTER_UPGRADE_SCRIPT}..."
if [ ! -z "${PHPBB_AFTER_UPGRADE_SCRIPT}" ]; then
  bash "$PHPBB_AFTER_UPGRADE_SCRIPT"
else
  fxInfo "No after-upgrade script configured"
fi

fxTitle "Re-opening the board..."
${PHPBB_CLI} config:set board_disable 0

fxTitle "Final cache flushing..."
${PHPBB_CLI} cache:purge

fxEndFooter
