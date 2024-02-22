#!/bin/bash
set +e

. /opt/cloud-deploy-scripts/common/env.sh
. /opt/cloud-deploy-scripts/$cloud_provider/env.sh

# It is required to bind to all interfaces for load balancer on GCP to work
if [ "$cloud_provider" == "gcp" ]; then
    export BIND_TO_ALL="true"
fi

/opt/cloud-deploy-scripts/common/config-es.sh
/opt/cloud-deploy-scripts/common/config-beats.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-es.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-es-discovery.sh

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.roles: []
EOF

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

/opt/cloud-deploy-scripts/common/config-clients.sh
