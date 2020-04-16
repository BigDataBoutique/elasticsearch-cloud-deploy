#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo rm /boot/grub/menu.lst

# Need to wait for cloud-init to finish before using apt-get
# https://github.com/hashicorp/packer/issues/2639
sleep 30

sudo -E apt-get upgrade -y
sudo -E apt-get install -y software-properties-common git python-dev htop ntp jq apt-transport-https unzip

# Disable daily apt unattended updates.
echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install