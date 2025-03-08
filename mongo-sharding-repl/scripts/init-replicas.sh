#!/bin/bash

echo "Initializing Config Server Replica Set..."
docker exec -it configSrv mongosh --port 27017 --eval "
rs.initiate({
  _id: 'config_server',
  configsvr: true,
  members: [
    { _id: 0, host: 'configSrv:27017' }
  ]
});
"

echo "Initializing Shard 1 Replica Set..."
docker exec -it shard1-primary mongosh --port 27018 --eval "
rs.initiate({
  _id: 'shard1',
  members: [
    { _id: 0, host: 'shard1-primary:27018' },
    { _id: 1, host: 'shard1-secondary1:27018' },
    { _id: 2, host: 'shard1-secondary2:27018' }
  ]
});
"

echo "Initializing Shard 2 Replica Set..."
docker exec -it shard2-primary mongosh --port 27019 --eval "
rs.initiate({
  _id: 'shard2',
  members: [
    { _id: 0, host: 'shard2-primary:27019' },
    { _id: 1, host: 'shard2-secondary1:27019' },
    { _id: 2, host: 'shard2-secondary2:27019' }
  ]
});
"

echo "Adding shards to router..."
docker exec -it router mongosh --port 27020 --eval "
sh.addShard('shard1/shard1-primary:27018,shard1-secondary1:27018,shard1-secondary2:27018');
sh.addShard('shard2/shard2-primary:27019,shard2-secondary1:27019,shard2-secondary2:27019');
"

echo "Replica sets and sharding initialized!"
