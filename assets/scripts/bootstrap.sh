#!/bin/bash

. /opt/cloud-deploy-scripts/$cloud_provider/env.sh

/opt/cloud-deploy-scripts/common/config-es.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-es.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-bootstrap-node.sh
/opt/cloud-deploy-scripts/$cloud_provider/config-es-discovery.sh

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.master: true
node.data: false
node.ingest: false
EOF

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
/opt/cloud-deploy-scripts/$cloud_provider/config-cluster.sh

while true
do
    echo "Checking cluster health"
    HEALTH="$(curl $BASICAUTH --silent -k localhost:9200/_cluster/health | jq -r '.status')"
    if [ "$HEALTH" = "green" ]; then
        break
    fi
    sleep 5
done

if [ "$cloud_provider" == "aws" ]; then
	shutdown -h now
elif [ "$cloud_provider" == "gcp" ]; then
	gcloud compute instances delete $HOSTNAME --zone $GCP_ZONE --quiet
fi