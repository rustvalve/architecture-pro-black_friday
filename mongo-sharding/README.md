# MongoDB Sharding - Инструкция по запуску

## 🚀 Как запустить

### Шаг 1: Запустить все контейнеры

```bash
docker compose up -d
```

Дождитесь, пока все контейнеры запустятся и пройдут healthcheck (около 10-15 секунд).

### Шаг 2: Проверить статус контейнеров

```bash
docker compose ps
```

Все контейнеры должны быть в статусе `healthy` или `running`.

### Шаг 3: Инициализировать шардированный кластер

```bash
chmod +x scripts/mongo-init.sh
./scripts/mongo-init.sh
```

Скрипт выполнит следующие действия:

1. ✅ Инициализирует Config Server Replica Set
2. ✅ Инициализирует Shard 1 Replica Set
3. ✅ Инициализирует Shard 2 Replica Set
4. ✅ Добавит оба шарда в кластер через mongos
5. ✅ Включит шардирование для базы данных `somedb`
6. ✅ Настроит шардирование для коллекции `helloDoc`
7. ✅ Вставит 1000 тестовых документов
8. ✅ Покажет статистику распределения данных по шардам

### Шаг 4: Проверить приложение

Откройте в браузере: http://localhost:8080

Доступные эндпоинты:

- `GET /` - информация о кластере и статистика
- `GET /docs` - Swagger UI документация
- `GET /helloDoc/users` - список пользователей
- `GET /helloDoc/count` - количество документов

## 📊 Проверка работы шардирования

### Проверить статус кластера

```bash
docker compose exec mongos_router mongosh --port 27020 --eval 'sh.status()'
```

### Проверить распределение данных по шардам

```bash
docker compose exec mongos_router mongosh --port 27020 --eval 'use somedb; db.helloDoc.getShardDistribution()'
```

### Проверить количество документов

```bash
docker compose exec mongos_router mongosh --port 27020 --eval 'use somedb; db.helloDoc.countDocuments({})'
```

## 🔍 Как проверить, что шардирование работает

1. **Проверить через API:**

   ```bash
   curl http://localhost:8080/
   ```

   В ответе вы увидите:

   - `mongo_topology_type: "Sharded"`
   - `mongo_is_mongos: true`
   - `shards` - список шардов в кластере

2. **Проверить распределение данных:**

   ```bash
   docker compose exec mongos_router mongosh --port 27020
   ```

   В mongosh выполните:

   ```javascript
   use somedb
   db.helloDoc.getShardDistribution()
   ```

   Вы увидите, что данные распределены между shard1 и shard2.

## 🛠️ Управление

### Остановить кластер

```bash
docker compose down
```

### Остановить и удалить данные

```bash
docker compose down -v
```

### Посмотреть логи

```bash
# Все сервисы
docker compose logs -f

# Конкретный сервис
docker compose logs -f mongos_router
docker compose logs -f shard1
docker compose logs -f shard2
```

### Подключиться к mongos через mongosh

```bash
docker compose exec mongos_router mongosh --port 27020
```

## 📝 Полезные команды MongoDB

После подключения к mongos:

```javascript
// Показать статус шардирования
sh.status()

// Показать список баз данных
show dbs

// Переключиться на базу данных
use somedb

// Показать коллекции
show collections

// Статистика по коллекции
db.helloDoc.stats()

// Распределение данных
db.helloDoc.getShardDistribution()

// Найти документы
db.helloDoc.find().limit(10)

// Подсчитать документы
db.helloDoc.countDocuments({})
```

## 🔧 Устранение неполадок

### Контейнеры не запускаются

```bash
docker compose down -v
docker compose up -d
```

### Ошибка при инициализации

Дождитесь полного запуска всех контейнеров (все должны быть healthy):

```bash
docker compose ps
```

Затем повторите инициализацию:

```bash
./scripts/mongo-init.sh
```

### Проверка здоровья сервисов

```bash
# Config Server
docker compose exec configSrv mongosh --port 27017 --eval 'rs.status()'

# Shard 1
docker compose exec shard1 mongosh --port 27018 --eval 'rs.status()'

# Shard 2
docker compose exec shard2 mongosh --port 27019 --eval 'rs.status()'
```
