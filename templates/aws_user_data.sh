#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export cloud_provider="${cloud_provider}"
export elasticsearch_data_dir="${elasticsearch_data_dir}"
export elasticsearch_logs_dir="${elasticsearch_logs_dir}"
export heap_size="${heap_size}"
export es_cluster="${es_cluster}"
export es_environment="${es_environment}"
export security_groups="${security_groups}"
export aws_region="${aws_region}"
export security_enabled="${security_enabled}"
export monitoring_enabled="${monitoring_enabled}"
export masters_count="${masters_count}"
export client_user="${client_user}"
export s3_backup_bucket="${s3_backup_bucket}"
export xpack_monitoring_host="${xpack_monitoring_host}"
export client_pwd="${client_pwd}"
export master="${master}"
export data="${data}"
export bootstrap_node="${bootstrap_node}"
export ca_cert="${ca_cert}"
export node_cert="${node_cert}"
export node_key="${node_key}"

/opt/cloud-deploy-scripts/${startup_script}