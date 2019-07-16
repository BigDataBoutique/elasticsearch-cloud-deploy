#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

while true
do
    echo "Fetching masters..."
    MASTER_INSTANCES="$(aws autoscaling describe-auto-scaling-groups --region ${aws_region} --auto-scaling-group-names ${asg_id} | jq -r '.AutoScalingGroups[0].Instances[].InstanceId' | sort)"
    COUNT=`echo "$MASTER_INSTANCES" | wc -l`

    if [ "$COUNT" -eq "${masters_count}" ]; then
        echo "Masters count is correct... Rechecking in 60 sec"
        sleep 60
        MASTER_INSTANCES_RECHECK="$(aws autoscaling describe-auto-scaling-groups --region ${aws_region} --auto-scaling-group-names ${asg_id} | jq -r '.AutoScalingGroups[0].Instances[].InstanceId' | sort)"
      
        if [ "$MASTER_INSTANCES" = "$MASTER_INSTANCES_RECHECK" ]; then
            break
        fi
    fi
  
    sleep 5
done

echo "Fetched masters"
MASTER_IPS="$(aws ec2 describe-instances --region ${aws_region} --instance-ids $MASTER_INSTANCES | jq -r '.Reservations[].Instances[].PrivateIpAddress')"
SEED_HOSTS=`echo "$MASTER_IPS" | paste -sd ',' -`
INITIAL_MASTER_NODES=`echo "$MASTER_IPS" | awk '{print "ip-" $0}' | tr . - | paste -sd ',' -`

# Configure elasticsearch
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
cluster.name: ${es_cluster}

# only data nodes should have ingest and http capabilities
node.master: true
node.data: false
node.ingest: false
path.data: ${elasticsearch_data_dir}
path.logs: ${elasticsearch_logs_dir}
EOF

if [ "${cloud_provider}" == "aws" ]; then
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml

network.host: _ec2:privateIpv4_,localhost
plugin.mandatory: discovery-ec2
cloud.node.auto_attributes: true
cluster.routing.allocation.awareness.attributes: aws_availability_zone
discovery:
    seed_providers: ec2
    ec2.groups: ${security_groups}
    ec2.host_type: private_ip
    ec2.tag.Cluster: ${es_environment}
    ec2.availability_zones: ${availability_zones}
    ec2.protocol: http # no need in HTTPS for internal AWS calls
EOF

echo "    seed_hosts: $SEED_HOSTS" >>/etc/elasticsearch/elasticsearch.yml
echo "cluster.initial_master_nodes: $HOSTNAME,$INITIAL_MASTER_NODES" >>/etc/elasticsearch/elasticsearch.yml

fi

# Azure doesn't have a proper discovery plugin, hence we are going old-school and relying on scaleset name prefixes
if [ "${cloud_provider}" == "azure" ]; then
        cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
network.host: _site_,localhost

# For discovery we are using predictable hostnames (thanks for the computer name prefix), but could just as well use the
# predictable subnet addresses starting at 10.1.0.5.
EOF
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
Restart=always
RestartSec=10
EOF

# Setup heap size and memory locking
sudo sed -i 's/#MAX_LOCKED_MEMORY=.*$/MAX_LOCKED_MEMORY=unlimited/' /etc/init.d/elasticsearch
sudo sed -i 's/#MAX_LOCKED_MEMORY=.*$/MAX_LOCKED_MEMORY=unlimited/' /etc/default/elasticsearch
sudo sed -i "s/^-Xms.*/-Xms${heap_size}/" /etc/elasticsearch/jvm.options
sudo sed -i "s/^-Xmx.*/-Xmx${heap_size}/" /etc/elasticsearch/jvm.options

# Storage
sudo mkdir -p ${elasticsearch_logs_dir}
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_logs_dir}

# Start Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service


while true
do
    echo "Checking cluster health"
    HEALTH="$(curl --silent http://localhost:9200/_cluster/health | jq -r '.status')"
    if [ "$HEALTH" = "green" ]; then
        break
    fi
    sleep 5
done

shutdown -h now