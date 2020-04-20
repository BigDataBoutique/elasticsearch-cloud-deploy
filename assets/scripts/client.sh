#!/bin/bash

/opt/cloud-deploy-scripts/common/config-es.sh

/opt/cloud-deploy-scripts/aws/config-es-discovery.sh

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.master: false
node.data: false
node.ingest: false
EOF

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

/opt/cloud-deploy-scripts/common/config-clients.sh