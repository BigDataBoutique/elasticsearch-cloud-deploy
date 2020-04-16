#!/bin/bash

docker run -d --name elasticsearch-binaries docker.elastic.co/elasticsearch/elasticsearch:6.8.1 sleep infinity

# Generate CA
docker exec elasticsearch-binaries /usr/share/elasticsearch/bin/elasticsearch-certutil ca \
    --pem \
    --out /root/ca.zip
docker exec elasticsearch-binaries unzip /root/ca.zip -d /root
docker cp elasticsearch-binaries:/root/ca .

# Generate certs
docker exec elasticsearch-binaries /usr/share/elasticsearch/bin/elasticsearch-certutil cert \
    --pem \
    --ca-cert /root/ca/ca.crt \
    --ca-key /root/ca/ca.key \
    --out /root/certs.zip
docker exec elasticsearch-binaries unzip /root/certs.zip -d /root/certs
docker exec elasticsearch-binaries chmod -R 777 /root/certs
docker cp elasticsearch-binaries:/root/certs .

mv certs ca $1

docker stop elasticsearch-binaries
docker rm elasticsearch-binaries
