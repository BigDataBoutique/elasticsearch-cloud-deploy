#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Configure elasticsearch
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml

cluster.name: ${es_cluster}

discovery.zen.minimum_master_nodes: ${minimum_master_nodes}

# only data nodes should have ingest and http capabilities
node.master: ${master}
node.data: ${data}
node.ingest: ${data}
http.enabled: ${http_enabled}
xpack.security.enabled: ${security_enabled}

path.logs: ${elasticsearch_logs_dir}

EOF

# add AWS-specific configs only if running on AWS
if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` == ec2 ]; then
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
network.host: _ec2:privateIpv4_,localhost

plugin.mandatory: discovery-ec2
cloud.aws.region: ${aws_region}
cloud.aws.protocol: http # no need in HTTPS for internal AWS calls
discovery:
    zen.hosts_provider: ec2
    ec2.groups: ${security_groups}
    ec2.host_type: private_ip
    ec2.tag.Cluster: ${es_environment}
    ec2.availability_zones: ${availability_zones}
EOF
fi

# add Azure-specific configs only if running on Azure
if `grep -q unknown-245 /var/lib/dhcp/dhclient.eth0.leases`; then
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
network.host: _site_,localhost
EOF
fi

cat <<'EOF' >>/etc/security/limits.conf

# allow user 'elasticsearch' mlockall
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF

cat <<'EOF' >>/etc/systemd/system/elasticsearch.service.d/override.conf
[Service]
LimitMEMLOCK=infinity
EOF

# Setup heap size and memory locking
sudo sed -i 's/#MAX_LOCKED_MEMORY=.*$/MAX_LOCKED_MEMORY=unlimited/' /etc/init.d/elasticsearch
sudo sed -i 's/#MAX_LOCKED_MEMORY=.*$/MAX_LOCKED_MEMORY=unlimited/' /etc/default/elasticsearch
sudo sed -i "s/^-Xms2g/-Xms${heap_size}/" /etc/elasticsearch/jvm.options
sudo sed -i "s/^-Xmx2g/-Xmx${heap_size}/" /etc/elasticsearch/jvm.options

# Storage
sudo mkdir -p ${elasticsearch_logs_dir}
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_logs_dir}

# we are assuming volume is declared and attached when data_dir is passed to the script
if [ -n "${elasticsearch_data_dir}" ]; then
    sudo sed -i '$ a path.data: ${elasticsearch_data_dir}' /etc/elasticsearch/elasticsearch.yml
    sudo mkfs -t ext4 ${volume_name}
    sudo mkdir -p ${elasticsearch_data_dir}
    sudo mount ${volume_name} ${elasticsearch_data_dir}
    sudo echo "${volume_name} ${elasticsearch_data_dir} ext4 defaults,nofail 0 2" >> /etc/fstab
    sudo chown -R elasticsearch:elasticsearch ${elasticsearch_data_dir}
fi

# Setup x-pack security also on Kibana configs where applicable
if [ -f "/etc/kibana/kibana.yml" ]; then
    echo "xpack.security.enabled: ${security_enabled}" | sudo tee -a /etc/kibana/kibana.yml
fi

if [ -f "/etc/nginx/nginx.conf" ]; then
    # Setup basic auth for nginx web front and start the service if exists
    sudo htpasswd -bc /etc/nginx/conf.d/search.htpasswd ${client_user} ${client_pwd}
    sudo service nginx start
fi

# Start Elasticsearch
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
sudo service elasticsearch start