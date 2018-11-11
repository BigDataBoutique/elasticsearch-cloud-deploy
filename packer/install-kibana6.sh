#!/bin/bash
set -e

# Get the PGP Key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list

apt-get update
if [ -z "$ES_VERSION" ]; then
    echo "Installing latest Kibana version"
    apt-get install kibana
else
    echo "Installing Kibana version $ES_VERSION"
    apt-get install kibana=$ES_VERSION
fi

cd /usr/share/kibana/
bin/kibana-plugin install x-pack || true
chown kibana:kibana * -R

# This needs to be here explicitly because of a long first-initialization time of Kibana
systemctl daemon-reload
systemctl enable kibana.service
sudo service kibana start

printf 'Waiting for Kibana to initialize...'
until $(curl --output /dev/null --silent --head --fail http://localhost:5601); do
    printf '.'
    sleep 5
done
