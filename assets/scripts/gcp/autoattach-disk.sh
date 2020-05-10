# Required variables
# - GCP_ZONE
# - es_cluster
# - elasticsearch_data_dir

INSTANCE_ROLE="$(gcloud compute instances describe $HOSTNAME --zone $GCP_ZONE --format json | jq -r ".labels.role")"
echo "INSTANCE_ROLE: $INSTANCE_ROLE"

INSTANCE_TEMPLATE_ID="$(gcloud compute instances describe $HOSTNAME --zone $GCP_ZONE --format json | jq -r '.metadata.items[] | select(.key == "instance-template") | .value')"
echo "INSTANCE_TEMPLATE_ID: $INSTANCE_TEMPLATE_ID"

INSTANCE_TEMPLATE_NAME="$(gcloud compute instance-templates describe $INSTANCE_TEMPLATE_ID --format json | jq -r ".name")"
echo "INSTANCE_TEMPLATE_NAME: $INSTANCE_TEMPLATE_NAME"

while true;
do 
    INSTANCE_GROUP="$(gcloud compute instance-groups managed list --filter="instanceTemplate:$INSTANCE_TEMPLATE_NAME AND zone:$GCP_ZONE" --format json)"
    ISG_COUNT="$(echo $INSTANCE_GROUP | jq -r 'length')"
    if [ "$ISG_COUNT" == "1" ]; then
        TARGET_CAPACITY="$(echo $INSTANCE_GROUP | jq -r '.[0].autoscaler.autoscalingPolicy.maxNumReplicas')"
        INSTANCE_GROUP="$(echo $INSTANCE_GROUP | jq -r '.[0].name')"
        break;
    fi
    echo "Instance groups for template:$INSTANCE_TEMPLATE_NAME and zone:$GCP_ZONE matched $ISG_COUNT. Retrying..."
    sleep 10
done

echo "INSTANCE_GROUP: $INSTANCE_GROUP"
echo "TARGET_CAPACITY: $TARGET_CAPACITY"

INSTANCE_ID="$(gcloud compute instances describe $HOSTNAME --format json --zone $GCP_ZONE | jq -r '.id')"
INSTANCES="$(gcloud compute instance-groups managed list-instances $INSTANCE_GROUP --zone $GCP_ZONE --format json | jq -r '.[].id')"
VOLUME_INDEX="$(expr $(echo "$INSTANCES" | awk "/$INSTANCE_ID/{ print NR; exit }") - 1)"

echo "VOLUME_INDEX: $VOLUME_INDEX"

VOLUME_ID="$(gcloud compute disks list --filter="labels.volume-index:$VOLUME_INDEX AND zone:$GCP_ZONE" --format json | jq -r '.[0].name')"
echo "VOLUME_ID: $VOLUME_ID"

gcloud compute instances attach-disk $HOSTNAME --disk $VOLUME_ID --device-name "espersistent" --zone $GCP_ZONE

echo 'Waiting for 30 seconds for the disk to become mountable...'
sleep 30

sudo mkdir -p $elasticsearch_data_dir
export DEVICE_NAME=$(lsblk -ip | tail -n +2 | grep -v " rom" | awk '{print $1 " " ($7? "MOUNTEDPART" : "") }' | sed ':a;N;$!ba;s/\n`/ /g' | sed ':a;N;$!ba;s/\n|-/ /g' | grep -v MOUNTEDPART)
if sudo mount -o defaults -t ext4 $DEVICE_NAME $elasticsearch_data_dir; then
    echo 'Successfully mounted existing disk'
else
    echo 'Trying to mount a fresh disk'
    sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard $DEVICE_NAME
    sudo mount -o defaults -t ext4 $DEVICE_NAME $elasticsearch_data_dir && echo 'Successfully mounted a fresh disk'
fi
echo "$DEVICE_NAME $elasticsearch_data_dir ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo chown -R elasticsearch:elasticsearch $elasticsearch_data_dir