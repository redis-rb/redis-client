#!/bin/bash

# Generate some test certificates which are used by the regression test suite:
#
#   test/fixtures/certs/ca.{crt,key}          Self signed CA certificate.
#   test/fixtures/certs/redis.{crt,key}       A certificate with no key usage/policy restrictions.
#   test/fixtures/certs/client.{crt,key}      A certificate restricted for SSL client usage.
#   test/fixtures/certs/server.{crt,key}      A certificate restricted for SSL server usage.
#   test/fixtures/certs/redis.dh              DH Params file.

generate_cert() {
    local name=$1
    local cn="$2"
    local opts="$3"

    local keyfile=test/fixtures/certs/${name}.key
    local certfile=test/fixtures/certs/${name}.crt

    [ -f $keyfile ] || openssl genrsa -out $keyfile 2048
    openssl req \
        -new -sha256 \
        -subj "/O=Redis Test/CN=$cn" \
        -key $keyfile | \
        openssl x509 \
            -req -sha256 \
            -CA test/fixtures/certs/ca.crt \
            -CAkey test/fixtures/certs/ca.key \
            -CAserial test/fixtures/certs/ca.txt \
            -CAcreateserial \
            -days 365 \
            $opts \
            -out $certfile
}

mkdir -p tests/tls
[ -f test/fixtures/certs/ca.key ] || openssl genrsa -out test/fixtures/certs/ca.key 4096
openssl req \
    -x509 -new -nodes -sha256 \
    -key test/fixtures/certs/ca.key \
    -days 3650 \
    -subj '/O=Redis Test/CN=Certificate Authority' \
    -out test/fixtures/certs/ca.crt

cat > test/fixtures/certs/openssl.cnf <<_END_
[ server_cert ]
keyUsage = digitalSignature, keyEncipherment
nsCertType = server
[ client_cert ]
keyUsage = digitalSignature, keyEncipherment
nsCertType = client
_END_

generate_cert server "127.0.0.1" "-extfile test/fixtures/certs/openssl.cnf -extensions server_cert"
generate_cert client "127.0.0.1" "-extfile test/fixtures/certs/openssl.cnf -extensions client_cert"
generate_cert redis "127.0.0.1"

[ -f test/fixtures/certs/redis.dh ] || openssl dhparam -out test/fixtures/certs/redis.dh 2048