# Required variables
# - es_environment
# - masters_count

while true
do
    echo "Fetching masters..."

    MASTER_INSTANCES="$(gcloud compute instances list --filter="labels.cluster:$es_environment AND labels.role:(master OR data-voters)" --format 'get(networkInterfaces[0].networkIP)' | sort)"
    COUNT=`echo "$MASTER_INSTANCES" | wc -l`
    echo "Found $COUNT instances, expecting $masters_count"
    if [ "$COUNT" -eq "$masters_count" ]; then
        echo "Masters count is correct... Rechecking in 60 sec"
        sleep 60
        MASTER_INSTANCES_RECHECK="$(gcloud compute instances list --filter="labels.cluster:$es_environment AND labels.role:(master OR data-voters)" --format 'get(networkInterfaces[0].networkIP)' | sort)"
        if [ "$MASTER_INSTANCES" = "$MASTER_INSTANCES_RECHECK" ]; then
            break
        fi
    fi

    sleep 5
done

echo "Fetched masters"
MASTER_IPS="$MASTER_INSTANCES"
SEED_HOSTS=`echo "$MASTER_IPS" | paste -sd ',' -`

echo "discovery.seed_hosts: $SEED_HOSTS" >>/etc/elasticsearch/elasticsearch.yml
echo "cluster.initial_master_nodes: $(hostname -I),$SEED_HOSTS" >>/etc/elasticsearch/elasticsearch.yml
