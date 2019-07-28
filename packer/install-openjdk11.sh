#!/bin/bash
set -e

sudo add-apt-repository ppa:openjdk-r/ppa
sudo apt-get update
sudo apt install -y openjdk-11-jdk

export JAVA_HOME=$(jrunscript -e 'java.lang.System.out.println(java.lang.System.getProperty("java.home"));')
/usr/bin/printf "
JAVA_HOME=${JAVA_HOME}" >> /etc/environment