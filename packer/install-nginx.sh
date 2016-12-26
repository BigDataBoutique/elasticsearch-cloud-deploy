#!/bin/bash
set -e

sudo apt-get install nginx apache2-utils
sudo htpasswd -c /etc/nginx/conf.d/search.htpasswd changeme

sudo mv ~/nginx-client.conf /etc/nginx/nginx.conf

sudo service nginx start