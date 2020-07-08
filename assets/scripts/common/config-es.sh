# Required variables
# - es_cluster
# - monitoring_enabled
# - elasticsearch_data_dir
# - elasticsearch_logs_dir
# - security_enabled
# - ca_cert
# - node_cert
# - node_key
# - xpack_monitoring_host
# - heap_size
# - use_g1gc

# Configure elasticsearch
cat <<EOF >>/etc/elasticsearch/elasticsearch.yml
cluster.name: $es_cluster
xpack.monitoring.enabled: $monitoring_enabled
xpack.monitoring.collection.enabled: $monitoring_enabled
path.data: $elasticsearch_data_dir
path.logs: $elasticsearch_logs_dir
xpack.security.enabled: $security_enabled
EOF

# If security enabled
if [ "$security_enabled" == "true" ]; then

    mkdir -p /etc/elasticsearch/config/certs/

    echo -n "$ca_cert" > /etc/elasticsearch/config/certs/ca.crt
    echo -n "$node_cert" > /etc/elasticsearch/config/certs/tls.crt
    echo -n "$node_key" > /etc/elasticsearch/config/certs/tls.key

    cat <<'EOF' >>/etc/elasticsearch/elasticsearch.yml
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: "certificate"
xpack.security.transport.ssl.key: "/etc/elasticsearch/config/certs/tls.key"
xpack.security.transport.ssl.certificate: "/etc/elasticsearch/config/certs/tls.crt"
xpack.security.transport.ssl.certificate_authorities: "/etc/elasticsearch/config/certs/ca.crt"
EOF
fi

if [ "$xpack_monitoring_host" != "self" ]; then
cat <<EOF >>/etc/elasticsearch/elasticsearch.yml
xpack.monitoring.exporters.xpack_remote:
  type: http
  host: "$xpack_monitoring_host"
EOF
fi


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
sudo sed -i "s/^-Xms.*/-Xms$heap_size/" /etc/elasticsearch/jvm.options
sudo sed -i "s/^-Xmx.*/-Xmx$heap_size/" /etc/elasticsearch/jvm.options

# Setup GC
if [ "$use_g1gc" = "true" ]; then
	sudo sed -i -re 's/# ([0-9]+-[0-9]+:-XX:-UseConcMarkSweepGC)/\1/ig' /etc/elasticsearch/jvm.options
	sudo sed -i -re 's/# ([0-9]+-[0-9]+:-XX:-UseCMSInitiatingOccupancyOnly)/\1/ig' /etc/elasticsearch/jvm.options
	sudo sed -i 's/[0-9]\+-:-XX:+UseG1GC/10-:-XX:+UseG1GC/ig' /etc/elasticsearch/jvm.options
	sudo sed -i 's/[0-9]\+-:-XX:G1ReservePercent/10-:-XX:G1ReservePercent/ig' /etc/elasticsearch/jvm.options
	sudo sed -i 's/[0-9]\+-:-XX:InitiatingHeapOccupancyPercent/10-:-XX:InitiatingHeapOccupancyPercent/ig' /etc/elasticsearch/jvm.options
fi

# Create log and data dirs
sudo mkdir -p $elasticsearch_logs_dir
sudo mkdir -p $elasticsearch_data_dir
sudo chown -R elasticsearch:elasticsearch $elasticsearch_logs_dir
sudo chown -R elasticsearch:elasticsearch $elasticsearch_data_dir