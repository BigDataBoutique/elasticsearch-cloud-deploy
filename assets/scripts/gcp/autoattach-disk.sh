# Required variables
# - GCP_ZONE
# - es_cluster
# - elasticsearch_data_dir

while true; do
    INSTANCE_ROLE="$(gcloud compute instances describe $HOSTNAME --zone $GCP_ZONE --format json | jq -r ".labels.role")"
    echo "INSTANCE_ROLE: $INSTANCE_ROLE"
    UNATTACHED_VOLUME_ID="$(gcloud compute disks list --filter="zone:$GCP_ZONE AND labels.cluster-name:$es_cluster AND labels.auto-attach-group:$INSTANCE_ROLE" --format json | jq  -r '.[] | .name' | shuf -n 1)"
    echo "UNATTACHED_VOLUME_ID: $UNATTACHED_VOLUME_ID"

    gcloud compute instances attach-disk $HOSTNAME --disk $UNATTACHED_VOLUME_ID --device-name "espersistent" --zone $GCP_ZONE
    if [ "$?" == "0" ]; then
        break
    fi

    sleep 30
done

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
