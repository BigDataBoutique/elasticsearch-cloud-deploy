#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


${configure_es_script}

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
node.master: true
node.data: false
node.ingest: false
EOF

while true
do
    echo "Fetching masters..."
    MASTER_INSTANCES="$(aws ec2 describe-instances --region=${aws_region} --filters Name=instance-state-name,Values=running Name=tag:Role,Values=master Name=tag:Cluster,Values=${es_environment} | jq -r '.Reservations | map(.Instances[].InstanceId) | .[]' | sort)"
    COUNT=`echo "$MASTER_INSTANCES" | wc -l`

    if [ "$COUNT" -eq "${masters_count}" ]; then
        echo "Masters count is correct... Rechecking in 60 sec"
        sleep 60
        MASTER_INSTANCES_RECHECK="$(aws ec2 describe-instances --region=${aws_region} --filters Name=instance-state-name,Values=running Name=tag:Role,Values=master Name=tag:Cluster,Values=${es_environment} | jq -r '.Reservations | map(.Instances[].InstanceId) | .[]' | sort)"
    
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

echo "discovery.seed_hosts: $SEED_HOSTS" >>/etc/elasticsearch/elasticsearch.yml
echo "cluster.initial_master_nodes: $(hostname -I),$SEED_HOSTS" >>/etc/elasticsearch/elasticsearch.yml

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

while true
do
    echo "Checking cluster health"
    HEALTH="$(curl $BASICAUTH --silent -k localhost:9200/_cluster/health | jq -r '.status')"
    if [ "$HEALTH" = "green" ]; then
        break
    fi
    sleep 5
done
shutdown -h now