#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo rm /boot/grub/menu.lst

sudo -E apt-get upgrade -y
sudo -E apt-get install -y software-properties-common git python-dev htop ntp jq apt-transport-https ca-certificates lsb-release gnupg


# Disable daily apt unattended updates.
echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py || python2 get-pip.py
pip install boto awscli || pip2 install boto awscli 

# Install azure CLI
curl -sL https://packages.microsoft.com/keys/microsoft.asc | 
    gpg --dearmor | 
    sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |  sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install -y azure-cli
