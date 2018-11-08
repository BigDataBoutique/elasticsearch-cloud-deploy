#!/bin/bash
set -e

# TODO get latest beats version

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.4.3-amd64.deb
sudo dpkg -i filebeat-6.4.3-amd64.deb
rm filebeat-6.4.3-amd64.deb

curl -L -O https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-6.4.3-amd64.deb
sudo dpkg -i heartbeat-6.4.3-amd64.deb
rm heartbeat-6.4.3-amd64.deb

curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-6.4.3-amd64.deb
sudo dpkg -i metricbeat-6.4.3-amd64.deb
rm metricbeat-6.4.3-amd64.deb