# Required variables
# - security_enabled
# - client_pwd
# - s3_backup_bucket

BASICAUTH=""
if [ "$security_enabled" == "true" ]; then
    BASICAUTH=" --user elastic:$client_pwd "
fi

if [ "${s3_backup_bucket}" != ""  ]; then
    curl $BASICAUTH -X PUT "localhost:9200/_snapshot/s3_repo" -H 'Content-Type: application/json' -d'
    {
      "type": "s3",
      "settings": {
        "bucket": "'"$s3_backup_bucket"'"
      }
    }
    '
    sleep 1

    curl $BASICAUTH -X POST "localhost:9200/_nodes/reload_secure_settings"
fi