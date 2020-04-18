# Required variables
# - security_enabled
# - client_pwd

if [ "$security_enabled" == "true" ]; then
BASICAUTH=" --user elastic:$client_pwd "

while true
do
    echo "Checking cluster health"
    HEALTH="$(curl $BASICAUTH --silent -k localhost:9200/_cluster/health | jq -r '.status')"
    DATA_NODE_COUNT="$(curl $BASICAUTH --silent -k localhost:9200/_cat/nodes?h=node.role | grep 'd' | wc -l)"

    if [ "$HEALTH" == "green" ] && [ "$DATA_NODE_COUNT" != "0" ]; then
        break
    fi

    sleep 5
done

curl $BASICAUTH \
     -X PUT -H 'Content-Type: application/json' -k \
     "localhost:9200/_xpack/security/user/kibana/_password" -d '{ "password": "'"$client_pwd"'" }'

curl $BASICAUTH \
     -X PUT -H 'Content-Type: application/json' -k \
     "localhost:9200/_xpack/security/user/logstash_system/_password" -d '{ "password": "'"$client_pwd"'" }'

curl $BASICAUTH \
     -X PUT -H 'Content-Type: application/json' -k \
     "localhost:9200/_xpack/security/user/elastic/_password" -d '{ "password": "'"$client_pwd"'" }'

curl $BASICAUTH \
     -X PUT -H 'Content-Type: application/json' -k \
     "localhost:9200/_xpack/security/user/remote_monitoring_user/_password" -d '{ "password": "'"$client_pwd"'" }'

fi