#!/bin/bash
# Using modified version of clair with precompiled DB. More info https://github.com/arminc/clair-local-scan
# In case of need to skip some vulnerabilities use this yaml https://github.com/arminc/clair-scanner#example-whitelist-yaml-file
# TODO:
# - check docker existence
# - change script for IP checking
# - make one bin file with all scripts
# - auto detect OS and choose script
IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' -m 1)

docker stop db clair &>/dev/null && docker rm db clair &>/dev/null
docker run -d --name db arminc/clair-db:latest
sleep 1
docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.6
sleep 1
# docker pull $1

./clair-scanner_linux_amd64 --ip $IP --all $1 &> results.txt
# For mac change to this script
# ./clair-scanner_darwin_amd64 --ip $IP --all $1 &> results.txt

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
