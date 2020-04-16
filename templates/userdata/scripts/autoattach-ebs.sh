# Find the ebs data disk by tag and attach it
AUTO_ATTACH_DISABLED="$(aws ec2 describe-tags --region ${aws_region} --filters Name=resource-id,Values=$(ec2metadata --instance-id) | jq -r '.Tags[] | select(.Key == "AutoAttachDiskDisabled") | .Value')"
if [ "$AUTO_ATTACH_DISABLED" != "true" ]; then

    ASG_NAME="$(aws ec2 describe-tags --region ${aws_region} --filters Name=resource-id,Values=$(ec2metadata --instance-id) | jq -r '.Tags[] | select(.Key == "aws:autoscaling:groupName") | .Value')"
    INSTANCE_ROLE="$(aws ec2 describe-tags --region ${aws_region} --filters Name=resource-id,Values=$(ec2metadata --instance-id) | jq -r '.Tags[] | select(.Key == "Role") | .Value')"

    echo "ASG_NAME: $ASG_NAME"
    echo "INSTANCE_ROLE: $INSTANCE_ROLE"

    # wait until all nodes are up
    while true
    do
        ASG_INSTANCES="$(aws autoscaling describe-auto-scaling-groups --region ${aws_region} --auto-scaling-group-names $ASG_NAME | jq -r '.AutoScalingGroups[].Instances[] | select(.LifecycleState == "InService") | .InstanceId' | sort)"
        TARGET_CAPACITY="$(aws autoscaling describe-auto-scaling-groups --region ${aws_region} --auto-scaling-group-names $ASG_NAME | jq -r '.AutoScalingGroups[].DesiredCapacity')"

        echo "ASG_INSTANCES: $ASG_INSTANCES"
        echo "TARGET_CAPACITY: $TARGET_CAPACITY"

        if [ "$(echo "$ASG_INSTANCES" | wc -l)" -eq "$TARGET_CAPACITY" ]; then break; fi
        sleep 5
    done

    # find the volume we need to attach
    VOLUME_INDEX="$(expr $(echo "$ASG_INSTANCES" | awk "/$(ec2metadata --instance-id)/{ print NR; exit }") - 1)"
    echo "VOLUME_INDEX: $VOLUME_INDEX"

    AV_ZONE="$(ec2metadata --availability-zone)"

    VOLUME_ID="$(aws ec2 describe-volumes --region ${aws_region} --filters Name=tag:ClusterName,Values=${es_cluster} Name=tag:VolumeIndex,Values=$VOLUME_INDEX Name=tag:AutoAttachGroup,Values=$INSTANCE_ROLE Name=availability-zone,Values=$AV_ZONE | jq -r ".Volumes[0].VolumeId")"
    echo "VOLUME_ID: $VOLUME_ID"
    aws ec2 attach-volume --device "/dev/xvdh" --instance-id=$(ec2metadata --instance-id) --volume-id $VOLUME_ID --region "${aws_region}"

    # wait until disk is attached
    while true
    do
        ATTACHMENTS_COUNT="$(aws ec2 describe-volumes --region ${aws_region} --filters Name=volume-id,Values=$VOLUME_ID | jq -r '.Volumes[0].Attachments | length')"
        if [ "$ATTACHMENTS_COUNT" != "0" ]; then break; fi
        sleep 5
    done
fi

echo 'Waiting for 30 seconds for the disk to become mountable...'
sleep 30

sudo mkdir -p ${elasticsearch_data_dir}
export DEVICE_NAME=$(lsblk -ip | tail -n +2 | awk '{print $1 " " ($7? "MOUNTEDPART" : "") }' | sed ':a;N;$!ba;s/\n`/ /g' | grep -v MOUNTEDPART)
if sudo mount -o defaults -t ext4 $DEVICE_NAME ${elasticsearch_data_dir}; then
    echo 'Successfully mounted existing disk'
else
    echo 'Trying to mount a fresh disk'
    sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard $DEVICE_NAME
    sudo mount -o defaults -t ext4 $DEVICE_NAME ${elasticsearch_data_dir} && echo 'Successfully mounted a fresh disk'
fi
echo "$DEVICE_NAME ${elasticsearch_data_dir} ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_data_dir}