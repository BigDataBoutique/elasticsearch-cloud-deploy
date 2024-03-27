# Required variables
# - client_user
# - client_pwd
# - security_enabled
# - monitoring_enabled
# - BIND_TO_ALL
# - ES_HOST
# - CURL_AUTH
# security_encryption_key
# reporting_encryption_key
# saved_objects_encryption_key

# Setup x-pack security also on Kibana configs where applicable
if [ -f "/etc/kibana/kibana.yml" ]; then

    if [ "$BIND_TO_ALL" == "true" ]; then
        echo "server.host: 0.0.0.0" | sudo tee -a /etc/kibana/kibana.yml
    else
        echo "server.host: $(hostname -i)" | sudo tee -a /etc/kibana/kibana.yml
    fi
    echo "monitoring.enabled: $monitoring_enabled" | sudo tee -a /etc/kibana/kibana.yml
    echo "monitoring.kibana.collection.enabled: $monitoring_enabled" | sudo tee -a /etc/kibana/kibana.yml

    if [ ! -z "$security_encryption_key" ]; then
        echo "$security_encryption_key" | /usr/share/kibana/bin/kibana-keystore add --stdin xpack.security.encryptionKey
    fi
    if [ ! -z "$reporting_encryption_key" ]; then
        echo "$reporting_encryption_key" | /usr/share/kibana/bin/kibana-keystore add --stdin xpack.reporting.encryptionKey
    fi
    if [ ! -z "$saved_objects_encryption_key" ]; then
        echo "$saved_objects_encryption_key" | /usr/share/kibana/bin/kibana-keystore add --stdin xpack.encryptedSavedObjects.encryptionKey
    fi


    if [ "$security_enabled" == "true" ]; then
        echo "elasticsearch.username: \"kibana\"" | sudo tee -a /etc/kibana/kibana.yml
        echo "${client_pwd}" | /usr/share/kibana/bin/kibana-keystore add --stdin elasticsearch.password
    fi

    systemctl daemon-reload
    systemctl enable kibana.service
    sudo service kibana restart
fi
