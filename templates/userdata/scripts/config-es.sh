# Configure elasticsearch
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
cluster.name: ${es_cluster}
xpack.monitoring.enabled: ${monitoring_enabled}
xpack.monitoring.collection.enabled: ${monitoring_enabled}
path.data: ${elasticsearch_data_dir}
path.logs: ${elasticsearch_logs_dir}
xpack.security.enabled: ${security_enabled}
EOF

# If security enabled
if [ "${security_enabled}" == "true" ]; then

    mkdir -p /etc/elasticsearch/config/certs/

    cat <<'EOF' >/etc/elasticsearch/config/certs/ca.crt
${ca_cert}
EOF
    cat <<'EOF' >/etc/elasticsearch/config/certs/tls.crt
${node_cert}
EOF
    cat <<'EOF' >/etc/elasticsearch/config/certs/tls.key
${node_key}
EOF

    cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: "certificate"
xpack.security.transport.ssl.key: "/etc/elasticsearch/config/certs/tls.key"
xpack.security.transport.ssl.certificate: "/etc/elasticsearch/config/certs/tls.crt"
xpack.security.transport.ssl.certificate_authorities: "/etc/elasticsearch/config/certs/ca.crt"
EOF
fi

if [ "${xpack_monitoring_host}" != "self" ]; then
cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
xpack.monitoring.exporters.xpack_remote:
  type: http
  host: "${xpack_monitoring_host}"
EOF
fi

cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml

network.host: _ec2:privateIpv4_,localhost
plugin.mandatory: discovery-ec2
cloud.node.auto_attributes: true
cluster.routing.allocation.awareness.attributes: aws_availability_zone
discovery:
    seed_providers: ec2
    ec2.groups: ${security_groups}
    ec2.host_type: private_ip
    ec2.tag.Cluster: ${es_environment}
    ec2.protocol: http # no need in HTTPS for internal AWS calls

    # manually set the endpoint because of auto-discovery issues
    # https://github.com/elastic/elasticsearch/issues/27464
    ec2.endpoint: ec2.${aws_region}.amazonaws.com
EOF


cat <<'EOF' >>/etc/security/limits.conf

# allow user 'elasticsearch' mlockall
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF

sudo mkdir -p /etc/systemd/system/elasticsearch.service.d
cat <<'EOF' >>/etc/systemd/system/elasticsearch.service.d/override.conf
[Service]
LimitMEMLOCK=infinity
Restart=always
RestartSec=10
EOF

# Setup heap size and memory locking
sudo sed -i 's/#MAX_LOCKED_MEMORY=.*$/MAX_LOCKED_MEMORY=unlimited/' /etc/init.d/elasticsearch
sudo sed -i 's/#MAX_LOCKED_MEMORY=.*$/MAX_LOCKED_MEMORY=unlimited/' /etc/default/elasticsearch
sudo sed -i "s/^-Xms.*/-Xms${heap_size}/" /etc/elasticsearch/jvm.options
sudo sed -i "s/^-Xmx.*/-Xmx${heap_size}/" /etc/elasticsearch/jvm.options

# Setup GC
sudo sed -i "s/^-XX:+UseConcMarkSweepGC/-XX:+UseG1GC/" /etc/elasticsearch/jvm.options

# Create log and data dirs
sudo mkdir -p ${elasticsearch_logs_dir}
sudo mkdir -p ${elasticsearch_data_dir}
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_logs_dir}
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_data_dir}