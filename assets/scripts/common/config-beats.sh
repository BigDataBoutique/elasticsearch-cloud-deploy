# Required variables
# - filebeat_monitoring_host

if [ "${filebeat_monitoring_host}" != "" ]; then

	cat <<EOF >/etc/filebeat/modules.d/elasticsearch.yml
# Module: elasticsearch
# Docs: https://www.elastic.co/guide/en/beats/filebeat/7.6/filebeat-module-elasticsearch.html

- module: elasticsearch
  server:
    enabled: true
  gc:
    enabled: false
  audit:
    enabled: false
  slowlog:
    enabled: true
  deprecation:
    enabled: true
EOF
	cat <<EOF >/etc/filebeat/filebeat.yml
filebeat.config.modules.path: /etc/filebeat/modules.d/*.yml
output.elasticsearch:
  hosts: ["$filebeat_monitoring_host"]
setup.ilm.enabled: false
EOF

systemctl daemon-reload
systemctl enable filebeat.service
systemctl start filebeat.service
fi