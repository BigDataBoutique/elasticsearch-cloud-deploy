#!/bin/bash
set -e

# See https://stackoverflow.com/a/50103533
printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' | sudo tee /etc/ssl/certs/java/cacerts > /dev/null
sudo /var/lib/dpkg/info/ca-certificates-java.postinst configure

cd /usr/share/elasticsearch/

if [[ -f /sys/hypervisor/uuid && `head -c 3 /sys/hypervisor/uuid` == "ec2" ]]; then
  # install AWS-specific plugins only if running on AWS
  # see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/identify_ec2_instances.html
  sudo bin/elasticsearch-plugin install --batch discovery-ec2
  sudo bin/elasticsearch-plugin install --batch repository-s3
elif `grep -q unknown-245 /var/lib/dhcp/dhclient.eth0.leases`; then
  # install Azure-specific plugins only if running on Azure
  sudo bin/elasticsearch-plugin install --batch repository-azure
elif (sudo dmidecode -s system-product-name | grep -q "Google Compute Engine"); then
  # install Google Compute specific plugins only if running on GCP
  sudo bin/elasticsearch-plugin install --batch discovery-gce
  sudo bin/elasticsearch-plugin install --batch repository-gcs
fi
