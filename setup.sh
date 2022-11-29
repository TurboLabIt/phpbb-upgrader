#!/usr/bin/env bash
echo ""
SCRIPT_NAME=phpbb-upgrader

## bash-fx
if [ -z $(command -v curl) ]; then sudo apt update && sudo apt install curl -y; fi
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

sudo bash /usr/local/turbolab.it/bash-fx/setup/start.sh ${SCRIPT_NAME}
sudo apt install -y zip unzip
fxLinkBin ${INSTALL_DIR}${SCRIPT_NAME}.sh

## zzmysqldump
curl -s https://raw.githubusercontent.com/TurboLabIt/zzmysqldump/master/setup.sh?$(date +%s) | sudo bash

sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}
