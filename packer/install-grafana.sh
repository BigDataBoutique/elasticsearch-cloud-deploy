#!/bin/bash
set -e

sudo wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -

sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt-get update
sudo apt-get install grafana