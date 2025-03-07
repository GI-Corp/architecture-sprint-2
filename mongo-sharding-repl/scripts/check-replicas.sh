#!/bin/bash

echo "Checking Config Server Replica Set..."
docker exec -it configSrv mongosh --port 27017 --eval "rs.status();"

echo "Checking Shard 1 Replica Set..."
docker exec -it shard1-primary mongosh --port 27018 --eval "rs.status();"

echo "Checking Shard 2 Replica Set..."
docker exec -it shard2-primary mongosh --port 27019 --eval "rs.status();"

echo "Checking Shards in the Router..."
docker exec -it router mongosh --port 27020 --eval "sh.status();"

echo "Replica status check complete."
