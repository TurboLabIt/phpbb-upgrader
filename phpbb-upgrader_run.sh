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

PHPBB_CLI="sudo -u www-data -H XDEBUG_MODE=off php ${PHPBB_DIR}bin/phpbbcli.php"

fxTitle "Creating backup directory..."
echo "${PHPBB_BACKUP_DIR}"
mkdir -p "${PHPBB_BACKUP_DIR}"
touch "${PHPBB_BACKUP_DIR}WARNING! ⚠️ This folder gets cleaned periodically ⚠️"

fxTitle "New version check..."
${PHPBB_CLI} update:check

fxTitle "Retriving zip URL..."
PHPBB_LOCATION_URL=https://raw.githubusercontent.com/TurboLabIt/phpbb-upgrader/main/phpbb-latest-url.txt
fxInfo "${PHPBB_LOCATION_URL}"
PHPBB_NEW_ZIP=$(curl -L --fail-with-body ${PHPBB_LOCATION_URL})
if [ "$?" != 0 ]; then
  fxCatastrophicError "Failure! Response: ##${PHPBB_NEW_ZIP}##"
fi

awk '{$PHPBB_NEW_ZIP=$PHPBB_NEW_ZIP};1'
fxOK "OK, download URL is ##${PHPBB_NEW_ZIP}##"

fxEndFooter
