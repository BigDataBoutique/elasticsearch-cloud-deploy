#!/bin/bash
set -e

# Get the PGP Key
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

# echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

apt-get update
if [ -z "$ES_VERSION" ]; then
    echo "Installing latest Kibana version"
    apt-get install kibana
else
    echo "Installing Kibana version $ES_VERSION"
    apt-get install kibana=$ES_VERSION
fi

# This needs to be here explicitly because of a long first-initialization time of Kibana
systemctl daemon-reload
systemctl enable kibana.service
sudo service kibana start
