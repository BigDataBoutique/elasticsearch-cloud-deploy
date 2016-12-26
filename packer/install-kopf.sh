#!/bin/bash
set -e

curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y build-essential nodejs

cd ~
wget https://github.com/synhershko/elasticsearch-kopf/archive/master.tar.gz
tar xvf master.tar.gz
mv elasticsearch-kopf-master/ /opt/
rm master.tar.gz
cd /opt/elasticsearch-kopf-master
npm install

cat <<'EOF' >/opt/elasticsearch-kopf-master/_site/kopf_external_settings.json
{
    "elasticsearch_root_path": "/es",
    "with_credentials": false,
    "theme": "dark",
    "refresh_rate": 5000
}
EOF
