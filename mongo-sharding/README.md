# **Задание 2: Шардирование MongoDB**  

Этот проект демонстрирует настройку шардирования в MongoDB с использованием Docker.  

## **Запуск проекта**  

Чтобы развернуть MongoDB и приложение, выполните следующую команду:  

```shell
docker compose up -d
```

## **Настройка шардирования**  

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

### **Шаг 2: Инициализация шардов**  

#### **Инициализация первого шарда**  

1. Подключаемся к `shard1`:  

   ```shell
   docker exec -it shard1 mongosh --port 27018
   ```

2. Выполняем команду инициализации:  

   ```shell
   rs.initiate({
     _id: "shard1",
     members: [{ _id: 0, host: "shard1:27018" }]
   });
   ```

3. Выходим из `mongosh`:  

   ```shell
   exit;
   ```

#### **Инициализация второго шарда**  

1. Подключаемся к `shard2`:  

   ```shell
   docker exec -it shard2 mongosh --port 27019
   ```

2. Выполняем команду инициализации:  

   ```shell
   rs.initiate({
     _id: "shard2",
     members: [{ _id: 0, host: "shard2:27019" }]
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
   sh.addShard("shard1/shard1:27018");
   sh.addShard("shard2/shard2:27019");
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

---

### **Автоматическое заполнение тестовыми данными (альтернативный вариант)**  

Выполните следующий скрипт для автоматической генерации данных в базе MongoDB:  

```shell
./scripts/mongo-init.sh
```

---

## **Проверка работы шардирования**  

1. Подключаемся к роутеру MongoDB:  

   ```shell
   docker exec -it router mongosh --port 27020
   ```

2. Переключаемся на базу `somedb` и проверяем количество записей:  

   ```shell
   use somedb;
   db.helloDoc.countDocuments();
   ```

Если всё настроено правильно, в консоли отобразится число **1000**.

---

