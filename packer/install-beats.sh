#!/bin/bash
set -e

ES_VERSION="${ES_VERSION:-7.9.0}"

curl -L -O "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$ES_VERSION-amd64.deb"
sudo dpkg -i "filebeat-$ES_VERSION-amd64.deb"
rm "filebeat-$ES_VERSION-amd64.deb"

curl -L -O "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-$ES_VERSION-amd64.deb"
sudo dpkg -i "heartbeat-$ES_VERSION-amd64.deb"
rm "heartbeat-$ES_VERSION-amd64.deb"

curl -L -O "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-$ES_VERSION-amd64.deb"
sudo dpkg -i "metricbeat-$ES_VERSION-amd64.deb"
rm "metricbeat-$ES_VERSION-amd64.deb"