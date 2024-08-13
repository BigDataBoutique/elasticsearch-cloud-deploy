# Required variables
# - aws_region
# - es_cluster
# - elasticsearch_data_dir

AV_ZONE="$(ec2metadata --availability-zone)"
INSTANCE_ROLE="$(aws ec2 describe-tags --region $aws_region --filters Name=resource-id,Values=$(ec2metadata --instance-id) | jq -r '.Tags[] | select(.Key == "Role") | .Value')"
echo "AV_ZONE: $AV_ZONE"
echo "INSTANCE_ROLE: $INSTANCE_ROLE"

while true; do
    UNATTACHED_VOLUME_ID="$(aws ec2 describe-volumes --region $aws_region --filters Name=tag:ClusterName,Values=$es_cluster Name=tag:AutoAttachGroup,Values=$INSTANCE_ROLE Name=availability-zone,Values=$AV_ZONE | jq -r '.Volumes[] | select(.Attachments | length == 0) | .VolumeId' | shuf -n 1)"
    echo "UNATTACHED_VOLUME_ID: $UNATTACHED_VOLUME_ID"

    aws ec2 attach-volume --device "/dev/xvdh" --instance-id=$(ec2metadata --instance-id) --volume-id $UNATTACHED_VOLUME_ID --region "$aws_region"
    if [ "$?" != "0" ]; then
        sleep 10
        continue
    fi

    sleep 30

    ATTACHMENTS_COUNT="$(aws ec2 describe-volumes --region $aws_region --filters Name=volume-id,Values=$UNATTACHED_VOLUME_ID | jq -r '.Volumes[0].Attachments | length')"
    if [ "$ATTACHMENTS_COUNT" != "0" ]; then break; fi
done

echo 'Waiting for 30 seconds for the disk to become mountable...'
sleep 30

sudo mkdir -p $elasticsearch_data_dir
export DEVICE_NAME=$(lsblk -ip | tail -n +2 | awk '{print $1 " " ($7? "MOUNTEDPART" : "") }' | sed ':a;N;$!ba;s/\n`/ /g' | sed ':a;N;$!ba;s/\n|-/ /g' | grep -v MOUNTEDPART)
if sudo mount -o defaults -t ext4 $DEVICE_NAME $elasticsearch_data_dir; then
    echo 'Successfully mounted existing disk'
else
    echo 'Trying to mount a fresh disk'
    sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard $DEVICE_NAME
    sudo mount -o defaults -t ext4 $DEVICE_NAME $elasticsearch_data_dir && echo 'Successfully mounted a fresh disk'
fi
echo "$DEVICE_NAME $elasticsearch_data_dir ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo chown -R elasticsearch:elasticsearch $elasticsearch_data_dir
