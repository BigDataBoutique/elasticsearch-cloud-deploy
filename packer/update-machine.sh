#!/bin/bash

apt-get update
apt-get upgrade -y
apt-get install -y software-properties-common git python-dev

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install boto awscli
