#!/bin/bash
set -e

# Get the PGP Key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list

apt-get update
if [ -z "$ES_VERSION" ]; then
    echo "Installing the latest Elasticsearch version"
    apt-get install elasticsearch
else
    echo "Installing Elasticsearch version $ES_VERSION"
    apt-get install elasticsearch=$ES_VERSION
fi

cd /usr/share/elasticsearch/
bin/elasticsearch-plugin install --batch x-pack || true
cd -

mv elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
