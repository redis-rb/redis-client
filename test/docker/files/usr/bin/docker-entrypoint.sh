exec redis-server \
  --port 16380 \
  --tls-port 26380 \
  --tls-cert-file /certs/redis.crt \
  --tls-key-file /certs/redis.key \
  --tls-ca-cert-file /certs/ca.crt \
  --save "" \
  --appendonly no
