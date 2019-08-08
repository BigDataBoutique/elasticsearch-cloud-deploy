#!/bin/bash
set -e

export CEREBRO_VERSION="0.8.1"

wget https://github.com/lmenezes/cerebro/releases/download/v${CEREBRO_VERSION}/cerebro-${CEREBRO_VERSION}.tgz
mkdir /usr/share/cerebro
tar -xvzf ./cerebro-${CEREBRO_VERSION}.tgz -C /usr/share/cerebro/

sed -i "s/^hosts = /foo = /" /usr/share/cerebro/cerebro-${CEREBRO_VERSION}/conf/application.conf
sed -i '$s@$@\nhosts = [ { host = "http://localhost:9200", name = "Elasticsearch" } ]@' /usr/share/cerebro/cerebro-${CEREBRO_VERSION}/conf/application.conf

if ! getent group cerebro > /dev/null 2>&1 ; then
    echo -n "Creating cerebro group..."
    addgroup --quiet --system cerebro
    echo " OK"
fi

# Create elasticsearch user if not existing
if ! id cerebro > /dev/null 2>&1 ; then
    echo -n "Creating cerebro user..."
    adduser --quiet \
            --system \
            --no-create-home \
            --ingroup cerebro \
            --disabled-password \
            --shell /bin/false \
            cerebro
    echo " OK"
fi

chown -R cerebro:cerebro /usr/share/cerebro

printf "[Unit]\nDescription=Cerebro\n\n[Service]\nType=simple\nUser=cerebro\nGroup=cerebro\nExecStart=/usr/share/cerebro/cerebro-${CEREBRO_VERSION}/bin/cerebro -no-version-check '-Dpidfile.path=/dev/null'\nRestart=always\nWorkingDirectory=/\n\n[Install]\nWantedBy=multi-user.target\n" | tee -a /etc/systemd/system/cerebro.service
systemctl daemon-reload
systemctl enable cerebro.service
systemctl start cerebro
