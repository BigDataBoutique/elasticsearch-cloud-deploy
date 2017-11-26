#!/bin/bash

cd /usr/share/elasticsearch/

# install AWS-specific plugins only if running on AWS
# see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/identify_ec2_instances.html
if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` == ec2 ]; then
  bin/elasticsearch-plugin install --batch discovery-ec2
  bin/elasticsearch-plugin install --batch repository-s3
fi

# install Azure-specific plugins only if running on Azure
if `grep -q unknown-245 /var/lib/dhcp/dhclient.eth0.leases`; then
  bin/elasticsearch-plugin install --batch repository-azure
  bin/elasticsearch-plugin install --batch discovery-azure-classic
fi
