#!/bin/bash
set -e

# Configure elasticsearch
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml

cluster.name: ${es_cluster}

# our init.d script sets the default to this as well
path:
  logs: ${elasticsearch_logs_dir}
  data: ${elasticsearch_data_dir}

network.host: _ec2:privateIpv4_
discovery.type: ec2
discovery.ec2.groups: ${security_groups}
discovery.ec2.tag.es_env: ${es_environment}
cloud.aws.region: ${aws_region}
discovery.ec2.availability_zones: ${availability_zones}

discovery.zen.minimum_master_nodes: ${minimum_master_nodes}
EOF

# Set heap size
sudo sed -i 's/#MAX_LOCKED_MEMORY=unlimited/MAX_LOCKED_MEMORY=unlimited/' /etc/sysconfig/elasticsearch
sudo sed -i "s/#ES_HEAP_SIZE=.*$/ES_HEAP_SIZE=${heap_size}/" /etc/sysconfig/elasticsearch

# Storage
sudo mkfs -t ext4 ${volume_name}
sudo mkdir -p ${elasticsearch_data_dir}
sudo mkdir -p ${elasticsearch_logs_dir}
sudo mount ${volume_name} ${elasticsearch_data_dir}
sudo echo "${volume_name} ${elasticsearch_data_dir} ext4 defaults,nofail 0 2" >> /etc/fstab
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_data_dir}
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_logs_dir}

# Start Elasticsearch
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service