#!/bin/bash

set -euo pipefail
DIR_ME=$(realpath $(dirname $0))

# This script is called by any user. It shall succeed without a username parameter
. ${DIR_ME}/.installUtils.sh
setUserName ${1-"$(whoami)"}

sudo apt update
sudo apt remove docker docker.io containerd runc
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y --no-install-recommends docker-ce

modifyBashrc "dockerd" "sudo -b sh -c 'nohup dockerd < /dev/null > /var/log/dockerd.log 2>&1'"
sudo usermod -a $USERNAME -G docker


VERSION_DOCKER_COMPOSE="v2.7.0"
if [[ ! -d ~/.docker/cli-plugins ]]; then
  mkdir -p ~/.docker/cli-plugins
fi
curl -fSL https://github.com/docker/compose/releases/download/${VERSION_DOCKER_COMPOSE}/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose
