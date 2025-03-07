# **Задание 4: Кеширование**  

Этот проект демонстрирует настройку кэширования.  

## **Запуск проекта**  

Чтобы развернуть Redis, MongoDB и приложение, выполните следующую команду:  

```shell
docker compose up -d
```

## **Настройка репликации**

### **Шаг 1: Инициализация сервера конфигурации**  

Подключаемся к серверу конфигурации:

```shell
docker exec -it configSrv mongosh --port 27017
```  

Выполняем команду инициализации:  

```shell
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [{ _id: 0, host: "configSrv:27017" }]
});
```  

Выходим из `mongosh`:  

```shell
exit;
```

---

### **Шаг 2: Инициализация реплик для каждого шарда**  

#### **Инициализация первого шарда (shard1)**  

1. Подключаемся к `shard1-primary`:  

   ```shell
   docker exec -it shard1-primary mongosh --port 27018
   ```

2. Выполняем команду инициализации (создание реплик):  

   ```shell
   rs.initiate({
   _id: "shard1",
   members: [
      { _id: 0, host: "shard1-primary:27018" },
      { _id: 1, host: "shard1-secondary1:27018" },
      { _id: 2, host: "shard1-secondary2:27018" }
   ]
   });
   ```

3. Выходим из `mongosh`:  

   ```shell
   exit;
   ```

#### **Инициализация второго шарда (shard2)**  

1. Подключаемся к `shard2-primary`:  

   ```shell
   docker exec -it shard2-primary mongosh --port 27019
   ```

2. Выполняем команду инициализации (создание реплик):  

   ```shell
   rs.initiate({
   _id: "shard2",
   members: [
      { _id: 0, host: "shard2-primary:27019" },
      { _id: 1, host: "shard2-secondary1:27019" },
      { _id: 2, host: "shard2-secondary2:27019" }
   ]
   });
   ```

3. Выходим из `mongosh`:  

   ```shell
   exit;
   ```

---

### **Шаг 3: Настройка роутера и шардированной коллекции**  

1. Подключаемся к `mongos`-роутеру:  

   ```shell
   docker exec -it router mongosh --port 27020
   ```

2. Добавляем шарды в роутер:  

   ```shell
   sh.addShard("shard1/shard1-primary:27018,shard1-secondary1:27018,shard1-secondary2:27018");
   sh.addShard("shard2/shard2-primary:27019,shard2-secondary1:27019,shard2-secondary2:27019");
   ```

3. Включаем шардирование для базы данных `somedb`:  

   ```shell
   sh.enableSharding("somedb");
   ```

4. Создаём коллекцию `helloDoc` с **хешированным** шардированием по полю `name`:  

   ```shell
   sh.shardCollection("somedb.helloDoc", { "name": "hashed" });
   ```

5. Заполняем базу 1000 тестовыми записями:  

   ```shell
   use somedb;
   for (var i = 0; i < 1000; i++) db.helloDoc.insert({ age: i, name: "ly" + i });
   ```

6. Проверяем количество созданных записей:  

   ```shell
   db.helloDoc.countDocuments();
   ```

7. Выходим из `mongosh`:  

   ```shell
   exit;
   ```

8. Добавляем `MONGODB_URL` в environment сервиса `pymongo_api`:  

   ```shell
   MONGODB_URL: "mongodb://router:27020"
   ```

---

## **Настройка кэширования**

1. Добавляем `redis` сервис в compose.yml:  

   ```shell
   redis:
      image: "redis:latest"
      container_name: redis
      ports:
      - "6379"
      volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
      command: [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
      networks:
      app-network:
         ipv4_address: 173.17.0.2
   ```

2. Добавляем файл `./redis/redis.conf` с конфигурациями для `redis`:

   ```shell
   port 6379
   cluster-enabled no
   cluster-config-file nodes.conf
   cluster-node-timeout 5000
   appendonly yes
   ```

3. Добавляем `REDIS_URL` в environment сервиса `pymongo_api`:  

   ```shell
   REDIS_URL: "redis://redis:6379"
   ```

---

## Доступные эндпоинты

Список доступных эндпоинтов, swagger http://localhost:8080/docs

Эндпоинт для проверки кеширования: http://localhost:8080/helloDoc/users


