#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo rm /boot/grub/menu.lst

# https://github.com/hashicorp/packer/issues/2639
echo "Waiting 100 seconds for cloud-init to finish..."
sleep 100

sudo apt-get update
sudo -E apt-get upgrade -y
sudo -E apt-get install -y software-properties-common git python-dev htop ntp jq apt-transport-https unzip

# Disable daily apt unattended updates.
echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install