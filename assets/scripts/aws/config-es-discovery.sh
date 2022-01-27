# Required variables
# - aws_region
# - security_groups
# - es_environment
# - availability_zones

cat <<EOF >>/etc/elasticsearch/elasticsearch.yml

network.host: _ec2:privateIpv4_,localhost
plugin.mandatory: discovery-ec2
cloud.node.auto_attributes: true
cluster.routing.allocation.awareness.attributes: aws_availability_zone
discovery:
    zen.hosts_provider: ec2
    ec2.groups: $security_groups
    ec2.host_type: private_ip
    ec2.tag.Cluster: $es_environment
    ec2.availability_zones: $availability_zones
    ec2.protocol: http # no need in HTTPS for internal AWS calls

    # manually set the endpoint because of auto-discovery issues
    # https://github.com/elastic/elasticsearch/issues/27464
    ec2.endpoint: ec2.$aws_region.amazonaws.com
EOF
