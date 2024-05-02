# Required variables
# - security_enabled
# - client_pwd
# - ES_HOST
# - CURL_AUTH
i=1
while true
do
    echo "Checking cluster health, attempt $i"
    HEALTH="$(curl $CURL_AUTH --silent -k "$ES_HOST/_cluster/health" | jq -r '.status')"
    DATA_NODE_COUNT="$(curl $CURL_AUTH --silent -k "$ES_HOST/_cat/nodes?h=node.role" | grep 'd\|h\|c' | wc -l)"

    if [ "$HEALTH" == "green" ] && [ "$DATA_NODE_COUNT" != "0" ]; then
        break
    fi

    sleep 5
    i=$((i+1))
done

# if any of the below fail, bootstrap failed - exit on error
set -e
if [ "$security_enabled" == "true" ]; then
  curl $CURL_AUTH \
       -X PUT -H 'Content-Type: application/json' -k \
       "$ES_HOST/_security/user/elastic/_password" -d '{ "password": "'"$client_pwd"'" }'

  curl $CURL_AUTH \
       -X PUT -H 'Content-Type: application/json' -k \
       "$ES_HOST/_security/user/kibana/_password" -d '{ "password": "'"$client_pwd"'" }'

  curl $CURL_AUTH \
       -X PUT -H 'Content-Type: application/json' -k \
       "$ES_HOST/_security/user/logstash_system/_password" -d '{ "password": "'"$client_pwd"'" }'

  curl $CURL_AUTH \
       -X PUT -H 'Content-Type: application/json' -k \
       "$ES_HOST/_security/user/remote_monitoring_user/_password" -d '{ "password": "'"$client_pwd"'" }'
fi
