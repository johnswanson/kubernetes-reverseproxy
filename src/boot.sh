#!/bin/bash

# Fail hard and fast
set -eo pipefail

openssl dhparam -out /etc/nginx/dhparams.pem 2048

CONFD_ETCD_NODE=${CONFD_ETCD_NODE:-}
CONFD_CLIENT_CERT=${CONFD_CLIENT_CERT:-}
CONFD_CLIENT_CAKEYS=${CONFD_CLIENT_CAKEYS:-}
CONFD_CLIENT_KEY=${CONFD_CLIENT_KEY:-}

# Loop until confd has updated the nginx config
until confd -onetime \
						-node=${CONFD_ETCD_NODE} \
						-client-key=${CONFD_CLIENT_KEY} \
						-client-cert=${CONFD_CLIENT_CERT} \
						-client-ca-keys=${CONFD_CLIENT_CAKEYS} \
						-config-file /etc/confd/conf.d/myconfig.toml; do
  echo "[nginx] waiting for confd to refresh nginx.conf"
  sleep 5
done

# Run confd in the background to watch the upstream servers
confd -interval 10 \
			-node ${CONFD_ETCD_NODE} \
			-client-key=${CONFD_CLIENT_KEY} \
			-client-cert=${CONFD_CLIENT_CERT} \
			-client-ca-keys=${CONFD_CLIENT_CAKEYS} \
			-config-file /etc/confd/conf.d/myconfig.toml &
echo "[nginx] confd is listening for changes on etcd..."

# Start nginx
echo "[nginx] starting nginx service..."

service nginx start


