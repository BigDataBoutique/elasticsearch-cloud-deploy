#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

if [ "${DEV_MODE_scripts_gcs_bucket}" != "" ]; then
	sudo gsutil cp -r "gs://${DEV_MODE_scripts_gcs_bucket}/*" /opt/cloud-deploy-scripts/
	sudo chmod -R +x /opt/cloud-deploy-scripts
fi

export cloud_provider="${cloud_provider}"
export gcp_zones="${gcp_zones}"
export gcp_project_id="${gcp_project_id}"
export gcs_snapshots_bucket="${gcs_snapshots_bucket}"
export gcs_service_account_key="${gcs_service_account_key}"
export elasticsearch_data_dir="${elasticsearch_data_dir}"
export elasticsearch_logs_dir="${elasticsearch_logs_dir}"
export heap_size="${heap_size}"
export es_cluster="${es_cluster}"
export es_environment="${es_environment}"
export use_g1gc="${use_g1gc}"
export security_enabled="${security_enabled}"
export monitoring_enabled="${monitoring_enabled}"
export masters_count="${masters_count}"
export client_user="${client_user}"
export xpack_monitoring_host="${xpack_monitoring_host}"
export filebeat_monitoring_host="${filebeat_monitoring_host}"
export client_pwd="${client_pwd}"
export master="${master}"
export data="${data}"
export bootstrap_node="${bootstrap_node}"
export ca_cert="${ca_cert}"
export node_cert="${node_cert}"
export node_key="${node_key}"

/opt/cloud-deploy-scripts/${startup_script}