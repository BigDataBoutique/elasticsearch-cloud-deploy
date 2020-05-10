# Required variables
# - gcp_zones
# - gcp_project_id
# - BIND_TO_ALL

cat <<EOF >>/etc/elasticsearch/elasticsearch.yml
plugin.mandatory: discovery-gce
cloud.gce.project_id: ${gcp_project_id}
cloud.gce.zone: ${gcp_zones}
discovery.seed_providers: gce
EOF

if [ "$BIND_TO_ALL" == "true" ]; then
	echo "network.host: 0.0.0.0" >> /etc/elasticsearch/elasticsearch.yml
else
	echo "network.host: _gce_,localhost" >> /etc/elasticsearch/elasticsearch.yml
fi