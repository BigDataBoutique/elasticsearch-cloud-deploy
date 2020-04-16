#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

${auto_attach_ebs_script}

${configure_es_script}

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.master: true
node.data: true
node.ingest: true
discovery.type: single-node
EOF

${configure_clients_script}

BASICAUTH=""
if [ "${security_enabled}" == "true" ]; then
    BASICAUTH=" --user ${client_user}:${client_pwd} "
    echo "${client_pwd}" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin bootstrap.password
fi

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

${configure_cluster_script}
