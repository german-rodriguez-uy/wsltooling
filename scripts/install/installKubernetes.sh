#!/bin/bash

set -euo pipefail
DIR_ME=$(realpath $(dirname $0))

# This script is called by any user. It shall succeed without a username parameter
. ${DIR_ME}/.installUtils.sh
setUserName ${1-"$(whoami)"}


#Start docker deamon
sudo -b sh -c 'nohup dockerd < /dev/null > /var/log/dockerd.log 2>&1'
sleep 10

curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
k3d cluster create mycluster


docker volume create portainer_data 
docker run -d -p 9000:9000 -p 8000:8000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce


curl -o /tmp/kubectl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl


sudo apt install -y httpie jq


export portainerAPI="host.internal:9000/api"
export portainerUserName="admin";
export portainerPassword="Admin12121212";


echo "Initializing admin user..."
http POST $portainerAPI/users/admin/init Username="$portainerUserName" Password="$portainerPassword"

echo "Creating authorization bearer..."
portainerTokenResponse=$(http POST $portainerAPI/auth Username="$portainerUserName" Password="$portainerPassword")	
if ! [[ $portainerTokenResponse = *"jwt"* ]]; then
  echo "Result: failed to login"
  exit 1
fi
portainerToken=$(echo $portainerTokenResponse | jq -r ".jwt")
http --form POST $portainerAPI/endpoints "Authorization: Bearer $portainerToken" Name="local-docker" EndpointCreationType=1

agentShortVersion=$(http GET $portainerAPI/status "Authorization: Bearer $portainerToken" | jq  -r '.Version | capture("(?<major>[0-9]+).(?<minor>[0-9]+)") | .major+"-"+.minor')

localkubernetes=$(http --form POST $portainerAPI/endpoints "Authorization: Bearer $portainerToken" Name="local-kubernetes" EndpointCreationType=4 URL="http://192.168.67.2:9000")

edgeIdVar=$(hexdump -vn16 -e'4/4 "%08X" 1 "\n"' /dev/urandom)
edgeKey=$(echo $localkubernetes | jq  -r '.EdgeKey')
selfSigned=1
agentSecret=""
envVarsTrimmed=""

curl https://downloads.portainer.io/ee${agentShortVersion}/portainer-edge-agent-setup.sh | bash -s -- \"${edgeIdVar}\" \"${edgeKey}\" \"${selfSigned}\" \"${agentSecret}\" \"${envVarsTrimmed}\"




