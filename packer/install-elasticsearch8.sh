#!/bin/bash
set -e

# Get the PGP Key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

apt-get update
if [ -z "$ES_VERSION" ]; then
    echo "Installing the latest Elasticsearch version"
    apt-get install elasticsearch
else
    echo "Installing Elasticsearch version $ES_VERSION"
    apt-get install elasticsearch=$ES_VERSION
fi

mv elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
