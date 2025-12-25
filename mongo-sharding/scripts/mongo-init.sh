#!/bin/bash

###
# Инициализация шардированного кластера MongoDB
###

echo "🚀 Шаг 1: Инициализация Config Server Replica Set..."
docker compose exec -T configSrv mongosh --port 27017 <<EOF
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [
    { _id: 0, host: "configSrv:27017" }
  ]
});
EOF

echo "⏳ Ожидание инициализации Config Server..."
sleep 5

echo "🚀 Шаг 2: Инициализация Shard 1 Replica Set..."
docker compose exec -T shard1 mongosh --port 27018 <<EOF
rs.initiate({
  _id: "shard1",
  members: [
    { _id: 0, host: "shard1:27018" }
  ]
});
EOF

echo "⏳ Ожидание инициализации Shard 1..."
sleep 5

echo "🚀 Шаг 3: Инициализация Shard 2 Replica Set..."
docker compose exec -T shard2 mongosh --port 27019 <<EOF
rs.initiate({
  _id: "shard2",
  members: [
    { _id: 0, host: "shard2:27019" }
  ]
});
EOF

echo "⏳ Ожидание инициализации Shard 2..."
sleep 5

echo "🚀 Шаг 4: Добавление шардов в кластер через mongos..."
docker compose exec -T mongos_router mongosh --port 27020 <<EOF
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");
sh.status();
EOF

echo "⏳ Ожидание добавления шардов..."
sleep 3

echo "🚀 Шаг 5: Включение шардирования для базы данных 'somedb'..."
docker compose exec -T mongos_router mongosh --port 27020 <<EOF
sh.enableSharding("somedb");
EOF

echo "⏳ Ожидание включения шардирования..."
sleep 2

echo "🚀 Шаг 6: Создание коллекции и настройка shard key..."
docker compose exec -T mongos_router mongosh --port 27020 <<EOF
use somedb;

// Создаем коллекцию
db.createCollection("helloDoc");

// Включаем шардирование для коллекции по полю 'name' с hashed стратегией
// Hashed sharding обеспечивает равномерное распределение данных между шардами
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });

print("✅ Шардирование коллекции helloDoc настроено (hashed по полю 'name')");
EOF

echo "⏳ Ожидание настройки шардирования..."
sleep 2

echo "🚀 Шаг 7: Заполнение базы данных тестовыми данными (1000 документов)..."
docker compose exec -T mongos_router mongosh --port 27020 <<EOF
use somedb;

// Вставляем 1000 документов
// Благодаря hashed sharding по полю 'name', данные автоматически
// равномерно распределяются между шардами (~50% на каждый шард)
for(var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({age: i, name: "ly" + i});
  if (i % 100 == 0) {
    print("Вставлено " + i + " документов...");
  }
}

print("✅ Вставлено 1000 документов");

// Показываем статистику распределения данных по шардам
print("\n📊 Статистика распределения данных по шардам:");
print("   (Ожидаем ~50% данных на каждом шарде благодаря hashed sharding)");
db.helloDoc.getShardDistribution();

print("\n📈 Общее количество документов:");
print(db.helloDoc.countDocuments({}));
EOF

echo ""
echo "✅ Инициализация завершена!"
echo ""
echo "📊 Проверьте статус кластера:"
echo "   docker compose exec mongos_router mongosh --port 27020 --eval 'sh.status()'"
echo ""
echo "🌐 Приложение доступно по адресу: http://localhost:8080"
echo ""
