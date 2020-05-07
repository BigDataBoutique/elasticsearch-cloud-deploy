# Required variables
# - security_enabled
# - client_pwd
# - gcs_snapshots_bucket

BASICAUTH=""
if [ "$security_enabled" == "true" ]; then
    BASICAUTH=" --user elastic:$client_pwd "
fi

if [ "${gcs_snapshots_bucket}" != ""  ]; then
    curl $BASICAUTH -X PUT "localhost:9200/_snapshot/gcs_repo" -H 'Content-Type: application/json' -d'
    {
      "type": "gcs",
      "settings": {
        "bucket": "'$gcs_snapshots_bucket'"
      }
    }
    '
fi