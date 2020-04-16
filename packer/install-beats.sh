#!/bin/bash
set -e

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.5.0-amd64.deb
sudo dpkg -i filebeat-7.5.0-amd64.deb
rm filebeat-7.5.0-amd64.deb

curl -L -O https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-7.5.0-amd64.deb
sudo dpkg -i heartbeat-7.5.0-amd64.deb
rm heartbeat-7.5.0-amd64.deb

curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-7.5.0-amd64.deb
sudo dpkg -i metricbeat-7.5.0-amd64.deb
rm metricbeat-7.5.0-amd64.deb