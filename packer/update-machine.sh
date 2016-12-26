#!/bin/bash

apt-get update
rm /boot/grub/menu.lst

apt-get upgrade -y
apt-get install -y software-properties-common git python-dev htop ntp jq

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install boto awscli
