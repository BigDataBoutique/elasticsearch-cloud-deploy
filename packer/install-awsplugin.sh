#!/bin/bash

cd /usr/share/elasticsearch/
bin/elasticsearch-plugin install discovery-ec2
bin/elasticsearch-plugin install repository-s3

