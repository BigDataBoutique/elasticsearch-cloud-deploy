#!/bin/bash
set -e

# Get the PGP Key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

apt-get update
if [ -z "$ES_VERSION" ]; then
    echo "Installing the latest Elasticsearch version"
    apt-get install elasticsearch
else
    echo "Installing Elasticsearch version $ES_VERSION"
    apt-get install elasticsearch=$ES_VERSION
fi

mv elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
