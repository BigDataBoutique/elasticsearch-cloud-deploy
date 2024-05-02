#!/bin/bash
set +e

. /opt/cloud-deploy-scripts/common/env.sh
. /opt/cloud-deploy-scripts/$cloud_provider/env.sh

# It is required to bind to all interfaces for load balancer on GCP to work
if [ "$cloud_provider" == "gcp" ]; then
    export BIND_TO_ALL="true"
fi

/opt/cloud-deploy-scripts/$cloud_provider/autoattach-disk.sh

/opt/cloud-deploy-scripts/common/config-es.sh
/opt/cloud-deploy-scripts/common/config-beats.sh

/opt/cloud-deploy-scripts/$cloud_provider/config-es.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-es-discovery.sh

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.roles: [ data_hot, data_content, ingest, transform, master, remote_cluster_client ]
discovery.type: single-node
EOF

/opt/cloud-deploy-scripts/common/config-clients.sh

# add bootstrap.password to the keystore, so that config-cluster scripts can run
# only done on bootstrap and singlenode nodes, before starting ES
if [ "${security_enabled}" == "true" ]; then
    echo "${client_pwd}" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin bootstrap.password
fi

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

/opt/cloud-deploy-scripts/common/config-cluster.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-cluster.sh
