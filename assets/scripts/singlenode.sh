#!/bin/bash

/opt/cloud-deploy-scripts/aws/autoattach-ebs.sh

/opt/cloud-deploy-scripts/common/config-es.sh
/opt/cloud-deploy-scripts/common/config-beats.sh

/opt/cloud-deploy-scripts/aws/config-es-discovery.sh

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.master: true
node.data: true
node.ingest: true
discovery.type: single-node
EOF

/opt/cloud-deploy-scripts/common/config-clients.sh

BASICAUTH=""
if [ "${security_enabled}" == "true" ]; then
    BASICAUTH=" --user ${client_user}:${client_pwd} "
    echo "${client_pwd}" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin bootstrap.password
fi

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

/opt/cloud-deploy-scripts/common/config-cluster.sh