#!/bin/bash
set -e

curl -o /tmp/SumoCollector.sh https://collectors.us2.sumologic.com/rest/download/linux/64
chmod +x /tmp/SumoCollector.sh
sudo /tmp/SumoCollector.sh -q -Vsumo.accessid=$SUMO_ACCESS_ID -Vsumo.accesskey=$SUMO_ACCESS_KEY
