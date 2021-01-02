#!/bin/bash
set +e

echo "Testing AMI Builder if it works properly"


echo "Running common env script"
. /opt/cloud-deploy-scripts/common/env.sh

if [ -e /opt/cloud-deploy-scripts/$cloud_provider/env.sh ]; then
    echo "Running ${cloud_provider} env script"
    . /opt/cloud-deploy-scripts/$cloud_provider/env.sh
fi

# It is required to bind to all interfaces for load balancer on GCP to work
if [ "$cloud_provider" == "gcp" ]; then
    export BIND_TO_ALL="true"
fi

echo "Running EBS volume autoattach script"
/opt/cloud-deploy-scripts/$cloud_provider/autoattach-disk.sh

echo "Running ENI autoattach script"
/opt/cloud-deploy-scripts/$cloud_provider/autoattach-network.sh

echo "Running config-es script"
/opt/cloud-deploy-scripts/common/config-es.sh

echo "Running config-beats script"
/opt/cloud-deploy-scripts/common/config-beats.sh

echo "Running ${cloud_provider}/config-es script"
/opt/cloud-deploy-scripts/$cloud_provider/config-es.sh

echo "Running ${cloud_provider}/config-es-discovery script"
/opt/cloud-deploy-scripts/$cloud_provider/config-es-discovery.sh

echo "Creating elasticsearch.yml file"
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.master: true
node.data: true
node.ingest: true
discovery.type: single-node
EOF

echo "Running config/clients script"

/opt/cloud-deploy-scripts/common/config-clients.sh

# add bootstrap.password to the keystore, so that config-cluster scripts can run
# only done on bootstrap and singlenode nodes, before starting ES
if [ "${security_enabled}" == "true" ]; then
    echo "Configuring elasticsearch keystore"
    echo "${client_pwd}" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin bootstrap.password
fi

#Fix IP Address
echo "Rewriting ENI IP Address in elasticsearch.yml"
sed -i -re "s/_ec2:privateIpv4_/${eni_ipv4}/ig" /etc/elasticsearch/elasticsearch.yml

# Start Elasticsearch
echo "Starting elasticsearch service"

systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

echo "Running config-cluster script"
/opt/cloud-deploy-scripts/common/config-cluster.sh


echo "Running ${cloud_provider}/config-cluster script"
/opt/cloud-deploy-scripts/$cloud_provider/config-cluster.sh



