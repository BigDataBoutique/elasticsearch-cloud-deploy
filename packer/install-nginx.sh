#!/bin/bash
set -e

apt-get install nginx apache2-utils

mv ~/nginx-client.conf /etc/nginx/nginx.conf
