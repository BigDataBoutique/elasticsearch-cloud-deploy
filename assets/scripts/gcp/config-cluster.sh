# Required variables
# - security_enabled
# - client_pwd
# - gcs_snapshots_bucket
# - ES_HOST
# - CURL_AUTH

if [ "${gcs_snapshots_bucket}" != ""  ]; then
    curl $CURL_AUTH -X PUT "$ES_HOST/_snapshot/gcs_repo" -H 'Content-Type: application/json' -d'
    {
      "type": "gcs",
      "settings": {
        "bucket": "'$gcs_snapshots_bucket'"
      }
    }
    '
fi