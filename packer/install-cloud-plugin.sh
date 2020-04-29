#!/bin/bash
set -e

cd /usr/share/elasticsearch/

if [[ $PACKER_BUILD_NAME == "aws" ]]; then
  sudo bin/elasticsearch-plugin install --batch discovery-ec2
  sudo bin/elasticsearch-plugin install --batch repository-s3
elif [[ $PACKER_BUILD_NAME == "azure" ]]; then
  sudo bin/elasticsearch-plugin install --batch repository-azure
elif [[ $PACKER_BUILD_NAME == "gcp" ]]; then
  sudo bin/elasticsearch-plugin install --batch discovery-gce
  sudo bin/elasticsearch-plugin install --batch repository-gcs
fi
