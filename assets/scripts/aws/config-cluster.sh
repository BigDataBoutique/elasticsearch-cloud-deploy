# Required variables
# - security_enabled
# - client_pwd
# - s3_backup_bucket
# - ES_HOST
# - CURL_AUTH

if [ "${s3_backup_bucket}" != ""  ]; then
    curl $CURL_AUTH -k -X PUT "$ES_HOST/_snapshot/s3_repo" -H 'Content-Type: application/json' -d'
    {
      "type": "s3",
      "settings": {
        "bucket": "'"$s3_backup_bucket"'"
      }
    }
    '
    sleep 1

    curl $CURL_AUTH -k -X POST "$ES_HOST/_nodes/reload_secure_settings"
fi