#!/bin/bash
# Using modified version of clair with precompiled DB. More info https://github.com/arminc/clair-local-scan
# In case of need to skip some vulnerabilities use this yaml https://github.com/arminc/clair-scanner#example-whitelist-yaml-file
# TODO:
# - check docker existence
# - change script for IP checking
# - make one bin file with all scripts
# - auto detect OS and choose script
unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)    IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' -m 1);;
    *)          IP=172.17.0.1
esac

docker stop db clair &>/dev/null && docker rm db clair &>/dev/null
docker run -d --name db arminc/clair-db:latest
sleep 5

docker run -p ${IP}:6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.6
sleep 5

case "${unameOut}" in
    Darwin*)    ./clair-scanner_darwin_amd64 -c="http://${IP}:6060" --ip "${IP}" --all $1 &> results.txt;;
    *)          ./clair-scanner_linux_amd64 -c="http://${IP}:6060" --ip="${IP}" --all $1 &> results.txt
esac

cat results.txt
docker stop db clair &>/dev/null && docker rm db clair &>/dev/null

if cat results.txt | grep -q 'CRIT\|WARN\|ERRO' ;then
  echo "-------------------------------------------------"
  echo "-------- Image contain vulnerabilities!! --------"
  echo "-------------------------------------------------"
  exit 1
else
  echo "-------------------------------------------------"
  echo "--------------- Image is checked ----------------"
  echo "-------------------------------------------------"
  exit 0
fi
