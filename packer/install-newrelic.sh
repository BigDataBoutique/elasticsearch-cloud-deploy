#!/bin/bash
set -e

curl -fsSL https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/newrelic-infra.gpg
echo "deb https://download.newrelic.com/infrastructure_agent/linux/apt focal main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
sudo apt update
sudo apt-get install newrelic-infra -y
echo $NR_LICENSE | sudo tee -a /etc/newrelic-infra.yml

