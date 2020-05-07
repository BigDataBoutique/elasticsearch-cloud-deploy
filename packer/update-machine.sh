#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo rm /boot/grub/menu.lst

# https://github.com/hashicorp/packer/issues/2639
echo "Waiting 100 seconds for cloud-init to finish..."
sleep 100

sudo apt-get update
sudo -E apt-get upgrade -y
sudo -E apt-get install -y software-properties-common git python-dev htop ntp jq apt-transport-https unzip

if [[ $PACKER_BUILD_NAME == "aws" ]]; then
	sudo -E apt-get install -y awscli
fi

# Disable daily apt unattended updates.
echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic