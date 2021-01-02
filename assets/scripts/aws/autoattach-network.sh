# Required variables
# - aws_region
# - es_cluster
# - elasticsearch_data_dir

AV_ZONE="$(ec2metadata --availability-zone)"
INSTANCE_ROLE="$(aws ec2 describe-tags --region $aws_region --filters Name=resource-id,Values=$(ec2metadata --instance-id) | jq -r '.Tags[] | select(.Key == "Role") | .Value')"
echo "AV_ZONE: $AV_ZONE"
echo "INSTANCE_ROLE: $INSTANCE_ROLE"

while true; do
    echo "UNATTACHED_ENI_ID: $eni_id"

    aws ec2 attach-network-interface --instance-id=$(ec2metadata --instance-id) --device-index 1 --network-interface-id ${eni_id} --region "$aws_region"
    if [ "$?" != "0" ]; then
        sleep 10
        continue
    fi

    ATTACHMENTS_COUNT="$(aws ec2 describe-network-interfaces --region $aws_region --filters Name=network-interface-id,Values=${eni_id} | jq -r '.NetworkInterfaces[0].Attachment | length')"
    if [ "$ATTACHMENTS_COUNT" != "0" ]; then break; fi
done

echo "Updating network configuration"

cat <<EOF >/etc/netplan/51-ens6.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens6:
      addresses:
       - ${eni_ipv4}/20
      dhcp4: no
      routes:
       - to: 0.0.0.0/0
         via: 172.31.16.1 # Default gateway
         table: 1000
       - to: ${eni_ipv4}
         via: 0.0.0.0
         scope: link
         table: 1000
      routing-policy:
        - from: ${eni_ipv4}
          table: 1000
EOF

sleep 5

netplan apply

