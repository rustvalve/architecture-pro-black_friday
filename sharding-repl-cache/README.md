# MongoDB Sharding с Replica Sets - Инструкция по запуску

## 🚀 Как запустить

### Шаг 1: Запустить все контейнеры

```bash
docker compose up -d
```

Дождитесь, пока все контейнеры запустятся и пройдут healthcheck (около 15-20 секунд).

### Шаг 2: Проверить статус контейнеров

```bash
docker compose ps
```

Все контейнеры должны быть в статусе `healthy` или `running`.

### Шаг 3: Инициализировать кластер с Replica Sets

```bash
chmod +x scripts/mongo-init.sh
./scripts/mongo-init.sh
```

Скрипт выполнит следующие действия:

1. ✅ Инициализирует Config Server Replica Set
2. ✅ Инициализирует Shard 1 Replica Set (3 узла)
3. ✅ Инициализирует Shard 2 Replica Set (3 узла)
4. ✅ Проверит статус Replica Sets
5. ✅ Добавит оба шарда в кластер через mongos
6. ✅ Включит шардирование для базы данных `somedb`
7. ✅ Настроит шардирование для коллекции `helloDoc`
8. ✅ Вставит 1000 тестовых документов
9. ✅ Настроит кэширование с помощью Redis
10. ✅ Покажет статистику распределения данных по шардам

### Шаг 4: Проверить приложение

Откройте в браузере: http://localhost:8080

Доступные эндпоинты:

- `GET /` - информация о кластере и статистика
- `GET /docs` - Swagger UI документация
- `GET /helloDoc/users` - список пользователей
- `GET /helloDoc/count` - количество документов

## 📊 Проверка работы Replica Sets

### Проверить статус Shard 1 Replica Set

```bash
docker compose exec shard1-1 mongosh --port 27018 --eval 'rs.status()'
```

Вы увидите:

- `shard1-1:27018` - PRIMARY
- `shard1-2:27118` - SECONDARY
- `shard1-3:27218` - SECONDARY

### Проверить статус Shard 2 Replica Set

```bash
docker compose exec shard2-1 mongosh --port 27019 --eval 'rs.status()'
```

Вы увидите:

- `shard2-1:27019` - PRIMARY
- `shard2-2:27119` - SECONDARY
- `shard2-3:27219` - SECONDARY

### Проверить статус кластера

```bash
docker compose exec mongos_router mongosh --port 27020 --eval 'sh.status()'
```

### Проверить распределение данных по шардам

```bash
docker compose exec mongos_router mongosh --port 27020 --eval 'use somedb; db.helloDoc.getShardDistribution()'
```

## 🔍 Как проверить, что Replica Sets работают

1. **Проверить через API:**

```bash
curl http://localhost:8080/
```

В ответе вы увидите:

- `mongo_topology_type: "Sharded"`
- `mongo_is_mongos: true`
- `shards` - список шардов в кластере

2. **Проверить конфигурацию Replica Set:**

```bash
docker compose exec shard1-1 mongosh --port 27018
```

В mongosh выполните:

```javascript
rs.conf(); // Конфигурация Replica Set
rs.status(); // Статус всех узлов
```

Вы увидите все 3 узла шарда и их роли (PRIMARY/SECONDARY).

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

# Shard 1 Primary
docker compose logs -f shard1-1

# Shard 2 Replica Set
docker compose logs -f shard2-1 shard2-2 shard2-3
```

### Подключиться к mongos через mongosh

```bash
docker compose exec mongos_router mongosh --port 27020
```

### Подключиться к Primary узлу шарда

```bash
# Shard 1 Primary
docker compose exec shard1-1 mongosh --port 27018

# Shard 2 Primary
docker compose exec shard2-1 mongosh --port 27019
```

## 📝 Полезные команды MongoDB

### В mongos (порт 27020):

```javascript
// Показать статус шардирования
sh.status()

// Показать список баз данных
show dbs

// Переключиться на базу данных
use somedb

// Статистика по коллекции
db.helloDoc.stats()

// Распределение данных
db.helloDoc.getShardDistribution()
```

### В Primary узле шарда:

```javascript
// Статус Replica Set
rs.status();

// Конфигурация Replica Set
rs.conf();

// Показать узлы
rs.printReplicationInfo();
rs.printSecondaryReplicationInfo();
```

## 🎯 Преимущества Replica Sets

### Отказоустойчивость:

- При падении Primary автоматически выбирается новый из Secondary
- Система продолжает работать даже при отказе 1 узла из 3

### Распределение нагрузки:

- Запросы на чтение могут выполняться на Secondary узлах
- Primary обрабатывает все операции записи

### Резервирование данных:

- Данные автоматически реплицируются на все узлы
- Защита от потери данных

## 🧪 Тест отказоустойчивости

### Симуляция отказа Primary узла:

```bash
# Остановить Primary узел Shard 1
docker compose stop shard1-1

# Проверить статус - должен выбраться новый Primary
docker compose exec shard1-2 mongosh --port 27118 --eval 'rs.status()'

# Приложение продолжает работать!
curl http://localhost:8080/

# Восстановить узел
docker compose start shard1-1
```

## 🔧 Устранение неполадок

### Приложение выдает "Internal Server Error"

1. Проверьте, что все контейнеры запущены:

```bash
docker compose ps
```

2. Проверьте логи приложения:

```bash
docker compose logs pymongo_api --tail 20
```

3. Если ошибка подключения к mongos:

```bash
docker compose up -d --force-recreate pymongo_api
```

### Replica Set не инициализируется

Дождитесь полного запуска всех контейнеров:

```bash
docker compose ps
```

Все узлы должны быть `healthy`. Затем повторите:

```bash
./scripts/mongo-init.sh
```

### Проверка здоровья узлов

```bash
# Config Server
docker compose exec configSrv mongosh --port 27017 --eval 'rs.status()'

# Shard 1 Replica Set
docker compose exec shard1-1 mongosh --port 27018 --eval 'rs.status()'

# Shard 2 Replica Set
docker compose exec shard2-1 mongosh --port 27019 --eval 'rs.status()'
```

### Один из узлов в состоянии STARTUP или RECOVERING

Подождите 10-15 секунд - узлы синхронизируются автоматически.

Проверить прогресс:

```bash
docker compose exec shard1-1 mongosh --port 27018 --eval 'rs.status()'
```
