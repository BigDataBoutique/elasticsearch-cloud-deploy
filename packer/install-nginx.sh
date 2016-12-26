#!/bin/bash
set -e

sudo apt-get install nginx apache2-utils
sudo htpasswd -bc /etc/nginx/conf.d/search.htpasswd exampleuser changeme

sudo mv ~/nginx-client.conf /etc/nginx/nginx.conf

sudo service nginx start