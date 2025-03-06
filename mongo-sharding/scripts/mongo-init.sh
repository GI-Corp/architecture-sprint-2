#!/bin/bash

set -e  # Прерываем выполнение при ошибке

echo "Инициализация сервера конфигурации..."
docker exec -it configSrv mongosh --port 27017 --eval "rs.initiate({ _id: 'config_server', configsvr: true, members: [{ _id: 0, host: 'configSrv:27017' }] })"

echo "Инициализация первого шарда..."
docker exec -it shard1 mongosh --port 27018 --eval "rs.initiate({ _id: 'shard1', members: [{ _id: 0, host: 'shard1:27018' }] })"

echo "Инициализация второго шарда..."
docker exec -it shard2 mongosh --port 27019 --eval "rs.initiate({ _id: 'shard2', members: [{ _id: 0, host: 'shard2:27019' }] })"

echo "Добавление шардов в роутер..."
docker exec -it router mongosh --port 27020 --eval "
  sh.addShard('shard1/shard1:27018');
  sh.addShard('shard2/shard2:27019');
  sh.enableSharding('somedb');
  sh.shardCollection('somedb.helloDoc', { name: 'hashed' });
"

echo "Заполнение базы тестовыми данными..."
docker exec -it router mongosh --port 27020 --eval "
  use somedb;
  for (var i = 0; i < 1000; i++) db.helloDoc.insert({ age: i, name: 'ly' + i });
  print('Создано записей:', db.helloDoc.countDocuments());
"

echo "Настройка шардирования завершена."