export ES_HOST="http://localhost:9200"
if [ "$https_enabled" == "true" ]; then
    export ES_HOST="https://localhost:9200"
fi

export CURL_AUTH=""
if [ "$security_enabled" == "true" ]; then
    export CURL_AUTH=" --user elastic:$client_pwd "
fi