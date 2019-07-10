#!/bin/bash
set -e

sudo add-apt-repository ppa:openjdk-r/ppa
sudo apt-get update
sudo apt install -y openjdk-11-jdk