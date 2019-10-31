#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

function fetch_master_nodes_ips() {
    if [ "${cloud_provider}" == "aws" ]; then
        local master_instance_ids="$(aws ec2 describe-instances --region=${aws_region} --filters Name=instance-state-name,Values=running Name=tag:Role,Values=master Name=tag:Cluster,Values=${es_environment} | jq -r '.Reservations | map(.Instances[].InstanceId) | .[]' | sort)"
        echo "$(aws ec2 describe-instances --region ${aws_region} --instance-ids $master_instance_ids | jq -r '.Reservations[].Instances[].PrivateIpAddress' | sort)"
    fi

    if [ "${cloud_provider}" == "azure" ]; then
        echo "$(az vmss nic list -g ${azure_resource_group} --vmss-name ${azure_master_vmss_name} | jq -r '.[].ipConfigurations[0].privateIpAddress' | sort)"
    fi
}

if [ "${cloud_provider}" == "azure" ]; then
    # Change node name to AWS-like hostname
    sudo sed -i -e "s/node.name: .*$/node.name: ip-$(hostname -I | tr . -)/ig" /etc/elasticsearch/elasticsearch.yml
fi


if [ "${bootstrap_node}" == "true"  ]; then

    if [ "${cloud_provider}" == "azure" ]; then
        az login -i
    fi

    while true
    do
        echo "Fetching masters..."
        MASTER_INSTANCES="$(fetch_master_nodes_ips)"
        COUNT=`echo "$MASTER_INSTANCES" | wc -l`

        if [ "$COUNT" -eq "${masters_count}" ]; then
            echo "Masters count is correct... Rechecking in 60 sec"
            sleep 60
            MASTER_INSTANCES_RECHECK="$(fetch_master_nodes_ips)"
        
            if [ "$MASTER_INSTANCES" = "$MASTER_INSTANCES_RECHECK" ]; then
                break
            fi
        fi
    
        sleep 5
    done

    echo "Fetched masters"
    MASTER_IPS="$(fetch_master_nodes_ips)"
    SEED_HOSTS=`echo "$MASTER_IPS" | paste -sd ',' -`
    INITIAL_MASTER_NODES=`echo "$MASTER_IPS" | awk '{print "ip-" $0}' | tr . - | paste -sd ',' -`
fi

# Configure elasticsearch
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
cluster.name: ${es_cluster}

# only data nodes should have ingest and http capabilities
node.master: ${master}
node.data: ${data}
node.ingest: ${data}
xpack.security.enabled: ${security_enabled}
xpack.monitoring.enabled: ${monitoring_enabled}
path.data: ${elasticsearch_data_dir}
path.logs: ${elasticsearch_logs_dir}
EOF

if [ "${bootstrap_node}" == "true"  ]; then
    echo "discovery.seed_hosts: $SEED_HOSTS" >>/etc/elasticsearch/elasticsearch.yml
    echo "cluster.initial_master_nodes: ip-$(hostname -I | tr . -),$INITIAL_MASTER_NODES" >>/etc/elasticsearch/elasticsearch.yml
fi

if [ "${master}" == "true"  ] && [ "${data}" == "true" ]; then
    echo "discovery.type: single-node" >>/etc/elasticsearch/elasticsearch.yml
fi

if [ "${xpack_monitoring_host}" != "self" ]; then
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
xpack.monitoring.exporters.xpack_remote:
  type: http
  host: "${xpack_monitoring_host}"
EOF
fi

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

    # manually set the endpoint because of auto-discovery issues
    # https://github.com/elastic/elasticsearch/issues/27464
    ec2.endpoint: ec2.${aws_region}.amazonaws.com
EOF
fi

if [ "${cloud_provider}" == "azure" ]; then
    echo 'network.host: _site_,localhost' >>/etc/elasticsearch/elasticsearch.yml

    if [ "${bootstrap_node}" != "true"  ]; then
        echo 'discovery.seed_hosts: ["${es_cluster}-master000000", "${es_cluster}-master000001", "${es_cluster}-data000000"]' >>/etc/elasticsearch/elasticsearch.yml
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
Restart=always
RestartSec=10
EOF

# Setup heap size and memory locking
sudo sed -i 's/#MAX_LOCKED_MEMORY=.*$/MAX_LOCKED_MEMORY=unlimited/' /etc/init.d/elasticsearch
sudo sed -i 's/#MAX_LOCKED_MEMORY=.*$/MAX_LOCKED_MEMORY=unlimited/' /etc/default/elasticsearch
sudo sed -i "s/^-Xms.*/-Xms${heap_size}/" /etc/elasticsearch/jvm.options
sudo sed -i "s/^-Xmx.*/-Xmx${heap_size}/" /etc/elasticsearch/jvm.options

# Setup GC
sudo sed -i "s/^-XX:+UseConcMarkSweepGC/-XX:+UseG1GC/" /etc/elasticsearch/jvm.options

# Storage
sudo mkdir -p ${elasticsearch_logs_dir}
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_logs_dir}

# we are assuming volume is declared and attached when data_dir is passed to the script
if { [ "${master}" == "true" ] || [ "${data}" == "true" ]; } && [ "${bootstrap_node}" != "true" ]; then
    sudo mkdir -p ${elasticsearch_data_dir}
    
    export DEVICE_NAME=$(lsblk -ip | tail -n +2 | grep -v " rom" | awk '{print $1 " " ($7? "MOUNTEDPART" : "") }' | sed ':a;N;$!ba;s/\n`/ /g' | sed ':a;N;$!ba;s/\n|-/ /g' | grep -v MOUNTEDPART)
    if sudo mount -o defaults -t ext4 $DEVICE_NAME ${elasticsearch_data_dir}; then
        echo 'Successfully mounted existing disk'
    else
        echo 'Trying to mount a fresh disk'
        sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard $DEVICE_NAME
        sudo mount -o defaults -t ext4 $DEVICE_NAME ${elasticsearch_data_dir} && echo 'Successfully mounted a fresh disk'
    fi
    echo "$DEVICE_NAME ${elasticsearch_data_dir} ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
    sudo chown -R elasticsearch:elasticsearch ${elasticsearch_data_dir}
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

if [ "${bootstrap_node}" == "true"  ]; then
    while true
    do
        echo "Checking cluster health"
        HEALTH="$(curl --silent http://localhost:9200/_cluster/health | jq -r '.status')"
        if [ "$HEALTH" = "green" ]; then
            break
        fi
        sleep 5
    done

    if [ "${cloud_provider}" == "azure" ]; then
        # Delete self
        az vm delete -g "${azure_resource_group}" --name "$HOSTNAME" --yes
    fi

    if [ "${cloud_provider}" == "aws" ]; then
        # AWS instance is set to terminate after shutdown automatically
        shutdown -h now
    fi
else
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
        echo "Elasticsearch unit failed to start"
        exit 1
    fi
fi