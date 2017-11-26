#!/bin/bash
set -e

echo "deb https://packagecloud.io/grafana/stable/debian/ jessie main" | tee -a /etc/apt/sources.list
curl https://packagecloud.io/gpg.key | apt-key add -

sudo apt-get update && sudo apt-get install grafana
