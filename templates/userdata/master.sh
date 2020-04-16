#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

${auto_attach_ebs_script}

${configure_es_script}

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.master: true
node.data: false
node.ingest: false
EOF

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service