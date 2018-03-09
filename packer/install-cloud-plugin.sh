#!/bin/bash
set -e

cd /usr/share/elasticsearch/

if [[ -f /sys/hypervisor/uuid && `head -c 3 /sys/hypervisor/uuid` == "ec2" ]]; then
  # install AWS-specific plugins only if running on AWS
  # see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/identify_ec2_instances.html
  sudo bin/elasticsearch-plugin install --batch discovery-ec2
  sudo bin/elasticsearch-plugin install --batch repository-s3
elif `grep -q unknown-245 /var/lib/dhcp/dhclient.eth0.leases`; then
  # install Azure-specific plugins only if running on Azure
  sudo bin/elasticsearch-plugin install --batch repository-azure
  sudo bin/elasticsearch-plugin install --batch discovery-azure-classic
elif (sudo dmidecode -s system-product-name | grep -q "Google Compute Engine"); then
  # install Google Compute specific plugins only if running on GCP
  sudo bin/elasticsearch-plugin install --batch discovery-gce
  sudo bin/elasticsearch-plugin install --batch repository-gcs
fi