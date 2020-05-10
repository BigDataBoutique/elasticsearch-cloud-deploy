if [ "${gcs_snapshots_bucket}" != "" ]; then
	echo "$gcs_service_account_key" | base64 -d > /tmp/gcs-snapshots-service-account.json
	/usr/share/elasticsearch/bin/elasticsearch-keystore add-file gcs.client.default.credentials_file /tmp/gcs-snapshots-service-account.json
    rm /tmp/gcs-snapshots-service-account.json
fi