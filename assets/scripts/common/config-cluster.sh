# Required variables
# - security_enabled
# - client_pwd
# - ES_HOST
# - CURL_AUTH

while true
do
    echo "Checking cluster health"
    HEALTH="$(curl $CURL_AUTH --silent -k "$ES_HOST/_cluster/health" | jq -r '.status')"
    DATA_NODE_COUNT="$(curl $CURL_AUTH --silent -k "$ES_HOST/_cat/nodes?h=node.role" | grep 'd' | wc -l)"

    if [ "$HEALTH" == "green" ] && [ "$DATA_NODE_COUNT" != "0" ]; then
        break
    fi

    sleep 5
done

if [ "$security_enabled" == "true" ]; then
    curl $CURL_AUTH \
         -X PUT -H 'Content-Type: application/json' -k \
         "$ES_HOST/_xpack/security/user/kibana/_password" -d '{ "password": "'"$client_pwd"'" }'

    curl $CURL_AUTH \
         -X PUT -H 'Content-Type: application/json' -k \
         "$ES_HOST/_xpack/security/user/logstash_system/_password" -d '{ "password": "'"$client_pwd"'" }'

    curl $CURL_AUTH \
         -X PUT -H 'Content-Type: application/json' -k \
         "$ES_HOST/_xpack/security/user/elastic/_password" -d '{ "password": "'"$client_pwd"'" }'

    curl $CURL_AUTH \
         -X PUT -H 'Content-Type: application/json' -k \
         "$ES_HOST/_xpack/security/user/remote_monitoring_user/_password" -d '{ "password": "'"$client_pwd"'" }'
fi