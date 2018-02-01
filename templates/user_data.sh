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
xpack.monitoring.enabled: ${monitoring_enabled}
path.data: ${elasticsearch_data_dir}
path.logs: ${elasticsearch_logs_dir}
EOF


if [ "${cloud_provider}" == "aws" ]; then
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

# Azure doesn't have a proper discovery plugin, hence we are going old-school and relying on scaleset name prefixes
if [ "${cloud_provider}" == "azure" ]; then
        cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
network.host: _site_,localhost

# For discovery we are using predictable hostnames (thanks for the computer name prefix), but could just as well use the
# predictable subnet addresses starting at 10.1.0.5.
EOF

    # avoiding discovery noise in single-node scenario
    if [ "${minimum_master_nodes}" == "1" ]; then
        cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
discovery.zen.ping.unicast.hosts: ["${es_cluster}-master000000", "${es_cluster}-data000000"]
EOF
    else
        cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
discovery.zen.ping.unicast.hosts: ["${es_cluster}-master000000", "${es_cluster}-master000001", "${es_cluster}-master000002", "${es_cluster}-data000000", "${es_cluster}-data000001"]
EOF
    fi
fi

cat <<'EOF' >>/etc/security/limits.conf

# allow user 'elasticsearch' mlockall
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF

sudo mkdir -p /etc/systemd/system/elasticsearch.service.d
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
if [ "true" == "${data}" ]; then
    sudo mkdir -p ${elasticsearch_data_dir}
    sudo chown -R elasticsearch:elasticsearch ${elasticsearch_data_dir}
    if [[ "${cloud_provider}" == "aws" && -n "${volume_name}" ]]; then
        sudo mkfs -t ext4 ${volume_name}
        sudo mount ${volume_name} ${elasticsearch_data_dir}
        sudo echo "${volume_name} ${elasticsearch_data_dir} ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
fi

if [ -f "/etc/nginx/nginx.conf" ]; then
    # Setup basic auth for nginx web front and start the service if exists
    sudo htpasswd -bc /etc/nginx/conf.d/search.htpasswd ${client_user} "${client_pwd}"
    sudo service nginx start
fi

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service


# Setup x-pack security also on Kibana configs where applicable
if [ -f "/etc/kibana/kibana.yml" ]; then
    echo "xpack.security.enabled: ${security_enabled}" | sudo tee -a /etc/kibana/kibana.yml
    echo "xpack.monitoring.enabled: ${monitoring_enabled}" | sudo tee -a /etc/kibana/kibana.yml
    systemctl daemon-reload
    systemctl enable kibana.service
    sudo service kibana restart
fi

if [ -f "/etc/nginx/nginx.conf" ]; then
    sudo rm /etc/grafana/grafana.ini
    cat <<'EOF' >>/etc/grafana/grafana.ini
[security]
admin_user = ${client_user}
admin_password = ${client_pwd}
EOF
    sudo /bin/systemctl daemon-reload
    sudo /bin/systemctl enable grafana-server.service
    sudo service grafana-server start
fi

sleep 60
if [ `systemctl is-failed elasticsearch.service` == 'failed' ];
then
    log "Elasticsearch unit failed to start"
    exit 1
fi