#!/bin/bash

#set -o nounset \
#    -o errexit \
#    -o verbose \
#    -o xtrace

# Cleanup files
rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12 *.log

# Generate CA key
openssl req -new -x509 -keyout snakeoil-ca-1.key -out snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.test.confluentdemo.io/OU=TEST/O=CONFLUENT/L=PaloAlto/ST=Ca/C=US' -passin pass:confluent -passout pass:confluent

# ksqlDB Server (ksqldb-server) and Control Center (control-center) share a certificate; a separate certificate is not generated for ksqldb-server
# this shared certificate allows the self-signed certificate to be accepted by a Control Center browser user visiting https://localhost:9092 ,
# without importing and trusting the self-signed CA, and this acceptance will also apply later to Websockets requests to wss://localhost:8089
# (port-forwarded to ksqldb-server:8089).  This is necessary as browsers never prompt to trust certificates for this kind of wss:// connection,
# see https://stackoverflow.com/a/23036270/452210 .
users=(kafka1 kafka2 client schemaregistry restproxy connect connectorSA control-center ksqlDBUser appSA badapp clientListen zookeeper mds)
echo "Creating certificates"
printf '%s\0' "${users[@]}" | xargs -0 -I{} -n1 -P15 sh -c './certs-create-per-user.sh "$1" > "certs-create-$1.log" 2>&1 && echo "Created certificates for $1"' -- {}
echo "Creating certificates completed"

# copy control-center certificate for ksqldb-server
cp kafka.control-center.keystore.jks kafka.ksqldb-server.keystore.jks
cp kafka.control-center.truststore.jks kafka.ksqldb-server.truststore.jks
