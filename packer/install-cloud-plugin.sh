#!/bin/bash
set -e

cd /usr/share/elasticsearch/

if [[ $PACKER_BUILD_NAME == "aws" ]]; then
  sudo bin/elasticsearch-plugin install --batch discovery-ec2
elif [[ $PACKER_BUILD_NAME == "gcp" ]]; then
  sudo bin/elasticsearch-plugin install --batch discovery-gce
fi
