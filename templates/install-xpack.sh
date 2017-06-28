#!/bin/bash
cd /usr/share/kibana/
bin/kibana-plugin install x-pack
sudo chown kibana:kibana * -R
