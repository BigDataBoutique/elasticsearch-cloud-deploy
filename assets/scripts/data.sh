#!/bin/bash
set +e

. /opt/cloud-deploy-scripts/common/env.sh
. /opt/cloud-deploy-scripts/$cloud_provider/env.sh

/opt/cloud-deploy-scripts/$cloud_provider/autoattach-disk.sh

/opt/cloud-deploy-scripts/common/config-es.sh
/opt/cloud-deploy-scripts/common/config-beats.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-es.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-es-discovery.sh

if [ "$is_voting_only" == "true" ]
then
  cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.roles: [ data_hot, data_content, ingest, transform, master, voting_only, remote_cluster_client]
EOF
else
  cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.roles: [ data_hot, data_content, ingest, transform, remote_cluster_client ]
EOF
fi

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service
