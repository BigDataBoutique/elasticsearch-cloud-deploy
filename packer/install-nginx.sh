#!/bin/bash
set -e

apt-get install nginx apache2-utils
htpasswd -bc /etc/nginx/conf.d/search.htpasswd exampleuser changeme

mv ~/nginx-client.conf /etc/nginx/nginx.conf

service nginx start